#!/usr/bin/env swift

// Simple test to verify TideTableView logic
import Foundation

struct TideData {
    let id = UUID()
    let time: Date
    let height: Double
    let type: TideType
    
    enum TideType: String {
        case high = "high_tide"
        case low = "low_tide"
        case current = "current"
    }
}

// Test data generation
func generateTestTideData() -> [TideData] {
    let now = Date()
    var tides: [TideData] = []
    
    // Generate 10 tides over next 30 hours
    for i in 0..<10 {
        let time = now.addingTimeInterval(Double(i) * 3600 * 3) // Every 3 hours
        let height = Double.random(in: 0.5...4.5)
        let type: TideData.TideType = i % 2 == 0 ? .high : .low
        
        tides.append(TideData(time: time, height: height, type: type))
    }
    
    return tides
}

// Test filtering logic
func testNext24HourFiltering() {
    let tides = generateTestTideData()
    let now = Date()
    let next24Hours = now.addingTimeInterval(24 * 3600)
    
    let filteredTides = tides.filter { tide in
        tide.time >= now && tide.time <= next24Hours && tide.type != .current
    }.sorted { $0.time < $1.time }
    
    print("Generated \(tides.count) total tides")
    print("Next 24 hours contains \(filteredTides.count) tides")
    
    for (index, tide) in filteredTides.prefix(8).enumerated() {
        let timeInterval = tide.time.timeIntervalSinceNow
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval % 3600) / 60
        let timeString = hours > 0 ? "\(hours)h" : "\(minutes)m"
        
        print("\(index + 1). \(tide.type.rawValue) at \(tide.time) (\(String(format: "%.1f", tide.height))m) - in \(timeString)")
    }
}

// Run test
testNext24HourFiltering()
