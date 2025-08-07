//
//  ContentView.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ReceiptListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Receipt.self, inMemory: true)
}
