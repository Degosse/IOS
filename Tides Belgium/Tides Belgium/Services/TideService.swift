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
    
    // Only support these stations
    enum SupportedStation: String, CaseIterable {
        case nieuwpoort
        case zeebrugge
        case oostende
        case knokkeHeist
        case blankenberge
        case deHaan
        case middelkerke
        case dePanne
        
        var displayName: String {
            switch self {
            case .nieuwpoort: return "Nieuwpoort"
            case .zeebrugge: return "Zeebrugge"
            case .oostende: return "Oostende"
            case .knokkeHeist: return "Knokke-Heist"
            case .blankenberge: return "Blankenberge"
            case .deHaan: return "De Haan"
            case .middelkerke: return "Middelkerke"
            case .dePanne: return "De Panne"
            }
        }
    }

    // Main fetch function, now supports 8 cities using TidesChart for all
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
        case "knokkeheist", "knokke-heist":
            supportedStation = .knokkeHeist
        case "blankenberge":
            supportedStation = .blankenberge
        case "dehaan", "de-haan":
            supportedStation = .deHaan
        case "middelkerke":
            supportedStation = .middelkerke
        case "depanne", "de-panne":
            supportedStation = .dePanne
        default:
            supportedStation = nil
        }
        
        guard let supported = supportedStation else {
            print("❌ Station \(station.id) is not supported")
            self.error = "Unsupported station: \(station.name)"
            self.isLoading = false
            return
        }
        print("✅ Matched to supported station: \(supported.displayName)")
        
        // Use TidesChart for all cities with correct URLs
        let tidesChartURL: String
        switch supported {
        case .nieuwpoort:
            tidesChartURL = "https://nl.tideschart.com/Belgium/Flanders/Provincie-West--Vlaanderen/Nieuwpoort/"
        case .zeebrugge:
            tidesChartURL = "https://nl.tideschart.com/Belgium/Flanders/Provincie-West--Vlaanderen/Zeebrugge/"
        case .oostende:
            tidesChartURL = "https://nl.tideschart.com/Belgium/Flanders/Provincie-West--Vlaanderen/Oostende/"
        case .knokkeHeist:
            tidesChartURL = "https://nl.tideschart.com/Belgium/Flanders/Provincie-West--Vlaanderen/Knokke--Heist/"
        case .blankenberge:
            tidesChartURL = "https://nl.tideschart.com/Belgium/Flanders/Provincie-West--Vlaanderen/Blankenberge/"
        case .deHaan:
            tidesChartURL = "https://nl.tideschart.com/Belgium/Flanders/Provincie-West--Vlaanderen/De-Haan/"
        case .middelkerke:
            tidesChartURL = "https://nl.tideschart.com/Belgium/Flanders/Provincie-West--Vlaanderen/Middelkerke/"
        case .dePanne:
            tidesChartURL = "https://nl.tideschart.com/Belgium/Flanders/Provincie-West--Vlaanderen/De-Panne/"
        }
        
        print("🔄 Fetching TidesChart data for \(supported.displayName) from \(tidesChartURL)")
        
        // Debug: log the exact URL being used
        print("🔗 Exact URL: \(tidesChartURL)")
        
        fetchTidesChartData(for: supported, url: tidesChartURL)
    }

    // Fetch from TidesChart
    private func fetchTidesChartData(for station: SupportedStation, url: String) {
        guard let tidesUrl = URL(string: url) else {
            self.error = "Invalid TidesChart URL"
            self.isLoading = false
            return
        }
        var request = URLRequest(url: tidesUrl)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    return
                }
                guard let data = data, let html = String(data: data, encoding: .utf8) else {
                    self.error = "No data from TidesChart"
                    self.isLoading = false
                    return
                }
                print("✅ Received TidesChart HTML data for \(station.displayName)")
                
                let parsedTides = self.parseTidesChartHTML(html, for: station.displayName)
                print("📊 Parsed \(parsedTides.count) tide entries for \(station.displayName)")
                
                // Only use sample data if parsing completely failed (0 tides found)
                if parsedTides.isEmpty {
                    print("❌ PARSING FAILED: No tide data found, creating sample data as last resort")
                    self.error = "Failed to parse real tide data, showing sample data"
                    self.allTideData = self.createSampleTideData(for: station.displayName)
                } else {
                    print("🎯 SUCCESS: Using real TidesChart data!")
                    print("🎯 First tide: \(parsedTides.first!.time) - \(String(format: "%.2f", parsedTides.first!.height))m")
                    self.error = nil // Clear any previous errors
                    self.allTideData = parsedTides
                }
                
                // Filter to show only the selected date's data
                self.filterTidesForSelectedDate()
                self.isLoading = false
            }
        }.resume()
    }

    // Parse TidesChart HTML for all Belgian cities with simplified table parsing
    private func parseTidesChartHTML(_ html: String, for stationName: String) -> [TideData] {
        var tides: [TideData] = []
        
        print("🔍 Starting to parse TidesChart HTML for \(stationName)")
        print("📄 HTML length: \(html.count) characters")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        do {
            // Look for all tide tables with class 'tide-table'
            let tablePattern = #"<table[^>]*class[^>]*tide-table[^>]*>.*?</table>"#
            let tableRegex = try NSRegularExpression(pattern: tablePattern, options: [.dotMatchesLineSeparators])
            let tableMatches = tableRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            
            print("🔍 Found \(tableMatches.count) tide tables")
            
            for (index, tableMatch) in tableMatches.enumerated() {
                let tableRange = Range(tableMatch.range, in: html)!
                let tableHTML = String(html[tableRange])
                
                // Determine if this table is for today or tomorrow
                var isToday = false
                var isTomorrow = false
                var dayLabel = "UNKNOWN"
                
                if tableHTML.contains("vandaag") {
                    isToday = true
                    dayLabel = "TODAY"
                } else if tableHTML.contains("morgen") {
                    isTomorrow = true
                    dayLabel = "TOMORROW"
                } else {
                    // Try to extract the actual date from the table header
                    let datePattern = #"(\d+)\s+(januari|februari|maart|april|mei|juni|juli|augustus|september|oktober|november|december)\s+(\d{4})"#
                    if let dateRegex = try? NSRegularExpression(pattern: datePattern, options: [.caseInsensitive]) {
                        let dateMatches = dateRegex.matches(in: tableHTML, range: NSRange(tableHTML.startIndex..., in: tableHTML))
                        for dateMatch in dateMatches {
                            if let dayRange = Range(dateMatch.range(at: 1), in: tableHTML),
                               let day = Int(String(tableHTML[dayRange])) {
                                let todayDay = calendar.component(.day, from: today)
                                let tomorrowDay = calendar.component(.day, from: tomorrow)
                                
                                if day == todayDay {
                                    isToday = true
                                    dayLabel = "TODAY"
                                } else if day == tomorrowDay {
                                    isTomorrow = true
                                    dayLabel = "TOMORROW"
                                }
                                break
                            }
                        }
                    }
                }
                
                if isToday || isTomorrow {
                    let targetDate = isToday ? today : tomorrow
                    print("📅 Found \(dayLabel) tide table (\(index + 1))")
                    
                    // Try first parsing method: compact tables with scope="row" - more flexible pattern
                    let tidePattern1 = #"<th\s+scope=[\"']row[\"']>(Vloed|Laagtij)</th>\s*<td>([^<]+?)</td>\s*<td>([^<]+?)</td>"#
                    let tideRegex1 = try NSRegularExpression(pattern: tidePattern1)
                    var tideMatches = tideRegex1.matches(in: tableHTML, range: NSRange(tableHTML.startIndex..., in: tableHTML))
                    
                    print("🔍 Method 1 (scope row): Found \(tideMatches.count) tides for \(dayLabel)")
                    
                    // If first method didn't find enough tides, try second method: weekly table with tide-d/tide-u classes
                    if tideMatches.count < 2 {
                        let tidePattern2 = #"<td class=[\"']tide-(d|u)[\"']>(\d{1,2}:\d{2})<div><i>&#x25B[C2];</i> ([\d,\.-]+) m</div></td>"#
                        let tideRegex2 = try NSRegularExpression(pattern: tidePattern2)
                        let weeklyMatches = tideRegex2.matches(in: tableHTML, range: NSRange(tableHTML.startIndex..., in: tableHTML))
                        
                        print("🔍 Method 2 (tide-d/u): Found \(weeklyMatches.count) tides for \(dayLabel)")
                        
                        if weeklyMatches.count > tideMatches.count {
                            tideMatches = weeklyMatches
                            print("� Using Method 2 results")
                        }
                    }
                    
                    // If still no results, try third method: looking for any time:height patterns
                    if tideMatches.count < 2 {
                        let tidePattern3 = #"(\d{1,2}:\d{2})[^0-9]*?([\d,\.-]+)\s*m"#
                        let tideRegex3 = try NSRegularExpression(pattern: tidePattern3)
                        let simpleMatches = tideRegex3.matches(in: tableHTML, range: NSRange(tableHTML.startIndex..., in: tableHTML))
                        
                        print("🔍 Method 3 (simple): Found \(simpleMatches.count) tides for \(dayLabel)")
                        
                        if simpleMatches.count > tideMatches.count {
                            tideMatches = simpleMatches
                            print("🎯 Using Method 3 results")
                        }
                    }
                    
                    print("🌊 Processing \(tideMatches.count) tides for \(dayLabel):")
                    
                    for tideMatch in tideMatches {
                        var typeStr = ""
                        var timeStr = ""
                        var heightStr = ""
                        
                        // Parse based on which method was used
                        if tideMatch.numberOfRanges >= 4 {
                            // Method 1 or 2: has type indicator
                            if let typeRange = Range(tideMatch.range(at: 1), in: tableHTML),
                               let timeRange = Range(tideMatch.range(at: 2), in: tableHTML),
                               let heightRange = Range(tideMatch.range(at: 3), in: tableHTML) {
                                
                                let rawType = String(tableHTML[typeRange])
                                timeStr = String(tableHTML[timeRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                                heightStr = String(tableHTML[heightRange])
                                    .replacingOccurrences(of: ",", with: ".")
                                    .replacingOccurrences(of: "m", with: "")
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                // Determine type based on raw type or height
                                if rawType == "Vloed" || rawType == "u" {
                                    typeStr = "Vloed"
                                } else if rawType == "Laagtij" || rawType == "d" {
                                    typeStr = "Laagtij"
                                } else {
                                    // Use height to determine type (high tide generally > 0m for Belgian coast)
                                    if let height = Double(heightStr), height > 0.0 {
                                        typeStr = "Vloed"
                                    } else {
                                        typeStr = "Laagtij"
                                    }
                                }
                            }
                        } else if tideMatch.numberOfRanges >= 3 {
                            // Method 3: simple time-height pairs, determine type by height
                            if let timeRange = Range(tideMatch.range(at: 1), in: tableHTML),
                               let heightRange = Range(tideMatch.range(at: 2), in: tableHTML) {
                                
                                timeStr = String(tableHTML[timeRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                                heightStr = String(tableHTML[heightRange])
                                    .replacingOccurrences(of: ",", with: ".")
                                    .replacingOccurrences(of: "m", with: "")
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                // Use height to determine type (high tide generally > 0m for Belgian coast)
                                if let height = Double(heightStr), height > 0.0 {
                                    typeStr = "Vloed"
                                } else {
                                    typeStr = "Laagtij"
                                }
                            }
                        }
                        
                        // Parse time components
                        let timeComponents = timeStr.split(separator: ":").compactMap { Int($0) }
                        guard timeComponents.count == 2,
                              let height = Double(heightStr),
                              !typeStr.isEmpty else { 
                            print("❌ Failed to parse tide: time='\(timeStr)', height='\(heightStr)', type='\(typeStr)'")
                            continue 
                        }
                        
                        let hour = timeComponents[0]
                        let minute = timeComponents[1]
                        let isHigh = typeStr == "Vloed"
                        let type: TideData.TideType = isHigh ? .high : .low
                        
                        print("✅ Parsing tide: \(typeStr) at \(timeStr) = \(heightStr)m -> \(type)")
                        
                        if let tideTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: targetDate) {
                            let newTide = TideData(time: tideTime, height: height, type: type)
                            if !isDuplicateTide(newTide, in: tides) {
                                tides.append(newTide)
                                print("   ✅ Added \(typeStr): \(timeStr) - \(heightStr)m")
                            } else {
                                print("   🔄 Skipped duplicate \(typeStr): \(timeStr) - \(heightStr)m")
                            }
                        } else {
                            print("   ❌ Failed to create date for \(timeStr)")
                        }
                    }
                }
            }
            
        } catch {
            print("❌ Error parsing TidesChart HTML: \(error)")
        }
        
        // Sort by time and remove duplicates
        let sortedTides = tides.sorted { $0.time < $1.time }
        let uniqueTides = removeDuplicateTides(sortedTides)
        
        print("📊 Total unique tides parsed for \(stationName): \(uniqueTides.count)")
        
        // Log the final results for debugging
        for tide in uniqueTides {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, HH:mm"
            let dayStr = calendar.isDateInTomorrow(tide.time) ? "TOMORROW" : "TODAY"
            print("📈 Final tide (\(dayStr)): \(formatter.string(from: tide.time)) - \(String(format: "%.2f", tide.height))m (\(tide.type == .high ? "HIGH" : "LOW"))")
        }
        
        return uniqueTides
    }
    
    // Helper function to check for duplicate tides
    private func isDuplicateTide(_ newTide: TideData, in existingTides: [TideData]) -> Bool {
        let isDup = existingTides.contains { existingTide in
            let timeDiff = abs(existingTide.time.timeIntervalSince(newTide.time))
            let heightDiff = abs(existingTide.height - newTide.height)
            return timeDiff < 900 && heightDiff < 0.1 // Within 15 minutes and 10cm
        }
        
        if isDup {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            print("🔄 Skipping duplicate tide: \(formatter.string(from: newTide.time)) - \(String(format: "%.2f", newTide.height))m")
        }
        
        return isDup
    }
    
    // Remove duplicate tides and filter to realistic daily pattern
    private func removeDuplicateTides(_ tides: [TideData]) -> [TideData] {
        var uniqueTides: [TideData] = []
        let sortedTides = tides.sorted(by: { $0.time < $1.time })
        
        for tide in sortedTides {
            let isDuplicate = uniqueTides.contains { existingTide in
                abs(existingTide.time.timeIntervalSince(tide.time)) < 1800 // 30 minutes
            }
            
            if !isDuplicate {
                uniqueTides.append(tide)
            }
        }
        
        // Group by day and limit to 4 tides maximum per day
        let calendar = Calendar.current
        var dailyTides: [String: [TideData]] = [:]
        
        for tide in uniqueTides {
            let dayKey = calendar.dateInterval(of: .day, for: tide.time)?.start.timeIntervalSince1970 ?? 0
            let dayString = String(dayKey)
            
            if dailyTides[dayString] == nil {
                dailyTides[dayString] = []
            }
            dailyTides[dayString]?.append(tide)
        }
        
        // Keep only the first 4 tides per day
        var filteredTides: [TideData] = []
        for (_, dayTideList) in dailyTides {
            let dayTidesSorted = dayTideList.sorted { $0.time < $1.time }
            let limitedTides = Array(dayTidesSorted.prefix(4))
            filteredTides.append(contentsOf: limitedTides)
        }
        
        let finalTides = filteredTides.sorted { $0.time < $1.time }
        print("Removed \(tides.count - finalTides.count) duplicate/excess tides (from \(tides.count) to \(finalTides.count))")
        return finalTides
    }
    
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
        
        // Log all stored tides for debugging
        for (index, tide) in allTideData.enumerated() {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, HH:mm"
            let dayStr = calendar.isDateInTomorrow(tide.time) ? "TOMORROW" : "TODAY"
            print("📊 Stored tide \(index + 1) (\(dayStr)): \(formatter.string(from: tide.time)) - \(String(format: "%.2f", tide.height))m (\(tide.type == .high ? "HIGH" : "LOW"))")
        }
        
        // Filter to show only tides for the selected date from all stored data
        let filteredTides = allTideData.filter { tide in
            let tideDate = tide.time
            let isInRange = tideDate >= selectedDayStart && tideDate < selectedDayEnd
            if !isInRange {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, HH:mm"
                print("🚫 Excluding tide outside range: \(formatter.string(from: tide.time))")
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
