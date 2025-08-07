//
//  Tides_BelgiumTests.swift
//  Tides BelgiumTests
//
//  Created by Nicolai Gosselin on 01/07/2025.
//

import Testing
@testable import Tides_Belgium

struct Tides_BelgiumTests {

    @Test func testTideStationCreation() async throws {
        let station = TideStation(
            id: "test",
            name: "Test Station",
            latitude: 51.2194,
            longitude: 2.9185,
            country: "Belgium"
        )
        
        #expect(station.id == "test")
        #expect(station.name == "Test Station")
        #expect(station.country == "Belgium")
    }
    
    @Test func testBelgianStationsExist() async throws {
        #expect(TideStation.belgianStations.count > 0)
        
        let oostende = TideStation.belgianStations.first { $0.id == "oostende" }
        #expect(oostende != nil)
        #expect(oostende?.name == "Oostende")
        #expect(oostende?.country == "Belgium")
    }
    
    @Test func testTideDataCreation() async throws {
        let now = Date()
        let tide = TideData(time: now, height: 3.5, type: .high)
        
        #expect(tide.time == now)
        #expect(tide.height == 3.5)
        #expect(tide.type == .high)
    }
    
    @Test func testUserPreferences() async throws {
        let preferences = UserPreferences()
        
        // Should have a default station
        #expect(preferences.selectedStation != nil)
        
        // Test changing station
        let newStation = TideStation(
            id: "test",
            name: "Test",
            latitude: 0,
            longitude: 0,
            country: "Test"
        )
        
        preferences.selectedStation = newStation
        #expect(preferences.selectedStation?.id == "test")
    }
    
    @Test func testTideService() async throws {
        let service = TideService()
        let station = TideStation.belgianStations[0]
        
        service.fetchTideData(for: station)
        
        // Give the async operation time to complete
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        #expect(service.tideData.count > 0)
        #expect(service.currentTideHeight > 0)
    }
}
