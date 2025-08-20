//
//  LocationSelectionView.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 01/07/2025.
//

import SwiftUI
import MapKit

struct LocationSelectionView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var userPreferences: UserPreferences
    @Environment(\.dismiss) private var dismiss
    @Environment(\.localizationManager) private var localizationManager
    
    @State private var searchText = ""
    @State private var showingLocationPermissionAlert = false
    @State private var hasRequestedLocation = false
    
    private var filteredStations: [TideStation] {
        if searchText.isEmpty {
            return TideStation.belgianStations
        } else {
            return TideStation.belgianStations.filter { station in
                let localizedName = L(station.id, localizationManager)
                return localizedName.localizedCaseInsensitiveContains(searchText) ||
                       station.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image("Icon-App-29x29@2x")
                        .foregroundColor(.gray)
                    
                    TextField(L("search_stations", localizationManager), text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Use current location button
                Button(action: {
                    if locationManager.authorizationStatus == .denied {
                        showingLocationPermissionAlert = true
                    } else {
                        hasRequestedLocation = true
                        locationManager.requestLocation()
                    }
                }) {
                    HStack {
                        Image("Icon-App-29x29@3x")
                        Text(L("current_location", localizationManager))
                        if let nearestStation = locationManager.nearestStation {
                            Text("(\(L(nearestStation.id, localizationManager)))")
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Divider()
                
                // Station list
                List {
                    ForEach(filteredStations) { station in
                        StationRowView(
                            station: station,
                            isSelected: userPreferences.selectedStation?.id == station.id,
                            distance: distanceToStation(station)
                        ) {
                            userPreferences.selectedStation = station
                            dismiss()
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle(L("select_location", localizationManager))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("cancel", localizationManager)) {
                        dismiss()
                    }
                }
            }
            .alert(L("location_permission_title", localizationManager), isPresented: $showingLocationPermissionAlert) {
                Button(L("settings_button", localizationManager)) {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button(L("cancel", localizationManager), role: .cancel) { }
            } message: {
                Text(L("location_permission_message", localizationManager))
            }
        }
        .onReceive(locationManager.$nearestStation) { nearestStation in
            if let station = nearestStation, hasRequestedLocation {
                userPreferences.selectedStation = station
                dismiss()
            }
        }
    }
    
    private func distanceToStation(_ station: TideStation) -> Double? {
        guard let userLocation = locationManager.location else { return nil }
        let stationLocation = CLLocation(latitude: station.latitude, longitude: station.longitude)
        return userLocation.distance(from: stationLocation) / 1000 // Convert to km
    }
}

struct StationRowView: View {
    let station: TideStation
    let isSelected: Bool
    let distance: Double?
    let onSelect: () -> Void
    @Environment(\.localizationManager) private var localizationManager
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L(station.id, localizationManager))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(station.country)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let distance = distance {
                        Text("\(distance, specifier: "%.1f") \(L("km_away", localizationManager))")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image("Icon-App-40x40@3x")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
