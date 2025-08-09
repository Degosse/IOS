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
    
    // Provide access to all tide data for charting (includes today + tomorrow for smooth flow)
    var allAvailableTideData: [TideData] {
        return allTideData
    }
    
    // Only support these 5 stations with Excel data
    enum SupportedStation: String, CaseIterable {
        case antwerpen
        case blankenberge
        case nieuwpoort
        case oostende
        case zeebrugge
        
        var displayName: String {
            switch self {
            case .antwerpen: return "Antwerpen"
            case .blankenberge: return "Blankenberge"
            case .nieuwpoort: return "Nieuwpoort"
            case .oostende: return "Oostende"
            case .zeebrugge: return "Zeebrugge"
            }
        }
    }

    // Main fetch function, now uses Excel data for the 5 supported cities
    func fetchTideData(for station: TideStation) {
        print("🌊 fetchTideData called for station: \(station.name) (id: \(station.id))")
        isLoading = true
        error = nil
        
        // Clear existing data
        tideData = []
        
        // Map station IDs to supported stations
        let supportedStation: SupportedStation?
        switch station.id.lowercased() {
        case "antwerpen":
            supportedStation = .antwerpen
        case "blankenberge":
            supportedStation = .blankenberge
        case "nieuwpoort":
            supportedStation = .nieuwpoort
        case "oostende":
            supportedStation = .oostende
        case "zeebrugge":
            supportedStation = .zeebrugge
        default:
            supportedStation = nil
        }
        
        guard let supported = supportedStation else {
            print("❌ Station \(station.id) is not supported")
            self.error = "Unsupported station: \(station.name). Only Antwerpen, Blankenberge, Nieuwpoort, Oostende, and Zeebrugge are supported."
            self.isLoading = false
            return
        }
        print("✅ Matched to supported station: \(supported.displayName)")
        
        fetchExcelTideData(for: supported)
    }
    
    // Fetch tide data from Excel/JSON files
    private func fetchExcelTideData(for station: SupportedStation) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        print("🔄 Loading tide data for \(station.displayName) for today and tomorrow")
        print("📅 Today date: \(today)")
        print("📅 Tomorrow date: \(tomorrow)")
        
        // Try JSON parser first, then fallback to Excel parser (sample data)
        let currentYear = calendar.component(.year, from: today)
            let jsonFileName = "\(station.rawValue)_\(currentYear).json"
            
            var parsedTides: [TideData] = []
            
            // Check if JSON file exists
            if Bundle.main.path(forResource: jsonFileName.replacingOccurrences(of: ".json", with: ""), ofType: "json") != nil {
                print("📊 Using JSON tide data")
                parsedTides = JSONTideParser.parseTideData(
                    for: ExcelTideParser.SupportedStation(rawValue: station.rawValue) ?? .oostende,
                    startDate: today,
                    endDate: tomorrow
                )
            } else {
                print("📊 JSON file not found, using sample data")
                parsedTides = ExcelTideParser.parseTideData(
                    for: ExcelTideParser.SupportedStation(rawValue: station.rawValue) ?? .oostende,
                    startDate: today,
                    endDate: tomorrow
                )
            }
            
            DispatchQueue.main.async {
                if parsedTides.isEmpty {
                    print("❌ No tide data found")
                    self.error = "No tide data found for \(station.displayName). Please check if data files are available."
                    self.allTideData = self.createSampleTideData(for: station.displayName)
                } else {
                    print("🎯 SUCCESS: Using tide data!")
                    print("🎯 First tide: \(parsedTides.first!.time) - \(String(format: "%.2f", parsedTides.first!.height))m")
                    self.error = nil
                    self.allTideData = parsedTides
                }
                
                // Filter to show only the selected date's data
                self.filterTidesForSelectedDate()
                self.isLoading = false
            }
        }
    }

    // Fetch from TidesChart
    
    // Create sample tide data as fallback when parsing fails
    private func createSampleTideData(for stationName: String) -> [TideData] {
        var tides: [TideData] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        print("⚠️ FALLBACK: Creating sample tide data for \(stationName) - parsing failed!")
        
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
            case "Knokke-Heist":
                return (1.05, 20) // Similar to Zeebrugge
            case "Blankenberge":
                return (1.02, 10) // Between Zeebrugge and Oostende
            case "De Haan":
                return (0.98, 5)  // Similar to Oostende
            case "Middelkerke":
                return (0.93, -5) // Between Oostende and Nieuwpoort
            case "De Panne":
                return (0.88, -15) // Similar to Nieuwpoort, slightly earlier
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
        let calendar = Calendar.current
        selectedDate = calendar.startOfDay(for: Date())
        print("🔄 showToday() called - selectedDate set to: \(selectedDate)")
        print("🔄 selectedDate components: \(calendar.dateComponents([.year, .month, .day], from: selectedDate))")
        filterTidesForSelectedDate()
    }
    
    func showTomorrow() {
        isShowingTomorrow = true
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        selectedDate = tomorrow
        print("🔄 showTomorrow() called - selectedDate set to: \(selectedDate)")
        print("🔄 selectedDate components: \(calendar.dateComponents([.year, .month, .day], from: selectedDate))")
        filterTidesForSelectedDate()
    }
    
    private func filterTidesForSelectedDate() {
        let calendar = Calendar.current
        let selectedDayStart = calendar.startOfDay(for: selectedDate)
        let selectedDayEnd = calendar.date(byAdding: .day, value: 1, to: selectedDayStart)!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy HH:mm"
        
        print("📅 Filtering tides for date: \(formatter.string(from: selectedDate))")
        print("📅 Looking for tides between \(formatter.string(from: selectedDayStart)) and \(formatter.string(from: selectedDayEnd))")
        print("📅 Total stored tides: \(allTideData.count)")
        print("📅 isShowingTomorrow: \(isShowingTomorrow)")
        
        // Log all stored tides for debugging
        for (index, tide) in allTideData.enumerated() {
            let tideFormatter = DateFormatter()
            tideFormatter.dateFormat = "MMM d, HH:mm"
            let tideComponents = calendar.dateComponents([.year, .month, .day], from: tide.time)
            let dayStr = calendar.isDateInTomorrow(tide.time) ? "TOMORROW" : (calendar.isDateInToday(tide.time) ? "TODAY" : "OTHER")
            print("📊 Stored tide \(index + 1) (\(dayStr)): \(tideFormatter.string(from: tide.time)) [Y:\(tideComponents.year ?? 0) M:\(tideComponents.month ?? 0) D:\(tideComponents.day ?? 0)] - \(String(format: "%.2f", tide.height))m (\(tide.type == .high ? "HIGH" : "LOW"))")
        }
        
        // Filter to show only tides for the selected date from all stored data
        let filteredTides = allTideData.filter { tide in
            let tideDate = tide.time
            let isInRange = tideDate >= selectedDayStart && tideDate < selectedDayEnd
            if !isInRange {
                let tideFormatter = DateFormatter()
                tideFormatter.dateFormat = "MMM d, HH:mm"
                print("🚫 Excluding tide outside range: \(tideFormatter.string(from: tide.time))")
            } else {
                let tideFormatter = DateFormatter()
                tideFormatter.dateFormat = "MMM d, HH:mm"
                print("✅ Including tide in range: \(tideFormatter.string(from: tide.time))")
            }
            return isInRange
        }
        
        print("📊 Filtered from \(allTideData.count) total tides to \(filteredTides.count) tides for selected date")
        
        // Log filtered results
        for (index, tide) in filteredTides.enumerated() {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            print("📈 Filtered tide \(index + 1): \(formatter.string(from: tide.time)) - \(String(format: "%.2f", tide.height))m (\(tide.type == .high ? "HIGH" : "LOW"))")
        }
        
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
