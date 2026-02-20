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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ExpenseReceipt.self)
    }
}

