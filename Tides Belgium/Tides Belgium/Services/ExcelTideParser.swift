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
        case blankenberge = "blankenberge"
        case nieuwpoort = "nieuwpoort"
        case oostende = "oostende"
        case zeebrugge = "zeebrugge"
        
        var displayName: String {
            switch self {
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
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Brussels") ?? .current
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
                let type: TideData.TideType = isHigh ? .high : .low
                
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
        case .blankenberge: return 4.3
        case .nieuwpoort: return 4.5
        case .oostende: return 4.4
        case .zeebrugge: return 4.6
        }
    }
    
    // Get typical low tide height for each station
    private static func getStationLowTideHeight(for station: SupportedStation) -> Double {
        switch station {
        case .blankenberge: return 0.6
        case .nieuwpoort: return 0.4
        case .oostende: return 0.5
        case .zeebrugge: return 0.3
        }
    }
}
