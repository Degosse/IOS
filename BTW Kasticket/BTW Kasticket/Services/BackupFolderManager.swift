import Combine
import Foundation
import SwiftData

enum BackupFolderError: LocalizedError {
    case accessDenied
    case notConfigured
    case folderUnavailable

    var errorDescription: String? {
        switch self {
        case .accessDenied: return "Could not access the selected backup folder."
        case .notConfigured: return "No backup folder has been configured yet."
        case .folderUnavailable: return "The backup folder is no longer available. Please choose it again."
        }
    }
}

@MainActor
final class BackupFolderManager: ObservableObject {
    static let shared = BackupFolderManager()

    @Published private(set) var lastBackupDate: Date?
    @Published private(set) var folderConfigured: Bool
    @Published private(set) var needsAttention: Bool = false

    private let bookmarkKey = "backupFolderBookmark"
    private let lastBackupDateKey = "lastBackupDate"
    private let lastBackupSignatureKey = "lastBackupSignature"
    private let maxRetainedBackups = 15
    private let filenamePrefix = "BTW-Kasticket-Backup-"

    private var isBackingUp = false

    private init() {
        let defaults = UserDefaults.standard
        lastBackupDate = defaults.object(forKey: lastBackupDateKey) as? Date
        folderConfigured = defaults.data(forKey: bookmarkKey) != nil
    }

    func setFolder(_ folderURL: URL) throws {
        guard folderURL.startAccessingSecurityScopedResource() else {
            throw BackupFolderError.accessDenied
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let bookmark = try folderURL.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
        folderConfigured = true
        needsAttention = false
    }

    private func resolveFolderURL() throws -> URL {
        guard let bookmark = UserDefaults.standard.data(forKey: bookmarkKey) else {
            throw BackupFolderError.notConfigured
        }

        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: bookmark, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale, url.startAccessingSecurityScopedResource() {
                if let refreshed = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) {
                    UserDefaults.standard.set(refreshed, forKey: bookmarkKey)
                }
                url.stopAccessingSecurityScopedResource()
            }
            return url
        } catch {
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
            folderConfigured = false
            needsAttention = true
            throw BackupFolderError.folderUnavailable
        }
    }

    private func signature(for receipts: [ExpenseReceipt]) -> String {
        let latestModified = receipts.map(\.modifiedAt).max()?.timeIntervalSince1970 ?? 0
        return "\(receipts.count)|\(latestModified)"
    }

    /// Writes one backup snapshot as a folder (`manifest.json` + an `images/` subfolder with
    /// one file per photo) into `parentDirectory`. A folder rather than a single JSON file with
    /// inlined base64 images, because a huge single text line made the Files app hang on-device.
    private func writeSnapshot(receipts: [ExpenseReceipt], into parentDirectory: URL) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let snapshotName = "\(filenamePrefix)\(formatter.string(from: Date.now))"
        let snapshotURL = parentDirectory.appendingPathComponent(snapshotName, isDirectory: true)
        let imagesURL = snapshotURL.appendingPathComponent("images", isDirectory: true)

        let fileManager = FileManager.default
        try fileManager.createDirectory(at: imagesURL, withIntermediateDirectories: true)

        let manifest = BackupService.shared.buildManifest(receipts: receipts)
        for (receipt, dto) in zip(receipts, manifest.receipts) {
            if let filename = dto.imageFilename, let imageData = receipt.imageData {
                try imageData.write(to: imagesURL.appendingPathComponent(filename), options: .atomic)
            }
        }

        let manifestData = try BackupService.shared.encode(manifest)
        try manifestData.write(to: snapshotURL.appendingPathComponent("manifest.json"), options: .atomic)

        return snapshotURL
    }

    @discardableResult
    func writeBackupNow(receipts: [ExpenseReceipt]) async throws -> URL {
        let folderURL = try resolveFolderURL()
        guard folderURL.startAccessingSecurityScopedResource() else {
            needsAttention = true
            throw BackupFolderError.accessDenied
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let snapshotURL = try writeSnapshot(receipts: receipts, into: folderURL)

        pruneOldBackups(in: folderURL)

        let defaults = UserDefaults.standard
        defaults.set(Date.now, forKey: lastBackupDateKey)
        defaults.set(signature(for: receipts), forKey: lastBackupSignatureKey)
        lastBackupDate = Date.now
        needsAttention = false

        return snapshotURL
    }

    /// Builds a one-off snapshot in the temp directory and zips it into a single shareable file
    /// (via the system zip trick, same as `ExportService.generateZIP`) for the manual "Export
    /// Backup File" escape hatch — works even before any backup folder has been configured.
    func buildShareableArchive(receipts: [ExpenseReceipt]) async throws -> URL {
        let fileManager = FileManager.default
        let snapshotURL = try writeSnapshot(receipts: receipts, into: fileManager.temporaryDirectory)
        defer { try? fileManager.removeItem(at: snapshotURL) }

        return try await Task.detached {
            try await withCheckedThrowingContinuation { continuation in
                let coordinator = NSFileCoordinator()
                var coordinatorError: NSError?

                coordinator.coordinate(readingItemAt: snapshotURL, options: [.forUploading], error: &coordinatorError) { zipURL in
                    do {
                        let finalZipURL = fileManager.temporaryDirectory.appendingPathComponent("\(snapshotURL.lastPathComponent).zip")
                        if fileManager.fileExists(atPath: finalZipURL.path) {
                            try fileManager.removeItem(at: finalZipURL)
                        }
                        try fileManager.copyItem(at: zipURL, to: finalZipURL)
                        continuation.resume(returning: finalZipURL)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }

                if let coordinatorError {
                    continuation.resume(throwing: coordinatorError)
                }
            }
        }.value
    }

    /// Best-effort automatic trigger. Silently no-ops if unconfigured or unchanged;
    /// failures surface via `needsAttention`/`lastBackupDate` in the UI, not an alert,
    /// since this can fire outside of any user-initiated action.
    func autoBackupIfNeeded(receipts: [ExpenseReceipt]) async {
        guard !isBackingUp else { return }
        guard UserDefaults.standard.data(forKey: bookmarkKey) != nil else { return }

        let currentSignature = signature(for: receipts)
        let lastSignature = UserDefaults.standard.string(forKey: lastBackupSignatureKey)
        guard currentSignature != lastSignature else { return }

        isBackingUp = true
        defer { isBackingUp = false }

        _ = try? await writeBackupNow(receipts: receipts)
    }

    private func pruneOldBackups(in folderURL: URL) {
        guard let items = try? FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil) else { return }
        let backups = items
            .filter { $0.lastPathComponent.hasPrefix(filenamePrefix) }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }

        guard backups.count > maxRetainedBackups else { return }
        for item in backups.dropFirst(maxRetainedBackups) {
            try? FileManager.default.removeItem(at: item)
        }
    }
}
