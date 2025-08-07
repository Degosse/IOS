//
//  Tides_BelgiumApp.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 01/07/2025.
//

import SwiftUI

@main
struct Tides_BelgiumApp: App {
    @StateObject private var localizationManager = LocalizationManager()
    
    var body: some Scene {
        WindowGroup {
            LaunchScreenView()
                .environment(\.localizationManager, localizationManager)
        }
    }
}
