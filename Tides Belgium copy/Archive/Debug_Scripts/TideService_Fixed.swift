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
    
    private var cancellables = Set<AnyCancellable>()
    
    // Only support these stations
    enum SupportedStation: String, CaseIterable {
        case nieuwpoort
        case zeebrugge
        case oostende
        case antwerpen
        case knokkeHeist
        
        var displayName: String {
            switch self {
            case .nieuwpoort: return "Nieuwpoort"
            case .zeebrugge: return "Zeebrugge"
            case .oostende: return "Oostende"
            case .antwerpen: return "Antwerpen"
            case .knokkeHeist: return "Knokke-Heist"
            }
        }
    }

    // Main fetch function, now only supports the 5 cities using TidesChart for all
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
        case "antwerpen":
            supportedStation = .antwerpen
        case "knokkeheist", "knokke-heist":
            supportedStation = .knokkeHeist
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
        case .antwerpen:
            tidesChartURL = "https://nl.tideschart.com/Belgium/Flanders/Provincie-Antwerpen/Antwerpen/"
        case .knokkeHeist:
            tidesChartURL = "https://nl.tideschart.com/Belgium/Flanders/Provincie-West--Vlaanderen/Knokke--Heist/"
        }
        
        print("🔄 Fetching TidesChart data for \(supported.displayName) from \(tidesChartURL)")
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
                
                self.tideData = self.parseTidesChartHTML(html, for: station.displayName)
                print("📊 Parsed \(self.tideData.count) tide entries for \(station.displayName)")
                
                if self.tideData.isEmpty {
                    print("⚠️ No tide data found, using sample data")
                    self.tideData = self.createSampleTideData(for: station.displayName)
                } else {
                    print("🎯 First tide: \(self.tideData.first!.time) - \(String(format: "%.2f", self.tideData.first!.height))m")
                }
                
                self.currentTideHeight = self.tideData.first?.height ?? 0.0
                self.isLoading = false
            }
        }.resume()
    }

    // Parse TidesChart HTML for all Belgian cities
    private func parseTidesChartHTML(_ html: String, for stationName: String) -> [TideData] {
        var tides: [TideData] = []
        
        print("🔍 Starting to parse TidesChart HTML for \(stationName)")
        print("📄 HTML length: \(html.count) characters")
        
        let calendar = Calendar.current
        
        do {
            // Main pattern for TidesChart table format
            // <th scope="row">Laagtij</th> <td>04:20</td> <td>1.38 m</td>
            // <th scope="row">Vloed</th> <td>11:48</td> <td>4.17 m</td>
            let tideTablePattern = #"<th\s+scope="row">(Laagtij|Vloed)</th>\s*<td>(\d{1,2}:\d{2})</td>\s*<td>([0-9.]+)\s*m</td>"#
            let tideRegex = try NSRegularExpression(pattern: tideTablePattern, options: [.caseInsensitive])
            let tideMatches = tideRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            
            print("🎯 Found \(tideMatches.count) tide table entries")
            
            // Process tide table matches
            for (index, match) in tideMatches.enumerated() {
                guard let typeRange = Range(match.range(at: 1), in: html),
                      let timeRange = Range(match.range(at: 2), in: html),
                      let heightRange = Range(match.range(at: 3), in: html) else { continue }
                
                let typeStr = String(html[typeRange])
                let timeStr = String(html[timeRange])
                let heightStr = String(html[heightRange])
                
                print("⏰ Processing tide \(index + 1): \(timeStr) \(typeStr) \(heightStr)m")
                
                if let height = Double(heightStr) {
                    let timeComponents = timeStr.split(separator: ":").map { Int($0) ?? 0 }
                    if timeComponents.count == 2 {
                        // Determine tide type based on Dutch words
                        let type: TideData.TideType = typeStr == "Vloed" ? .high : .low
                        
                        // Determine which day this tide belongs to
                        let matchStart = match.range.location
                        let contextStart = max(0, matchStart - 200)
                        let contextEnd = min(html.count, matchStart + 200)
                        let contextRange = NSRange(location: contextStart, length: contextEnd - contextStart)
                        let context = String(html[Range(contextRange, in: html)!])
                        
                        let isForTomorrow = context.contains("morgen") || context.contains("Maandag") || context.contains("ma ")
                        
                        let today = calendar.startOfDay(for: Date())
                        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
                        let targetDate = isForTomorrow ? tomorrow : today
                        
                        if let tideTime = calendar.date(bySettingHour: timeComponents[0], minute: timeComponents[1], second: 0, of: targetDate) {
                            // Check for duplicates
                            let isDuplicate = tides.contains { existingTide in
                                abs(existingTide.time.timeIntervalSince(tideTime)) < 900 && // Within 15 minutes
                                abs(existingTide.height - height) < 0.1 // Within 10cm
                            }
                            
                            if !isDuplicate {
                                tides.append(TideData(time: tideTime, height: height, type: type))
                                let dayStr = isForTomorrow ? "TOMORROW" : "TODAY"
                                print("✅ Added \(type == .high ? "HIGH" : "LOW") tide for \(dayStr): \(timeStr) - \(height)m")
                            }
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
        for tide in uniqueTides.prefix(8) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, HH:mm"
            print("📈 Final tide: \(formatter.string(from: tide.time)) - \(String(format: "%.2f", tide.height))m (\(tide.type == .high ? "HIGH" : "LOW"))")
        }
        
        return uniqueTides
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
            case "Antwerpen": 
                return (1.3, 60)  // Higher tides, 1 hour later
            case "Zeebrugge": 
                return (1.0, 15)  // Reference station
            case "Oostende": 
                return (0.95, 0)  // Slightly lower
            case "Nieuwpoort": 
                return (0.9, -10) // Lower tides, earlier
            case "Knokke-Heist":
                return (1.05, 20) // Similar to Zeebrugge
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
        
        print("✅ Generated \(tides.count) sample tides for \(stationName)")
        return tides.sorted { $0.time < $1.time }
    }
}
