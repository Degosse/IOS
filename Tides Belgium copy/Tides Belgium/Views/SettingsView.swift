//
//  SettingsView.swift
//  Tides Belgium
//
//  Created by Nicolai Gosselin on 01/07/2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDataStatus = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(LocalizationManager.AppLanguage.allCases) { language in
                        LanguageRowView(
                            language: language,
                            isSelected: localizationManager.currentLanguage == language,
                            onSelect: {
                                localizationManager.changeLanguage(to: language)
                            }
                        )
                    }
                } header: {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        Text(localizationManager.localizedString(for: "language"))
                            .textCase(.none)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                } footer: {
                    Text("Select your preferred language. The app will refresh when you return to the main screen.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: { showingDataStatus = true }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Official Tide Data")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Text("Belgian Government Source")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(.blue)
                        Text("Data Source")
                            .textCase(.none)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                } footer: {
                    Text("View information about official tide data from the Belgian Maritime Service (Agentschap MDK)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tides Belgium")
                            .font(.headline)
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Built with ❤️ for the Belgian coast")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About")
                        .textCase(.none)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .navigationTitle(localizationManager.localizedString(for: "settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(for: "done")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDataStatus) {
                NavigationView {
                    TideDataStatusView()
                        .navigationTitle("Data Status")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingDataStatus = false
                                }
                            }
                        }
                }
            }
        }
    }
}

struct LanguageRowView: View {
    let language: LocalizationManager.AppLanguage
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                onSelect()
            }
        }) {
            HStack {
                Text(language.flagEmoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(language.rawValue.uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    HStack(spacing: 4) {
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.body)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? .blue.opacity(0.1) : .clear)
                    .stroke(isSelected ? .blue.opacity(0.3) : .clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView(localizationManager: LocalizationManager())
}
