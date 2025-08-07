//
//  ContentView.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 01/07/2025.
//

import SwiftUI

// Extension for date formatting
extension DateFormatter {
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var tideService = TideService()
    @StateObject private var userPreferences = UserPreferences()
    @Environment(\.localizationManager) private var localizationManager
    
    @State private var showingLocationSelection = false
    @State private var showingSettings = false
    @State private var refreshTimer: Timer?
    @State private var refreshKey = UUID() // For forcing view refresh
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Fixed header area at top - always visible
                VStack(spacing: 16) {
                    // Header with location selection
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("app_title", localizationManager))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            if let station = userPreferences.selectedStation {
                                Button(action: {
                                    showingLocationSelection = true
                                }) {
                                    HStack {
                                        Image(systemName: "location.fill")
                                            .foregroundColor(.blue)
                                        Text(L(station.id, localizationManager))
                                            .foregroundColor(.primary)
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                }
                            } else {
                                Button(L("select_location", localizationManager)) {
                                    showingLocationSelection = true
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        // Language selection and Refresh buttons with better touch targets
                        HStack(spacing: 12) { // Spacing for better alignment
                            // Language selection button - more visible and prominent
                            Button(action: { showingSettings = true }) {
                                HStack(spacing: 6) {
                                    Text(localizationManager.currentLanguage.flagEmoji)
                                        .font(.title2)
                                    Text(localizationManager.currentLanguage.rawValue.uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.blue.opacity(0.1))
                                        .stroke(.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .accessibilityLabel("Language: \(localizationManager.currentLanguage.displayName)")
                            .accessibilityHint("Change app language")
                            
                            Button(action: refreshTideData) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 44, height: 44) // Apple's minimum 44pt touch target
                                    .contentShape(Rectangle()) // Improve touch area
                            }
                            .accessibilityLabel("Refresh")
                            .accessibilityHint("Refresh tide data")
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
                .background(Color(.systemBackground))
                
                // Scrollable content area
                ScrollView {
                    VStack(spacing: 16) {
                        // Reduced spacing before content
                        Spacer(minLength: 16)
                        
                        // Loading indicator with better accessibility
                        if tideService.isLoading {
                            VStack(spacing: 16) { // Increased spacing
                                ProgressView()
                                    .scaleEffect(1.5) // Larger for better visibility
                                    .accessibilityLabel("Loading tide data")
                                Text(L("loading", localizationManager))
                                    .font(.subheadline) // Larger text (11pt+ per Apple guidelines)
                                    .foregroundColor(.secondary)
                            }
                            .frame(minHeight: 200) // Consistent height
                            .padding()
                        }
                        // Error state with better contrast and touch targets
                        else if let error = tideService.error {
                            VStack(spacing: 16) { // Increased spacing
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                    .accessibilityHidden(true) // Decorative icon
                                
                                Text(L("error_loading", localizationManager))
                                    .font(.headline)
                                    .foregroundColor(.primary) // Better contrast
                                    .multilineTextAlignment(.center)
                                
                                Text(error)
                                    .font(.subheadline) // Larger text for better readability
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3) // Prevent excessive text
                                
                                Button(L("retry", localizationManager)) {
                                    refreshTideData()
                                }
                                .buttonStyle(.borderedProminent)
                                .frame(minHeight: 44) // Apple's minimum touch target
                                .accessibilityLabel("Retry loading tide data")
                            }
                            .frame(minHeight: 200)
                            .padding(20) // More generous padding
                        }
                        // Main content with improved layout and accessibility
                        else if !tideService.tideData.isEmpty {
                            VStack(spacing: 12) {
                                // Beautiful new 48-hour continuous tide chart
                                TideChartView(
                                    tideData: tideService.allAvailableTideData, // Use all available data for smooth flow
                                    currentHeight: tideService.currentTideHeight,
                                    selectedDate: Date() // Always start with today
                                )
                                
                                // Improved tide table with better spacing
                                TideInfoView(
                                    tideData: tideService.tideData,
                                    currentHeight: tideService.currentTideHeight
                                )
                            }
                            .padding(.horizontal, 12) // Reduced horizontal padding
                        }
                        // Empty state
                        else {
                            VStack(spacing: 16) {
                                Image(systemName: "water.waves")
                                    .font(.system(size: 60))
                                    .foregroundColor(.blue.opacity(0.6))
                                
                                Text(L("welcome_title", localizationManager))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(L("welcome_message", localizationManager))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button(L("choose_location", localizationManager)) {
                                    showingLocationSelection = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .frame(height: 300)
                            .padding()
                        }
                        
                        Spacer(minLength: 20) // Reduced bottom spacing
                    }
                }
                .refreshable {
                    refreshTideData()
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingLocationSelection) {
            LocationSelectionView(
                locationManager: locationManager,
                userPreferences: userPreferences
            )
        }
        .sheet(isPresented: $showingSettings, onDismiss: {
            // Trigger refresh only after settings view is dismissed
            localizationManager.triggerRefreshIfNeeded()
        }) {
            SettingsView(localizationManager: localizationManager)
        }
        .onAppear {
            setupInitialData()
            setupLanguageCallback()
        }
        .onReceive(userPreferences.$selectedStation) { station in
            if let station = station {
                tideService.fetchTideData(for: station)
            }
        }
        .id(refreshKey) // Force view refresh when language changes
    }
    
    private func setupInitialData() {
        // Start location services
        locationManager.requestLocation()
        
        // Load tide data for selected station
        if let station = userPreferences.selectedStation {
            tideService.fetchTideData(for: station)
        }
        
        // Set up refresh timer (every 15 minutes)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { _ in
            refreshTideData()
        }
    }
    
    private func setupLanguageCallback() {
        localizationManager.onLanguageChanged = {
            // Force a complete view refresh when language changes
            refreshKey = UUID()
            // Also refresh tide data to update any cached strings
            refreshTideData()
        }
    }
    
    private func refreshTideData() {
        guard let station = userPreferences.selectedStation else { return }
        tideService.fetchTideData(for: station)
    }
}

#Preview {
    ContentView()
}
