import Foundation
import SwiftData

struct ReceiptBackupDTO: Codable {
    let id: UUID
    let date: Date
    let restaurantName: String
    let totalPrice: Double
    let modifiedAt: Date
    /// Filename of the receipt photo relative to the backup snapshot's "images" folder — never
    /// inlined as base64, since a single very long text line makes Files-app previews hang.
    let imageFilename: String?
}

struct BackupManifest: Codable {
    let formatVersion: Int
    let exportedAt: Date
    let receipts: [ReceiptBackupDTO]
}

struct RestoreSummary {
    let imported: Int
    let updated: Int
    let skippedDuplicates: Int
    let total: Int
}

enum BackupServiceError: LocalizedError {
    case incompatibleFormatVersion(Int)

    var errorDescription: String? {
        switch self {
        case .incompatibleFormatVersion(let version):
            return "This backup uses format version \(version), which this version of the app can't restore."
        }
    }
}

final class BackupService {
    static let shared = BackupService()
    private init() {}

    private let currentFormatVersion = 2

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Builds the manifest describing a snapshot. Pure/no I/O — writing the referenced image
    /// files to disk is the caller's responsibility (see `BackupFolderManager`).
    func buildManifest(receipts: [ExpenseReceipt]) -> BackupManifest {
        let dtos = receipts.map { receipt in
            ReceiptBackupDTO(
                id: receipt.id,
                date: receipt.date,
                restaurantName: receipt.restaurantName,
                totalPrice: receipt.totalPrice,
                modifiedAt: receipt.modifiedAt,
                imageFilename: receipt.imageData != nil ? "\(receipt.id.uuidString).jpg" : nil
            )
        }
        return BackupManifest(formatVersion: currentFormatVersion, exportedAt: Date.now, receipts: dtos)
    }

    func encode(_ manifest: BackupManifest) throws -> Data {
        try encoder.encode(manifest)
    }

    func decode(_ data: Data) throws -> BackupManifest {
        let manifest = try decoder.decode(BackupManifest.self, from: data)
        guard manifest.formatVersion == currentFormatVersion else {
            throw BackupServiceError.incompatibleFormatVersion(manifest.formatVersion)
        }
        return manifest
    }

    private func imageData(for dto: ReceiptBackupDTO, imagesDirectory: URL) -> Data? {
        guard let filename = dto.imageFilename else { return nil }
        return try? Data(contentsOf: imagesDirectory.appendingPathComponent(filename))
    }

    @discardableResult
    func restore(manifest: BackupManifest, imagesDirectory: URL, into context: ModelContext) throws -> RestoreSummary {
        let existing = try context.fetch(FetchDescriptor<ExpenseReceipt>())
        var byId = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        var imported = 0
        var updated = 0
        var skipped = 0

        for dto in manifest.receipts {
            if let match = byId[dto.id] {
                if dto.modifiedAt > match.modifiedAt {
                    match.date = dto.date
                    match.restaurantName = dto.restaurantName
                    match.totalPrice = dto.totalPrice
                    // Never let a restore clobber an existing photo with a missing one —
                    // the photo is the actual evidence and must never be silently lost.
                    if let newImageData = imageData(for: dto, imagesDirectory: imagesDirectory) {
                        match.imageData = newImageData
                    }
                    match.modifiedAt = dto.modifiedAt
                    updated += 1
                } else {
                    skipped += 1
                }
            } else {
                let newReceipt = ExpenseReceipt(
                    id: dto.id,
                    date: dto.date,
                    restaurantName: dto.restaurantName,
                    totalPrice: dto.totalPrice,
                    imageData: imageData(for: dto, imagesDirectory: imagesDirectory),
                    modifiedAt: dto.modifiedAt
                )
                context.insert(newReceipt)
                byId[dto.id] = newReceipt
                imported += 1
            }
        }

        try context.save()
        return RestoreSummary(imported: imported, updated: updated, skippedDuplicates: skipped, total: manifest.receipts.count)
    }
}
