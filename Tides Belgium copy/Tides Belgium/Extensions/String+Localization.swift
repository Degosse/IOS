//
//  String+Localization.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 01/07/2025.
//

import SwiftUI

extension String {
    func localized(_ localizationManager: LocalizationManager) -> String {
        return localizationManager.localizedString(for: self)
    }
}

// Environment key for localization manager
struct LocalizationManagerKey: EnvironmentKey {
    static let defaultValue = LocalizationManager()
}

extension EnvironmentValues {
    var localizationManager: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}

// View modifier for easy access to localized strings
struct LocalizedText: View {
    let key: String
    @Environment(\.localizationManager) private var localizationManager
    
    init(_ key: String) {
        self.key = key
    }
    
    var body: some View {
        Text(localizationManager.localizedString(for: key))
    }
}

// Helper function for localized strings in views
func L(_ key: String, _ localizationManager: LocalizationManager) -> String {
    return localizationManager.localizedString(for: key)
}
