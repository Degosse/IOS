# Tides Belgium

A beautiful iOS app for tracking tide times and heights across Belgian coastal locations.

## Features

### 🌊 Comprehensive Tide Information
- Real-time tide heights and predictions
- High and low tide times
- Interactive tide charts with current position indicator
- 24-hour tide view with smooth curves

### 📍 Location-Based Services
- Automatic location detection
- Nearest tide station suggestions
- Manual location selection with search
- Saved location preferences

### 🇧🇪 Belgian Coastal Coverage
- Oostende
- Zeebrugge
- Nieuwpoort
- Antwerpen
- Plus nearby stations (Vlissingen, Calais)

### 📱 Modern iOS Design
- SwiftUI interface following Apple Design Guidelines
- Beautiful charts and visualizations
- Dark/Light mode support
- Smooth animations and transitions
- Launch screen with app branding

### 💾 Smart Data Management
- Location preferences remembered between app launches
- Automatic data refresh every 15 minutes
- Offline-friendly with cached data
- Pull-to-refresh support

## Technical Implementation

### Architecture
- **SwiftUI** for modern iOS UI
- **Combine** for reactive programming
- **CoreLocation** for GPS functionality
- **UserDefaults** for persistent preferences
- **MVVM** architecture pattern

### Data Sources
- Synthetic tide data for demonstration
- Ready for integration with real APIs like:
  - WorldTides API
  - Admiralty Maritime Data Solutions
  - Belgian Hydrographic Service

### Privacy & Permissions
- Location permission with clear usage description
- Optional location services (app works without GPS)
- No personal data collection

## Project Structure

```
Tides Belgium/
├── Models/
│   └── TideData.swift           # Data structures
├── Services/
│   ├── TideService.swift        # Tide data management
│   ├── LocationManager.swift    # GPS & location services
│   └── UserPreferences.swift    # Settings persistence
├── Views/
│   ├── ContentView.swift        # Main app interface
│   ├── TideChartView.swift      # Interactive tide charts
│   ├── TideInfoView.swift       # Tide information display
│   ├── LocationSelectionView.swift # Location picker
│   └── LaunchScreenView.swift   # App launch screen
├── Assets.xcassets/             # App icons & images
└── Info.plist                   # App configuration
```

## Building & Running

1. Open `Tides Belgium.xcodeproj` in Xcode 15.0+
2. Select your target device/simulator
3. Build and run (⌘+R)

### Requirements
- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Future Enhancements

- [ ] Real tide API integration
- [ ] Weather information overlay
- [ ] Tide alerts and notifications
- [ ] Apple Watch companion app
- [ ] Widget support for iOS home screen
- [ ] Siri shortcuts integration
- [ ] Fishing time recommendations
- [ ] Historical tide data charts

## License

This project is open source. Feel free to use and modify for your own projects.

---

Built with ❤️ for the Belgian coastal community
