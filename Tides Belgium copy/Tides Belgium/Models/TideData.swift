//
//  TideData.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 01/07/2025.
//

import Foundation

struct TideData: Codable, Identifiable {
    let id = UUID()
    let time: Date
    let height: Double
    let type: TideType
    
    enum TideType: String, Codable, CaseIterable {
        case high = "high"
        case low = "low"
        case current = "current"
        case regular = "regular"
    }
    
    private enum CodingKeys: String, CodingKey {
        case time, height, type
    }
}

struct TideStation: Codable, Identifiable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
    
    // Belgian tide stations - Only official government supported cities
    static let belgianStations = [
        TideStation(id: "oostende", name: "Oostende", latitude: 51.2194, longitude: 2.9185, country: "Belgium"),
        TideStation(id: "zeebrugge", name: "Zeebrugge", latitude: 51.3292, longitude: 3.2, country: "Belgium"),
        TideStation(id: "nieuwpoort", name: "Nieuwpoort", latitude: 51.1343, longitude: 2.7574, country: "Belgium"),
        TideStation(id: "blankenberge", name: "Blankenberge", latitude: 51.3137, longitude: 3.1305, country: "Belgium")
    ]
}

struct TideResponse: Codable {
    let tides: [TideData]
    let station: TideStation
}
