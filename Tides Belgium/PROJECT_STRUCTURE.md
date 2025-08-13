# Tides Belgium - Project Structure

## 📁 Project Organization

```
Tides Belgium/
├── README.md                           # Main project documentation
├── PROJECT_STRUCTURE.md               # This file - project organization guide
├── 
├── 📱 Tides Belgium/                   # Main iOS app source code
├── 📱 Tides Belgium.xcodeproj/         # Xcode project files
├── 🧪 Tides BelgiumTests/             # Unit tests
├── 🧪 Tides BelgiumUITests/           # UI tests
├── 
├── 📊 Data/                           # Generated JSON tide data
│   ├── 2025/                         # Tide data for 2025
│   └── 2026/                         # Tide data for 2026
├── 
├── 📄 SourceData/                     # Original Excel files from Flemish Government
│   ├── xlsx-getijtabellen-taw-2025/  # 2025 Excel tide tables
│   └── xlsx-getijtabellen-taw-2026/  # 2026 Excel tide tables
├── 
├── 🛠️ Scripts/                        # Active data processing scripts
│   ├── extract_year_data.py          # ⭐ Main extraction tool (supports any year)
│   ├── extract_2025_complete.py      # Legacy 2025-specific extractor
│   ├── extract_2026.py               # Legacy 2026-specific extractor
│   └── Archive/                      # Old/experimental scripts
├── 
├── 🎨 Assets/                         # App icons and visual assets
│   └── icons/                        # App icon files
├── 
└── 📚 Archive/                        # Documentation and archived files
    ├── README.md                     # Archive documentation
    ├── Documentation/               # All project documentation
    └── Debug_Scripts/              # Debug utilities
    └── Test_Scripts/               # Testing utilities
```

## 🚀 Quick Start Guide

### Extract New Year Data
```bash
cd Scripts
python3 extract_year_data.py 2027
```

### Build iOS App
```bash
xcodebuild -project "Tides Belgium.xcodeproj" -scheme "Tides Belgium" build
```

## 📂 Folder Descriptions

### Core App (`Tides Belgium/`)
- **Purpose**: Main iOS application source code
- **Contents**: SwiftUI views, models, services, localization
- **Key Files**: 
  - `TideChartView.swift` - Main chart display
  - `TideService.swift` - Data loading and processing
  - `LocalizationManager.swift` - Multi-language support

### Data Processing (`Scripts/`)
- **Purpose**: Tools to convert Excel files to JSON format
- **Main Tool**: `extract_year_data.py` - Universal year data extractor
- **Usage**: Run from Scripts directory to maintain proper relative paths

### Generated Data (`Data/`)
- **Purpose**: Processed tide data in JSON format
- **Structure**: Year-based folders containing station JSON files
- **Files**: `{station}_YYYY.json` for each of 5 Belgian tide stations

### Source Materials (`SourceData/`)
- **Purpose**: Original Excel files from Flemish Government
- **Contents**: Official tide tables in Excel format
- **Note**: These are the authoritative source for all tide data

### Visual Assets (`Assets/`)
- **Purpose**: App icons and graphical resources
- **Contents**: App store icons, device-specific icons

### Documentation (`Archive/`)
- **Purpose**: Project history, documentation, and archived materials
- **Contents**: Development notes, deprecated scripts, debug tools

## 🔧 Development Workflow

1. **Add New Year Data**: 
   - Place Excel files in `SourceData/xlsx-getijtabellen-taw-YYYY/`
   - Run `Scripts/extract_year_data.py YYYY`
   - JSON files appear in `Data/YYYY/`

2. **Update iOS App**:
   - Modify Swift files in `Tides Belgium/`
   - Build and test using Xcode

3. **Debugging**:
   - Check `Archive/Debug_Scripts/` for troubleshooting tools
   - Review `Archive/Documentation/` for issue history

## 🏗️ Clean Architecture Benefits

- ✅ **Separation of Concerns**: Data, code, assets in dedicated folders
- ✅ **Scalability**: Easy to add new years without cluttering
- ✅ **Maintainability**: Clear script organization and documentation
- ✅ **Source Control**: Logical file grouping for Git operations
- ✅ **Collaboration**: Self-documenting structure for team development
