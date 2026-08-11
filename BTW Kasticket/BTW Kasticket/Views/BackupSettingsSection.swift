import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BackupSettingsSection: View {
    let receipts: [ExpenseReceipt]
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var folderManager = BackupFolderManager.shared
    @AppStorage("appLanguage") private var language = "nl"

    @State private var isBackingUp = false
    @State private var isRestoring = false
    @State private var showFolderPicker = false
    @State private var showRestorePicker = false
    @State private var exportShareURL: URL?
    @State private var showExportShareSheet = false

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        Section(header: Text("Backup & Restore".localized(language))) {
            HStack {
                Label {
                    Text("Last backup".localized(language))
                } icon: {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                }
                Spacer()
                Text(statusText)
                    .foregroundColor(statusColor)
                    .multilineTextAlignment(.trailing)
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK".localized(language), role: .cancel) {}
            } message: {
                Text(alertMessage)
            }

            Button {
                showFolderPicker = true
            } label: {
                Label(
                    folderManager.folderConfigured ? "Change Backup Folder".localized(language) : "Choose Backup Folder".localized(language),
                    systemImage: "folder"
                )
            }
            .fileImporter(isPresented: $showFolderPicker, allowedContentTypes: [.folder]) { result in
                handleFolderPick(result)
            }

            Button {
                backUpNow()
            } label: {
                HStack {
                    if isBackingUp {
                        ProgressView()
                            .padding(.trailing, 5)
                        Text("Backing up...".localized(language))
                    } else {
                        Label("Back up now".localized(language), systemImage: "icloud.and.arrow.up")
                    }
                }
            }
            .disabled(isBackingUp || !folderManager.folderConfigured)

            Button {
                showRestorePicker = true
            } label: {
                HStack {
                    if isRestoring {
                        ProgressView()
                            .padding(.trailing, 5)
                        Text("Restoring...".localized(language))
                    } else {
                        Label("Restore from Backup".localized(language), systemImage: "tray.and.arrow.down")
                    }
                }
            }
            .disabled(isRestoring)
            .fileImporter(isPresented: $showRestorePicker, allowedContentTypes: [.folder]) { result in
                handleRestorePick(result)
            }

            Button {
                exportBackupFile()
            } label: {
                Label("Export Backup File".localized(language), systemImage: "square.and.arrow.up")
            }
            .sheet(isPresented: $showExportShareSheet) {
                if let url = exportShareURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private var statusText: String {
        if folderManager.needsAttention {
            return "Backup folder needs attention — tap to reselect".localized(language)
        }
        if !folderManager.folderConfigured {
            return "Backup folder not configured".localized(language)
        }
        guard let date = folderManager.lastBackupDate else {
            return "Never backed up".localized(language)
        }
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date.now)
    }

    private var statusColor: Color {
        if folderManager.needsAttention { return .red }
        if !folderManager.folderConfigured || folderManager.lastBackupDate == nil { return .orange }
        return .secondary
    }

    private var statusIcon: String {
        if folderManager.needsAttention { return "exclamationmark.triangle.fill" }
        if !folderManager.folderConfigured || folderManager.lastBackupDate == nil { return "icloud.slash" }
        return "checkmark.icloud.fill"
    }

    private func backUpNow() {
        isBackingUp = true
        Task {
            do {
                _ = try await folderManager.writeBackupNow(receipts: receipts)
            } catch {
                showError(title: "Backup Failed".localized(language), error: error)
            }
            isBackingUp = false
        }
    }

    private func handleFolderPick(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                try folderManager.setFolder(url)
                backUpNow()
            } catch {
                showError(title: "Backup Failed".localized(language), error: error)
            }
        case .failure(let error):
            showError(title: "Backup Failed".localized(language), error: error)
        }
    }

    private func handleRestorePick(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            isRestoring = true
            Task {
                await restore(from: url)
                isRestoring = false
            }
        case .failure(let error):
            showError(title: "Restore Failed".localized(language), error: error)
        }
    }

    private func restore(from folderURL: URL) async {
        guard folderURL.startAccessingSecurityScopedResource() else {
            showError(title: "Restore Failed".localized(language), error: BackupFolderError.accessDenied)
            return
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        do {
            let manifestData = try Data(contentsOf: folderURL.appendingPathComponent("manifest.json"))
            let manifest = try BackupService.shared.decode(manifestData)
            let imagesURL = folderURL.appendingPathComponent("images")
            let summary = try BackupService.shared.restore(manifest: manifest, imagesDirectory: imagesURL, into: modelContext)
            alertTitle = "Restore Successful".localized(language)
            alertMessage = "\("New receipts imported".localized(language)): \(summary.imported)\n"
                + "\("Receipts updated".localized(language)): \(summary.updated)\n"
                + "\("Duplicates skipped".localized(language)): \(summary.skippedDuplicates)"
            showAlert = true
        } catch {
            showError(title: "Invalid backup file".localized(language), error: error)
        }
    }

    private func exportBackupFile() {
        Task {
            do {
                let url = try await folderManager.buildShareableArchive(receipts: receipts)
                exportShareURL = url
                showExportShareSheet = true
            } catch {
                showError(title: "Backup Failed".localized(language), error: error)
            }
        }
    }

    private func showError(title: String, error: Error) {
        alertTitle = title
        alertMessage = error.localizedDescription
        showAlert = true
    }
}
