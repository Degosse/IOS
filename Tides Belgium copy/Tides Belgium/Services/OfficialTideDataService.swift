//
//  OfficialTideDataService.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 07/08/2025.
//

import Foundation
import Combine

class OfficialTideDataService: ObservableObject {
    @Published var isDownloading: Bool = false
    @Published var downloadProgress: Double = 0.0
    @Published var error: String?
    @Published var lastUpdateCheck: Date?
    
    private let currentYear = Calendar.current.component(.year, from: Date())
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    // Official Belgian government URLs for tide data
    private let baseURL = "https://www.agentschapmdk.be/nl/publicaties#getijgegevens-"
    
    // Store current year's data URLs (these will be updated when new year data becomes available)
    private let tideDataURLs = [
        "excel_lat": "https://www.agentschapmdk.be/nl/bijlage/af1da440-0b80-4523-aa70-72cd510509fe/xlsx-getijtabellen-lat-2025",
        "excel_taw": "https://www.agentschapmdk.be/nl/bijlage/86f58fff-d0f8-436d-8e86-d81c1a9c2c74/xlsx-getijtabellen-taw-2025",
        "pdf_kust": "https://www.agentschapmdk.be/nl/bijlage/3cdea549-aea8-4aeb-906f-27a6177e00c6/getijtafels-kust-2025"
    ]
    
    // Supported cities that appear in the official documents
    enum OfficialStation: String, CaseIterable {
        case nieuwpoort = "nieuwpoort"
        case zeebrugge = "zeebrugge"
        case oostende = "oostende"
        case blankenberge = "blankenberge"
        
        var displayName: String {
            switch self {
            case .nieuwpoort: return "Nieuwpoort"
            case .zeebrugge: return "Zeebrugge"
            case .oostende: return "Oostende"
            case .blankenberge: return "Blankenberge"
            }
        }
        
        // Map to official document naming (might be different from our IDs)
        var officialName: String {
            switch self {
            case .nieuwpoort: return "Nieuwpoort"
            case .zeebrugge: return "Zeebrugge"
            case .oostende: return "Oostende"
            case .blankenberge: return "Blankenberge"
            }
        }
    }
    
    init() {
        // Load last update check from UserDefaults
        if let lastCheck = UserDefaults.standard.object(forKey: "lastTideDataUpdateCheck") as? Date {
            self.lastUpdateCheck = lastCheck
        }
        
        // Check for updates if it's been more than a week
        checkForUpdatesIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /// Check if we need to look for new year's data
    func checkForUpdatesIfNeeded() {
        let calendar = Calendar.current
        let now = Date()
        
        // If we've never checked, or it's been more than a week, check for updates
        if let lastCheck = lastUpdateCheck {
            if calendar.dateInterval(of: .weekOfYear, for: now)?.start != calendar.dateInterval(of: .weekOfYear, for: lastCheck)?.start {
                checkForNewYearData()
            }
        } else {
            checkForNewYearData()
        }
    }
    
    /// Manually trigger a check for new data
    func checkForNewYearData() {
        print("🔍 Checking for new year tide data...")
        
        let nextYear = currentYear + 1
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        // Only check for next year's data if we're in December
        if currentMonth == 12 {
            checkForDataAvailability(year: nextYear)
        }
        
        // Always check if current year data is available and downloaded
        checkForDataAvailability(year: currentYear)
    }
    
    /// Download and parse tide data for a specific station
    func getTideData(for station: OfficialStation) async throws -> [TideData] {
        // First, ensure we have the latest data files
        try await downloadLatestDataIfNeeded()
        
        // Then parse the data for the requested station
        return try parseLocalTideData(for: station)
    }
    
    // MARK: - Private Methods
    
    private func checkForDataAvailability(year: Int) {
        print("🔍 Checking availability for year \(year)")
        
        let urlString = baseURL + String(year)
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.lastUpdateCheck = Date()
                UserDefaults.standard.set(Date(), forKey: "lastTideDataUpdateCheck")
                
                if let data = data,
                   let html = String(data: data, encoding: .utf8),
                   self?.containsTideData(html: html, year: year) == true {
                    print("✅ Found tide data for year \(year)")
                    
                    if year > self?.currentYear ?? 0 {
                        // New year data is available!
                        NotificationCenter.default.post(name: .newYearTideDataAvailable, object: year)
                    }
                } else {
                    print("❌ No tide data found for year \(year)")
                }
            }
        }.resume()
    }
    
    private func containsTideData(html: String, year: Int) -> Bool {
        let yearString = String(year)
        return html.contains("getijgegevens-\(yearString)") ||
               html.contains("getijtafels-\(yearString)") ||
               html.contains("getijtabellen-\(yearString)")
    }
    
    private func downloadLatestDataIfNeeded() async throws {
        let excelFile = documentsDirectory.appendingPathComponent("tide_data_\(currentYear).xlsx")
        
        // Check if we already have current year's data
        if FileManager.default.fileExists(atPath: excelFile.path) {
            // Check if file is less than 30 days old
            let attributes = try FileManager.default.attributesOfItem(atPath: excelFile.path)
            if let modificationDate = attributes[.modificationDate] as? Date {
                let daysSinceUpdate = Calendar.current.dateComponents([.day], from: modificationDate, to: Date()).day ?? 0
                if daysSinceUpdate < 30 {
                    print("📁 Using cached tide data (updated \(daysSinceUpdate) days ago)")
                    return
                }
            }
        }
        
        // Download new data
        try await downloadExcelData()
    }
    
    private func downloadExcelData() async throws {
        print("⬇️ Downloading latest tide data...")
        
        DispatchQueue.main.async {
            self.isDownloading = true
            self.downloadProgress = 0.0
            self.error = nil
        }
        
        guard let excelURL = URL(string: tideDataURLs["excel_lat"] ?? "") else {
            throw TideDataError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: excelURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TideDataError.downloadFailed
        }
        
        // Save to documents directory
        let excelFile = documentsDirectory.appendingPathComponent("tide_data_\(currentYear).xlsx")
        try data.write(to: excelFile)
        
        DispatchQueue.main.async {
            self.isDownloading = false
            self.downloadProgress = 1.0
        }
        
        print("✅ Successfully downloaded tide data to \(excelFile.path)")
    }
    
    private func parseLocalTideData(for station: OfficialStation) throws -> [TideData] {
        print("📊 Parsing tide data for \(station.displayName)")
        
        // For now, create sample data structure
        // TODO: Implement actual Excel parsing using a library like SwiftXLSX
        return createSampleOfficialData(for: station)
    }
    
    private func createSampleOfficialData(for station: OfficialStation) -> [TideData] {
        var tides: [TideData] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Create more realistic Belgian coast tide data with proper timing
        // Belgian coast typically has semidiurnal tides (2 highs, 2 lows per day)
        // High tides occur roughly every 12 hours 25 minutes apart
        
        for day in 0...1 {
            guard let date = calendar.date(byAdding: .day, value: day, to: today) else { continue }
            
            // Base tide times for Belgian coast (adjusted per station)
            let stationTimingData = getStationTiming(for: station)
            
            // Generate 4 tides per day with realistic spacing
            let baseTimes = [
                (hour: 6, minute: 0 + stationTimingData.offset, type: TideData.TideType.high, heightMultiplier: 1.0),
                (hour: 12, minute: 20 + stationTimingData.offset, type: TideData.TideType.low, heightMultiplier: 0.2),
                (hour: 18, minute: 25 + stationTimingData.offset, type: TideData.TideType.high, heightMultiplier: 0.95),
                (hour: 0, minute: 50 + stationTimingData.offset, type: TideData.TideType.low, heightMultiplier: 0.25) // Next day
            ]
            
            for (hour, minute, type, heightMultiplier) in baseTimes {
                var tideDate = date
                if hour == 0 { // Midnight tide belongs to next day
                    tideDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
                }
                
                // Handle minute overflow/underflow
                let totalMinutes = minute
                let finalHour = (hour + totalMinutes / 60) % 24
                let finalMinute = ((totalMinutes % 60) + 60) % 60
                
                guard let tideTime = calendar.date(bySettingHour: finalHour, minute: finalMinute, second: 0, of: tideDate) else { continue }
                
                // Calculate realistic height based on station and tide type
                let baseHeight = type == .high ? stationTimingData.highTideHeight : stationTimingData.lowTideHeight
                let adjustedHeight = baseHeight * heightMultiplier
                
                // Add seasonal and weather variation (±15%)
                let variation = Double.random(in: 0.85...1.15)
                let finalHeight = max(0.1, adjustedHeight * variation)
                
                tides.append(TideData(
                    time: tideTime,
                    height: finalHeight,
                    type: type
                ))
            }
        }
        
        return tides.sorted { $0.time < $1.time }
    }
    
    private func getStationTiming(for station: OfficialStation) -> (offset: Int, highTideHeight: Double, lowTideHeight: Double) {
        // Based on real Belgian coast tide characteristics
        switch station {
        case .zeebrugge:
            return (offset: 0, highTideHeight: 4.8, lowTideHeight: 0.8)      // Reference port
        case .oostende:
            return (offset: -15, highTideHeight: 4.5, lowTideHeight: 0.7)    // 15 min earlier, slightly lower
        case .nieuwpoort:
            return (offset: -25, highTideHeight: 4.3, lowTideHeight: 0.6)    // 25 min earlier, lower tides
        case .blankenberge:
            return (offset: 5, highTideHeight: 4.7, lowTideHeight: 0.8)      // 5 min later, similar to Zeebrugge
        }
    }
}

// MARK: - Custom Errors

enum TideDataError: Error, LocalizedError {
    case invalidURL
    case downloadFailed
    case parsingFailed
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid tide data URL"
        case .downloadFailed:
            return "Failed to download tide data"
        case .parsingFailed:
            return "Failed to parse tide data"
        case .fileNotFound:
            return "Tide data file not found"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let newYearTideDataAvailable = Notification.Name("newYearTideDataAvailable")
}
