# Receipt Organizer Pro - iOS App

A powerful AI-powered receipt scanning and organization app built with Expo and React Native.

## Features

- 📱 **Camera Receipt Scanning**: Use your device camera to capture receipts
- 🤖 **AI Analysis**: Google Gemini AI automatically extracts vendor, amount, and date
- 📊 **Smart Categorization**: Automatic categorization of expenses
- 📋 **Receipt Management**: View, edit, and organize all your receipts
- 📈 **Reports & Analytics**: Generate expense reports with PDF export
- 🌐 **Multi-language**: Support for English, Dutch, German, and French
- 🎨 **Modern UI**: Clean, intuitive interface with Expo Router navigation

## Tech Stack

- **React Native** with **Expo SDK 53**
- **Expo Router** for navigation
- **TypeScript** for type safety
- **Zustand** for state management
- **Google Gemini AI** for receipt analysis
- **Expo Camera** for receipt scanning
- **PDF generation** for reports

## Prerequisites

Before running this app, make sure you have:

1. **Node.js** (v18 or later)
2. **Expo CLI** (`npm install -g @expo/cli`)
3. **iOS Simulator** (via Xcode) or physical iOS device
4. **Google Gemini API key** (configured securely via environment variables)

## Quick Start

### 1. Installation

```bash
# Navigate to the project
cd "Receipt Organizer"

# Install dependencies
npm install --legacy-peer-deps
```

### 2. Environment Setup

The API key is already configured, but you can verify the `.env` file contains:

```env
EXPO_PUBLIC_GEMINI_API_KEY=AIzaSyA0KAKmK7ffkuhs35f9XF1ZNqkn-Zp4hVk
```

### 3. Development

```bash
# Start the development server
npm run start

# Run on iOS simulator
npm run start:ios

# Run with tunnel for physical device testing
npm run start:tunnel
```

## Running on iOS

### Option 1: iOS Simulator (Recommended for Development)

```bash
npm run start:ios
```

This will:
1. Start the Expo development server
2. Automatically open iOS Simulator
3. Load the app in the simulator

### Option 2: Physical iOS Device

```bash
npm run start:tunnel
```

Then:
1. Install **Expo Go** from the App Store on your iOS device
2. Scan the QR code displayed in the terminal
3. The app will load on your device

### Option 3: Development Build (For Production Testing)

```bash
# Build a development version
npm run build:dev

# Or build for production
npm run build:ios
```

### Option 4: Native iOS Development with Xcode

If you want to open the project in Xcode:

```bash
# Generate iOS project files
npm run prebuild

# Open in Xcode
open ios/ReceiptOrganizerPro.xcworkspace
```

## Project Structure

```
📁 Receipt Organizer/
├── 📱 app/                    # App screens (Expo Router)
│   ├── (tabs)/               # Tab navigation screens
│   ├── receipt/              # Receipt management screens
│   └── camera.tsx            # Camera scanning screen
├── 🧩 components/            # Reusable UI components
├── 🔧 services/             # API services (Gemini AI)
├── 📊 store/                # Zustand state management
├── 🎨 constants/            # Colors, categories, translations
├── 🔨 utils/               # Utility functions
└── 📄 types/               # TypeScript type definitions
```

## Key Components

### 🤖 AI Receipt Analysis

The app uses Google Gemini AI to automatically extract:
- **Vendor name** from receipt header
- **Total amount** from receipt totals
- **Transaction date** 
- **Smart categorization** based on vendor type

### 📱 Camera Integration

- **Smart cropping** with corner adjustment
- **Image optimization** for better AI analysis
- **PDF support** for scanned documents
- **Gallery integration** for existing images

### 📊 State Management

Using Zustand for:
- Receipt storage with persistence
- Multi-language preferences
- Report generation data

## Security & API Keys

✅ **Your API key is securely configured** using Expo's recommended practices:

1. **Environment variables** for development (`.env` file)
2. **Expo config** for production builds
3. **Runtime access** via `expo-constants`
4. **Git exclusion** (`.env` is gitignored)

## Building for Production

### Development Build
```bash
eas build --profile development --platform ios
```

### Production Build  
```bash
eas build --profile production --platform ios
```

### Submit to App Store
```bash
eas submit --platform ios
```

## Troubleshooting

### Common Issues

1. **Metro bundler cache issues**
   ```bash
   npx expo start --clear
   ```

2. **iOS Simulator not opening**
   ```bash
   npx expo run:ios
   ```

3. **TypeScript errors**
   ```bash
   npm run prebuild:clean
   ```

4. **Dependency conflicts**
   ```bash
   npm install --legacy-peer-deps
   ```

### API Key Issues

If you see "API key not configured" errors:

1. Check `.env` file exists with correct key
2. Restart the development server
3. Clear Metro cache: `npx expo start --clear`

## Development Commands Reference

```bash
# Development
npm run start              # Start development server
npm run start:ios          # Start with iOS simulator
npm run start:tunnel       # Start with tunnel (for device testing)

# Building
npm run prebuild           # Generate native code
npm run build:ios          # Build for iOS
npm run build:dev          # Build development version

# Utilities  
npm run start -- --clear   # Clear Metro cache
```

## Features in Detail

### 📸 Receipt Scanning
- Camera integration with smart framing guides
- Automatic receipt detection and cropping
- Support for both photos and PDFs
- Real-time image optimization

### 🤖 AI Analysis
- Google Gemini AI integration
- Automatic text extraction and parsing
- Smart vendor name recognition
- Amount and date detection
- Category suggestions

### 📊 Organization
- Receipt list with search and filtering  
- Category-based organization
- Date range filtering
- Expense summaries

### 📋 Reports
- PDF expense report generation
- Date range selection
- Category breakdowns
- Export and sharing capabilities

### 🌍 Internationalization
- English, Dutch, German, French support
- Localized currencies and date formats
- Cultural adaptations for different markets

## License

Private project - All rights reserved.

## Support

For issues or questions about this iOS receipt scanner app, please check the troubleshooting section above or review the code documentation.
