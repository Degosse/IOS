//
//  TideDataStatusView.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 07/08/2025.
//

import SwiftUI

struct TideDataStatusView: View {
    @ObservedObject private var officialDataService = OfficialTideDataService()
    @State private var showingUpdateAlert = false
    @State private var newYearAvailable: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.blue)
                    Text("Official Tide Data")
                        .font(.headline)
                }
                
                Text("Data source: Belgian Government (Agentschap MDK)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Current data status
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Current Year Data")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("2025")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Text("Official tide predictions for Zeebrugge, Nieuwpoort, Oostende, and Blankenberge")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Supported cities
            VStack(alignment: .leading, spacing: 8) {
                Text("Supported Cities")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(["Zeebrugge", "Nieuwpoort", "Oostende", "Blankenberge"], id: \.self) { city in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(city)
                                .font(.caption)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            
            Divider()
            
            // Update information
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Data Updates")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if officialDataService.isDownloading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                if let lastCheck = officialDataService.lastUpdateCheck {
                    Text("Last checked: \(lastCheck, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Never checked for updates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button("Check for Updates") {
                    officialDataService.checkForNewYearData()
                }
                .buttonStyle(.bordered)
                .disabled(officialDataService.isDownloading)
            }
            
            // Info about automatic updates
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Automatic Updates")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Text("The app automatically checks for new yearly tide data each December. When new data becomes available, you'll be notified to download it.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .onAppear {
            // Set up notification listener for new year data
            NotificationCenter.default.addObserver(
                forName: .newYearTideDataAvailable,
                object: nil,
                queue: .main
            ) { notification in
                if let year = notification.object as? Int {
                    newYearAvailable = year
                    showingUpdateAlert = true
                }
            }
        }
        .alert("New Tide Data Available!", isPresented: $showingUpdateAlert) {
            Button("Download Now") {
                // TODO: Implement download of new year data
                officialDataService.checkForNewYearData()
            }
            Button("Later") { }
        } message: {
            if let year = newYearAvailable {
                Text("Official tide data for \(year) is now available from the Belgian government. Would you like to download it?")
            }
        }
    }
}

#Preview {
    NavigationView {
        TideDataStatusView()
            .navigationTitle("Data Status")
            .navigationBarTitleDisplayMode(.inline)
    }
}
