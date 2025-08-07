//
//  TideService.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 01/07/2025.
//

import Foundation
import Combine

class TideService: ObservableObject {
    @Published var tideData: [TideData] = []
    @Published var currentTideHeight: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var selectedDate: Date = Date() // Track the selected date (today or tomorrow)
    @Published var isShowingTomorrow: Bool = false // Track if showing tomorrow's data
    
    private var cancellables = Set<AnyCancellable>()
    private var allTideData: [TideData] = [] // Store all parsed tide data (today + tomorrow)
    
    // Official data service for Belgian government tide data
    private let officialDataService = OfficialTideDataService()
    
    // Provide access to all tide data for charting (includes today + tomorrow for smooth flow)
    var allAvailableTideData: [TideData] {
        return allTideData
    }
    
    // Only support officially documented stations
    enum SupportedStation: String, CaseIterable {
        case nieuwpoort
        case zeebrugge
        case oostende
        case blankenberge
        
        var displayName: String {
            switch self {
            case .nieuwpoort: return "Nieuwpoort"
            case .zeebrugge: return "Zeebrugge"
            case .oostende: return "Oostende"
            case .blankenberge: return "Blankenberge"
            }
        }
        
        var officialStation: OfficialTideDataService.OfficialStation {
            switch self {
            case .nieuwpoort: return .nieuwpoort
            case .zeebrugge: return .zeebrugge
            case .oostende: return .oostende
            case .blankenberge: return .blankenberge
            }
        }
    }

    // Main fetch function using official Belgian government data
    func fetchTideData(for station: TideStation) {
        print("🌊 fetchTideData called for station: \(station.name) (id: \(station.id))")
        isLoading = true
        error = nil
        
        // Clear existing data
        tideData = []
        
        // Map station IDs to supported stations
        let supportedStation: SupportedStation?
        switch station.id.lowercased() {
        case "nieuwpoort":
            supportedStation = .nieuwpoort
        case "zeebrugge":
            supportedStation = .zeebrugge
        case "oostende":
            supportedStation = .oostende
        case "blankenberge":
            supportedStation = .blankenberge
        default:
            supportedStation = nil
        }
        
        guard let supported = supportedStation else {
            print("❌ Station \(station.id) is not supported")
            self.error = "Station not available in official data: \(station.name)"
            self.isLoading = false
            return
        }
        print("✅ Matched to supported station: \(supported.displayName)")
        
        // Use official Belgian government data
        fetchOfficialTideData(for: supported)
    }

    // Fetch from official Belgian government data
    private func fetchOfficialTideData(for station: SupportedStation) {
        Task {
            do {
                print("🏛️ Fetching official government data for \(station.displayName)")
                let officialTides = try await officialDataService.getTideData(for: station.officialStation)
                
                DispatchQueue.main.async {
                    print("� Received \(officialTides.count) official tide entries for \(station.displayName)")
                    
                    if officialTides.isEmpty {
                        print("❌ No official tide data found, creating sample data as fallback")
                        self.error = "No official data available, showing sample data"
                        self.allTideData = self.createSampleTideData(for: station.displayName)
                    } else {
                        print("🎯 SUCCESS: Using official Belgian government data!")
                        print("🎯 First tide: \(officialTides.first!.time) - \(String(format: "%.2f", officialTides.first!.height))m")
                        self.error = nil
                        self.allTideData = officialTides
                    }
                    
                    // Filter to show only the selected date's data
                    self.filterTidesForSelectedDate()
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    print("❌ Failed to fetch official data: \(error.localizedDescription)")
                    self.error = "Failed to load official data: \(error.localizedDescription)"
                    
                    // Fallback to sample data
                    self.allTideData = self.createSampleTideData(for: station.displayName)
                    self.filterTidesForSelectedDate()
                    self.isLoading = false
                }
            }
        }
    }

    // Create sample tide data as fallback when official data is not available
    private func createSampleTideData(for stationName: String) -> [TideData] {
        var tides: [TideData] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        print("⚠️ FALLBACK: Creating sample tide data for \(stationName) - official data not available!")
        
        // Create realistic tide patterns for Belgian coast
        let baseTideTimes: [(hour: Int, minute: Int, isHigh: Bool)] = [
            (6, 30, true),   // Morning high tide
            (12, 45, false), // Afternoon low tide
            (19, 15, true),  // Evening high tide
            (1, 0, false)    // Early morning low tide (next day)
        ]
        
        // Adjust heights and times based on station
        let stationData: (heightMultiplier: Double, timeOffset: Int) = {
            switch stationName {
            case "Zeebrugge": 
                return (1.0, 15)  // Reference station
            case "Oostende": 
                return (0.95, 0)  // Slightly lower
            case "Nieuwpoort": 
                return (0.9, -10) // Lower tides, earlier
            case "Blankenberge":
                return (1.02, 10) // Between Zeebrugge and Oostende
            default: 
                return (1.0, 0)
            }
        }()
        
        // Generate tides for today and tomorrow
        for dayOffset in 0...1 {
            let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: today)!
            
            for (hour, minute, isHigh) in baseTideTimes {
                let adjustedHour = hour
                let adjustedMinute = minute + stationData.timeOffset
                
                // Handle minute overflow
                let finalHour = adjustedMinute >= 60 ? adjustedHour + 1 : (adjustedMinute < 0 ? adjustedHour - 1 : adjustedHour)
                let finalMinute = adjustedMinute >= 60 ? adjustedMinute - 60 : (adjustedMinute < 0 ? adjustedMinute + 60 : adjustedMinute)
                
                if let tideTime = calendar.date(bySettingHour: finalHour, minute: finalMinute, second: 0, of: baseDate) {
                    let baseHeight: Double = isHigh ? 4.2 : 0.8
                    let adjustedHeight = baseHeight * stationData.heightMultiplier
                    
                    // Add some realistic variation (±10%)
                    let variation = Double.random(in: 0.9...1.1)
                    let finalHeight = adjustedHeight * variation
                    
                    let type: TideData.TideType = isHigh ? .high : .low
                    tides.append(TideData(time: tideTime, height: finalHeight, type: type))
                }
            }
        }
        
        print("⚠️ Generated \(tides.count) FALLBACK sample tides for \(stationName)")
        return tides.sorted { $0.time < $1.time }
    }
    
    // Methods to handle date selection (today/tomorrow)
    func showToday() {
        isShowingTomorrow = false
        selectedDate = Date()
        filterTidesForSelectedDate()
    }
    
    func showTomorrow() {
        isShowingTomorrow = true
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        filterTidesForSelectedDate()
    }
    
    private func filterTidesForSelectedDate() {
        let calendar = Calendar.current
        let selectedDayStart = calendar.startOfDay(for: selectedDate)
        let selectedDayEnd = calendar.date(byAdding: .day, value: 1, to: selectedDayStart)!
        
        print("📅 Filtering tides for date: \(selectedDate)")
        print("📅 Looking for tides between \(selectedDayStart) and \(selectedDayEnd)")
        print("📅 Total stored tides: \(allTideData.count)")
        
        // Filter to show only tides for the selected date from all stored data
        let filteredTides = allTideData.filter { tide in
            let tideDate = tide.time
            return tideDate >= selectedDayStart && tideDate < selectedDayEnd
        }
        
        print("📊 Filtered from \(allTideData.count) total tides to \(filteredTides.count) tides for selected date")
        
        // Update the published tideData to trigger UI refresh
        if filteredTides.count > 0 {
            tideData = filteredTides
            // Use interpolated height for more accuracy
            currentTideHeight = interpolateCurrentHeight(from: filteredTides) ?? filteredTides.first?.height ?? 0.0
        } else {
            print("⚠️ No tides found for selected date, showing all data")
            tideData = allTideData
            currentTideHeight = interpolateCurrentHeight(from: allTideData) ?? allTideData.first?.height ?? 0.0
        }
        
        print("🎯 Final tideData count for UI: \(tideData.count)")
    }
    
    // Calculate interpolated current height for more accurate real-time data
    private func interpolateCurrentHeight(from tides: [TideData]) -> Double? {
        let now = Date()
        
        // Find the two tides that bracket the current time
        let sortedTides = tides.sorted { $0.time < $1.time }
        
        for i in 0..<(sortedTides.count - 1) {
            let currentTide = sortedTides[i]
            let nextTide = sortedTides[i + 1]
            
            if now >= currentTide.time && now <= nextTide.time {
                // Linear interpolation between the two points
                let timeRange = nextTide.time.timeIntervalSince(currentTide.time)
                let currentTimeOffset = now.timeIntervalSince(currentTide.time)
                let ratio = currentTimeOffset / timeRange
                
                let heightDifference = nextTide.height - currentTide.height
                let interpolatedHeight = currentTide.height + (heightDifference * ratio)
                
                print("🔢 Interpolated current height: \(String(format: "%.2f", interpolatedHeight))m (between \(String(format: "%.2f", currentTide.height))m and \(String(format: "%.2f", nextTide.height))m)")
                
                return interpolatedHeight
            }
        }
        
        // If we can't interpolate, return the closest tide's height
        let closestTide = sortedTides.min { abs($0.time.timeIntervalSince(now)) < abs($1.time.timeIntervalSince(now)) }
        return closestTide?.height
    }
}
