//
//  TideTableView.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 01/07/2025.
//

import SwiftUI

struct TideTableView: View {
    let tideData: [TideData]
    let currentHeight: Double
    @Environment(\.localizationManager) private var localizationManager
    
    private var todayTides: [TideData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let filteredTides = tideData.filter { tide in
            tide.time >= today && tide.time < tomorrow && tide.type != .current
        }.sorted { $0.time < $1.time }
        
        // Limit to 4 tides maximum per day to avoid cluttered UI
        return Array(filteredTides.prefix(4))
    }
    
    private var next24HourTides: [TideData] {
        let now = Date()
        let next24Hours = now.addingTimeInterval(24 * 3600)
        
        let filteredTides = tideData.filter { tide in
            tide.time >= now && tide.time <= next24Hours && tide.type != .current
        }.sorted { $0.time < $1.time }
        
        // Limit to 6 tides maximum for 24 hour period to keep UI clean
        return Array(filteredTides.prefix(6))
    }
    
    private var highTides: [TideData] {
        return next24HourTides.filter { $0.type == .high }
    }
    
    private var lowTides: [TideData] {
        return next24HourTides.filter { $0.type == .low }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // High/Low Summary
            tidesSummarySection
        }
        .padding(.vertical, 8)
    }
    
    private var tidesSummarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Image("Icon-App-40x40@2x")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text(L("todays_tide_summary", localizationManager))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // High Tides
                TideSummaryCard(
                    tides: highTides,
                    type: .high,
                    localizationManager: localizationManager
                )
                
                // Low Tides
                TideSummaryCard(
                    tides: lowTides,
                    type: .low,
                    localizationManager: localizationManager
                )
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

struct TideSummaryCard: View {
    let tides: [TideData]
    let type: TideData.TideType
    let localizationManager: LocalizationManager
    
    private var averageHeight: Double {
        guard !tides.isEmpty else { return 0 }
        return tides.map { $0.height }.reduce(0, +) / Double(tides.count)
    }
    
    private var highestTide: TideData? {
        return tides.max { $0.height < $1.height }
    }
    
    private var lowestTide: TideData? {
        return tides.min { $0.height < $1.height }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(type == .high ? "Icon-App-60x60@3x" : "Icon-App-40x40@3x")
                    .foregroundColor(type == .high ? .blue : .red)
                    .font(.title2)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L(type.rawValue, localizationManager))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(tides.count) \(L("today", localizationManager))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(L(type.rawValue, localizationManager)) \(tides.count) \(L("today", localizationManager))")
            
            if tides.isEmpty {
                Text(L("no_data", localizationManager))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    // Average height
                    HStack {
                        Text(L("average", localizationManager))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(averageHeight, specifier: "%.1f")m")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    // Extreme values
                    if let extreme = (type == .high ? highestTide : lowestTide) {
                        HStack {
                            Text(type == .high ? L("highest", localizationManager) : L("lowest", localizationManager))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(extreme.height, specifier: "%.1f")m")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(type == .high ? .blue : .red)
                                Text(extreme.time, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Next occurrence
                    if let nextTide = tides.first(where: { $0.time > Date() }) {
                        Divider()
                        
                        HStack {
                            Text(L("next", localizationManager))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(nextTide.time, style: .time)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text("\(nextTide.height, specifier: "%.1f")m")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(type == .high ? Color.blue.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}
