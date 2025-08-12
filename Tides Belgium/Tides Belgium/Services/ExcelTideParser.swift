//
//  ExcelTideParser.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 09/08/2025.
//

import Foundation

class ExcelTideParser {
    
    // Supported stations mapping to Excel file names
    enum SupportedStation: String, CaseIterable {
        case antwerpen = "antwerpen"
        case blankenberge = "blankenberge"
        case nieuwpoort = "nieuwpoort"
        case oostende = "oostende"
        case zeebrugge = "zeebrugge"
        
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
    
    // Parse tide data for a specific station and date range
    // NOTE: This is now a fallback - JSONTideParser should be used for real data
    static func parseTideData(for station: SupportedStation, startDate: Date, endDate: Date) -> [TideData] {
        print("⚠️ ExcelTideParser fallback: Creating basic tide pattern for \(station.displayName)")
        print("⚠️ This should only be used when JSON data is unavailable")
        
        return createBasicTidePattern(for: station, startDate: startDate, endDate: endDate)
    }
    
    // Create a basic tide pattern as fallback when real data is unavailable
    private static func createBasicTidePattern(for station: SupportedStation, startDate: Date, endDate: Date) -> [TideData] {
        var tides: [TideData] = []
        let calendar = Calendar.current
        var currentDate = startDate
        
        // Basic tide pattern: 2 high and 2 low tides per day
        let baseTimes = [(6, 30, true), (12, 45, false), (19, 15, true), (1, 0, false)] // (hour, minute, isHigh)
        
        while currentDate <= endDate {
            for (hour, minute, isHigh) in baseTimes {
                var tideDate = currentDate
                if hour < 6 { // Early morning tide belongs to next day
                    tideDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                }
                
                let tideTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: tideDate) ?? tideDate
                
                let height = isHigh ? getStationHighTideHeight(for: station) : getStationLowTideHeight(for: station)
                let type: TideType = isHigh ? .high : .low
                
                tides.append(TideData(time: tideTime, height: height, type: type))
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            if calendar.isDate(currentDate, inSameDayAs: endDate) { break }
        }
        
        return tides.sorted { $0.time < $1.time }
    }
    
    // Get typical high tide height for each station
    private static func getStationHighTideHeight(for station: SupportedStation) -> Double {
        switch station {
        case .antwerpen: return 5.2
        case .blankenberge: return 4.3
        case .nieuwpoort: return 4.5
        case .oostende: return 4.4
        case .zeebrugge: return 4.6
        }
    }
    
    // Get typical low tide height for each station
    private static func getStationLowTideHeight(for station: SupportedStation) -> Double {
        switch station {
        case .antwerpen: return 0.5
        case .blankenberge: return 0.6
        case .nieuwpoort: return 0.4
        case .oostende: return 0.5
        case .zeebrugge: return 0.3
        }
    }
}
                    createTideData(date: date, hour: 8, minute: 25, height: 0.45, type: .low),
                    createTideData(date: date, hour: 14, minute: 10, height: 4.58, type: .high),
                    createTideData(date: date, hour: 20, minute: 55, height: 0.15, type: .low)
                ]
            case .zeebrugge:
                return [
                    createTideData(date: date, hour: 2, minute: 15, height: 4.95, type: .high),
                    createTideData(date: date, hour: 8, minute: 50, height: 0.25, type: .low),
                    createTideData(date: date, hour: 14, minute: 40, height: 4.90, type: .high),
                    createTideData(date: date, hour: 21, minute: 20, height: -0.05, type: .low)
                ]
            case .blankenberge:
                return [
                    createTideData(date: date, hour: 2, minute: 5, height: 4.70, type: .high),
                    createTideData(date: date, hour: 8, minute: 35, height: 0.35, type: .low),
                    createTideData(date: date, hour: 14, minute: 25, height: 4.68, type: .high),
                    createTideData(date: date, hour: 21, minute: 5, height: 0.05, type: .low)
                ]
            case .antwerpen:
                return [
                    createTideData(date: date, hour: 2, minute: 45, height: 5.35, type: .high),
                    createTideData(date: date, hour: 9, minute: 15, height: 0.55, type: .low),
                    createTideData(date: date, hour: 15, minute: 0, height: 5.30, type: .high),
                    createTideData(date: date, hour: 21, minute: 45, height: 0.45, type: .low)
                ]
            }
        }
        // August 11, 2025 (Nieuwpoort) - from official table
        else if dateComponents.year == 2025 && dateComponents.month == 8 && dateComponents.day == 11 {
            print("✅ MATCH: Using August 11, 2025 data for \(station.displayName)")
            switch station {
            case .nieuwpoort:
                // High water: 02:55 (5.01m), 15:11 (4.95m)
                // Low water: 09:42 (~0.30m placeholder), 22:11 (~0.25m placeholder)
                return [
                    createTideData(date: date, hour: 2, minute: 55, height: 5.01, type: .high),
                    createTideData(date: date, hour: 9, minute: 42, height: 0.30, type: .low),
                    createTideData(date: date, hour: 15, minute: 11, height: 4.95, type: .high),
                    createTideData(date: date, hour: 22, minute: 11, height: 0.25, type: .low)
                ]
            default:
                // Other stations: use pattern for now
                let tidePatterns = getTidePatterns(for: station)
                return createDailyTides(for: date, station: station, patterns: tidePatterns)
            }
        }
        // August 12, 2025 (Nieuwpoort) - from official table
        else if dateComponents.year == 2025 && dateComponents.month == 8 && dateComponents.day == 12 {
            print("✅ MATCH: Using August 12, 2025 data for \(station.displayName)")
            switch station {
            case .nieuwpoort:
                // High water: 03:34 (5.12m), 15:49 (5.06m)
                // Low water: 10:24 (~0.28m placeholder), 22:52 (~0.20m placeholder)
                return [
                    createTideData(date: date, hour: 3, minute: 34, height: 5.12, type: .high),
                    createTideData(date: date, hour: 10, minute: 24, height: 0.28, type: .low),
                    createTideData(date: date, hour: 15, minute: 49, height: 5.06, type: .high),
                    createTideData(date: date, hour: 22, minute: 52, height: 0.20, type: .low)
                ]
            default:
                // Other stations: use pattern for now
                let tidePatterns = getTidePatterns(for: station)
                return createDailyTides(for: date, station: station, patterns: tidePatterns)
            }
        }
        // For other dates, use pattern-based generation
        else {
            let formatter2 = DateFormatter()
            formatter2.dateFormat = "yyyy-MM-dd"
            print("⚠️ NO MATCH: No specific data for \(formatter.string(from: date)) (\(formatter2.string(from: date))) - Year: \(dateComponents.year ?? 0), Month: \(dateComponents.month ?? 0), Day: \(dateComponents.day ?? 0)")
            print("⚠️ Expected: Year: 2025, Month: 8, Day: 9 OR 10")
            let tidePatterns = getTidePatterns(for: station)
            return createDailyTides(for: date, station: station, patterns: tidePatterns)
        }
    }
    
    // Helper function to create TideData
    private static func createTideData(date: Date, hour: Int, minute: Int, height: Double, type: TideData.TideType) -> TideData {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Brussels") ?? .current
        let tideTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date)!
        return TideData(time: tideTime, height: max(0.0, height), type: type)
    }
    
    // Get tide patterns specific to each station
    private static func getTidePatterns(for station: SupportedStation) -> TidePatternInfo {
        switch station {
        case .antwerpen:
            return TidePatternInfo(
                highTideHeight: (4.8, 5.2),  // Higher tides due to river effect
                lowTideHeight: (0.2, 0.6),
                primaryHighTime: (6, 30),    // Morning high
                primaryLowTime: (0, 45),     // Early morning low
                secondaryHighTime: (19, 15), // Evening high
                secondaryLowTime: (13, 0)    // Afternoon low
            )
        case .blankenberge:
            return TidePatternInfo(
                highTideHeight: (4.2, 4.6),
                lowTideHeight: (0.4, 0.8),
                primaryHighTime: (6, 0),
                primaryLowTime: (0, 15),
                secondaryHighTime: (18, 45),
                secondaryLowTime: (12, 30)
            )
        case .nieuwpoort:
            return TidePatternInfo(
                highTideHeight: (4.0, 4.4),
                lowTideHeight: (0.3, 0.7),
                primaryHighTime: (5, 45),
                primaryLowTime: (23, 45),
                secondaryHighTime: (18, 30),
                secondaryLowTime: (12, 15)
            )
        case .oostende:
            return TidePatternInfo(
                highTideHeight: (4.1, 4.5),
                lowTideHeight: (0.3, 0.7),
                primaryHighTime: (6, 15),
                primaryLowTime: (0, 0),
                secondaryHighTime: (18, 45),
                secondaryLowTime: (12, 30)
            )
        case .zeebrugge:
            return TidePatternInfo(
                highTideHeight: (4.3, 4.7),
                lowTideHeight: (0.2, 0.6),
                primaryHighTime: (6, 30),
                primaryLowTime: (0, 15),
                secondaryHighTime: (19, 0),
                secondaryLowTime: (12, 45)
            )
        }
    }
    
    // Create realistic daily tide data
    private static func createDailyTides(for date: Date, station: SupportedStation, patterns: TidePatternInfo) -> [TideData] {
        let calendar = Calendar.current
        var tides: [TideData] = []
        
        // Add some daily variation (±30 minutes for timing, ±0.3m for height)
        let timeVariation = Int.random(in: -30...30) // minutes
        let heightVariation = Double.random(in: -0.3...0.3) // meters
        
        // Early morning low tide
        if let lowTime1 = calendar.date(bySettingHour: patterns.primaryLowTime.0, 
                                       minute: patterns.primaryLowTime.1 + timeVariation, 
                                       second: 0, of: date) {
            let height = Double.random(in: patterns.lowTideHeight.0...patterns.lowTideHeight.1) + heightVariation
            tides.append(TideData(time: lowTime1, height: max(0, height), type: .low))
        }
        
        // Morning high tide
        if let highTime1 = calendar.date(bySettingHour: patterns.primaryHighTime.0, 
                                        minute: patterns.primaryHighTime.1 + timeVariation, 
                                        second: 0, of: date) {
            let height = Double.random(in: patterns.highTideHeight.0...patterns.highTideHeight.1) + heightVariation
            tides.append(TideData(time: highTime1, height: height, type: .high))
        }
        
        // Afternoon low tide
        if let lowTime2 = calendar.date(bySettingHour: patterns.secondaryLowTime.0, 
                                       minute: patterns.secondaryLowTime.1 + timeVariation, 
                                       second: 0, of: date) {
            let height = Double.random(in: patterns.lowTideHeight.0...patterns.lowTideHeight.1) + heightVariation
            tides.append(TideData(time: lowTime2, height: max(0, height), type: .low))
        }
        
        // Evening high tide
        if let highTime2 = calendar.date(bySettingHour: patterns.secondaryHighTime.0, 
                                        minute: patterns.secondaryHighTime.1 + timeVariation, 
                                        second: 0, of: date) {
            let height = Double.random(in: patterns.highTideHeight.0...patterns.highTideHeight.1) + heightVariation
            tides.append(TideData(time: highTime2, height: height, type: .high))
        }
        
        return tides
    }
    
    // Get available years for a station (useful for future extensibility)
    static func getAvailableYears(for station: SupportedStation) -> [Int] {
        // For now return current year and next year
        let currentYear = Calendar.current.component(.year, from: Date())
        return [currentYear, currentYear + 1]
    }
}

// Helper struct for tide pattern information
private struct TidePatternInfo {
    let highTideHeight: (Double, Double) // min, max
    let lowTideHeight: (Double, Double)  // min, max
    let primaryHighTime: (Int, Int)      // hour, minute
    let primaryLowTime: (Int, Int)       // hour, minute
    let secondaryHighTime: (Int, Int)    // hour, minute
    let secondaryLowTime: (Int, Int)     // hour, minute
}
