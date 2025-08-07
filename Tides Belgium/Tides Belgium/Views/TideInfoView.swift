//
//  TideInfoView.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 01/07/2025.
//

import SwiftUI

struct TideInfoView: View {
    let tideData: [TideData]
    let currentHeight: Double
    @Environment(\.localizationManager) private var localizationManager
    
    private var nextTide: TideData? {
        let now = Date()
        return tideData
            .filter { $0.time > now && $0.type != .current }
            .sorted { $0.time < $1.time }
            .first
    }
    
    private var displayTides: [TideData] {
        return tideData.filter { tide in
            tide.type != .current
        }.sorted { $0.time < $1.time }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Simplified tide table - just showing the basic tide data
            VStack(alignment: .leading, spacing: 10) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                    ForEach(displayTides) { tide in
                        TideItemView(tide: tide)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
    }
    
    private func timeUntil(_ date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        
        if interval < 0 {
            return L("past", localizationManager)
        }
        
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        
        if hours > 0 {
            let timeString = "\(hours)\(L("hours_short", localizationManager)) \(minutes)\(L("minutes_short", localizationManager))"
            return String(format: L("in_time", localizationManager), timeString)
        } else {
            let timeString = "\(minutes)\(L("minutes_short", localizationManager))"
            return String(format: L("in_time", localizationManager), timeString)
        }
    }
}

struct TideItemView: View {
    let tide: TideData
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Color-coded circle indicator
                Circle()
                    .fill(tide.type == .high ? .red : .blue)
                    .frame(width: 12, height: 12)
                
                Text(L(tide.type.rawValue, localizationManager))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tide.time, style: .time)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(tide.height, specifier: "%.2f") \(L("meters", localizationManager))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
