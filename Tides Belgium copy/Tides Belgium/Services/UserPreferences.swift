//
//  UserPreferences.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 01/07/2025.
//

import Foundation
import Combine

class UserPreferences: ObservableObject {
    @Published var selectedStation: TideStation? {
        didSet {
            saveSelectedStation()
        }
    }
    
    private let selectedStationKey = "selectedTideStation"
    
    init() {
        loadSelectedStation()
    }
    
    private func saveSelectedStation() {
        guard let station = selectedStation else {
            UserDefaults.standard.removeObject(forKey: selectedStationKey)
            return
        }
        
        if let encoded = try? JSONEncoder().encode(station) {
            UserDefaults.standard.set(encoded, forKey: selectedStationKey)
        }
    }
    
    private func loadSelectedStation() {
        guard let data = UserDefaults.standard.data(forKey: selectedStationKey),
              let station = try? JSONDecoder().decode(TideStation.self, from: data) else {
            // Don't set a default - let user choose
            selectedStation = nil
            return
        }
        
        selectedStation = station
    }
}
