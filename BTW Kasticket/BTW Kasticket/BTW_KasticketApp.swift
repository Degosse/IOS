//
//  BTW_KasticketApp.swift
//  BTW Kasticket
//
//  Created by Nicolaï Gosselin on 20/02/2026.
//

import SwiftUI
import SwiftData

@main
struct BTW_KasticketApp: App {
    let container: ModelContainer = {
        do {
            return try ModelContainer(for: ExpenseReceipt.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                let receipts = (try? container.mainContext.fetch(FetchDescriptor<ExpenseReceipt>())) ?? []
                Task {
                    await BackupFolderManager.shared.autoBackupIfNeeded(receipts: receipts)
                }
            }
        }
    }
}

