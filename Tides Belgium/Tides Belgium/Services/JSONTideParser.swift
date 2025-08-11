//
//  JSONTideParser.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 09/08/2025.
//

import Foundation

// JSON structure for tide data files
struct JSONTideEntry: Codable {
    let date: String
    let time: String
    let height: Double
    let type: String
}

class JSONTideParser {
    
    // Parse tide data from JSON files for a specific station and date range
    static func parseTideData(for station: ExcelTideParser.SupportedStation, startDate: Date, endDate: Date) -> [TideData] {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: startDate)
        
        // Get the JSON file name
        let fileName = "\(station.rawValue)_\(currentYear).json"
        
        // 1) Try bundled resource
        var jsonURL: URL? = Bundle.main.url(
            forResource: fileName.replacingOccurrences(of: ".json", with: ""),
            withExtension: "json"
        )
        
        // 2) If not bundled, try Documents directory (allows side-loading real data without editing Xcode project)
        if jsonURL == nil {
            if let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let candidate = docsDir.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: candidate.path) {
                    jsonURL = candidate
                    print("📄 Using JSON from Documents: \(candidate.path)")
                }
            }
        }
        
        guard let finalJSONURL = jsonURL else {
            print("❌ JSON file not found (bundle or Documents): \(fileName)")
            // Fallback to sample data
            return ExcelTideParser.parseTideData(for: station, startDate: startDate, endDate: endDate)
        }
        
        print("📁 Found JSON file: \(finalJSONURL.path)")
        
        do {
            let jsonData = try Data(contentsOf: finalJSONURL)
            let jsonEntries = try JSONDecoder().decode([JSONTideEntry].self, from: jsonData)
            
            return parseJSONEntries(jsonEntries, startDate: startDate, endDate: endDate, stationName: station.displayName)
            
        } catch {
            print("❌ Error parsing JSON file: \(error)")
            // Fallback to sample data
            return ExcelTideParser.parseTideData(for: station, startDate: startDate, endDate: endDate)
        }
    }
    
    // Parse JSON entries into TideData objects
    private static func parseJSONEntries(_ entries: [JSONTideEntry], startDate: Date, endDate: Date, stationName: String) -> [TideData] {
        var tides: [TideData] = []
    let tz = TimeZone(identifier: "Europe/Brussels") ?? .current
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    dateFormatter.timeZone = tz
        
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm"
    timeFormatter.timeZone = tz
        
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = tz
        
        for entry in entries {
            // Parse date
            guard let date = dateFormatter.date(from: entry.date) else {
                print("❌ Could not parse date: \(entry.date)")
                continue
            }
            
            // Check if date is in range
            if date < startDate || date > endDate {
                continue
            }
            
            // Parse time
            let timeComponents = entry.time.components(separatedBy: ":")
            guard timeComponents.count >= 2,
                  let hour = Int(timeComponents[0]),
                  let minute = Int(timeComponents[1]) else {
                print("❌ Could not parse time: \(entry.time)")
                continue
            }
            
            // Create full datetime
            guard let tideTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) else {
                print("❌ Could not create datetime for \(entry.date) \(entry.time)")
                continue
            }
            
            // Determine tide type
            let tideType: TideData.TideType
            if entry.type.lowercased() == "high" {
                tideType = .high
            } else if entry.type.lowercased() == "low" {
                tideType = .low
            } else {
                // Fallback: determine by height
                tideType = entry.height > 2.0 ? .high : .low
            }
            
            let tideData = TideData(time: tideTime, height: entry.height, type: tideType)
            tides.append(tideData)
        }
        
        let sortedTides = tides.sorted { $0.time < $1.time }
        
        // Log results
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, HH:mm"
    formatter.timeZone = tz
        for tide in sortedTides {
            let dayStr = calendar.isDateInTomorrow(tide.time) ? "TOMORROW" : "TODAY"
            print("📈 Parsed JSON tide (\(dayStr)): \(formatter.string(from: tide.time)) - \(String(format: "%.2f", tide.height))m (\(tide.type == .high ? "HIGH" : "LOW"))")
        }
        
        print("📊 Total JSON tides parsed for \(stationName): \(sortedTides.count)")
        return sortedTides
    }
}
