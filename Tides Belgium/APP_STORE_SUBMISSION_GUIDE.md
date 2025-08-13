# 📱 App Store Submission Guide - Tides Belgium

## 🎯 Prerequisites Checklist

### ✅ **Apple Developer Account**
- [ ] Apple Developer Program membership ($99/year)
- [ ] Sign in at [developer.apple.com](https://developer.apple.com)
- [ ] Access to App Store Connect

### ✅ **App Configuration**
- [x] **Bundle ID**: `ngc.TidesBE` (currently set)
- [x] **App Icons**: Available in `Assets/icons/`
- [x] **Localization**: 4 languages (EN, NL, FR, DE) ✨
- [x] **Data Disclaimer**: Flemish Government attribution ✨
- [ ] **Privacy Policy** (required for App Store)

## 📋 Step-by-Step Submission Process

### **Phase 1: Xcode Configuration**

#### 1. Update App Information
```bash
# Open project in Xcode
open "Tides Belgium.xcodeproj"
```

**In Xcode, configure:**
- **Target** → **General** → **Identity**
  - Display Name: "Tides Belgium"
  - Bundle Identifier: `ngc.TidesBE` (or change to your preferred domain)
  - Version: `1.0.0`
  - Build: `1`

#### 2. Set App Icons
- **Target** → **General** → **App Icons and Launch Screen**
- Use icons from `Assets/icons/icon-pack/ios/AppIcons/`

#### 3. Configure Deployment
- **Target** → **General** → **Deployment**
  - iOS Deployment Target: `16.0` (recommended)
  - iPhone/iPad: iPhone only (unless you want iPad support)

#### 4. Signing & Capabilities
- **Target** → **Signing & Capabilities**
- **Team**: Select your Apple Developer Team
- **Provisioning Profile**: Automatic (Xcode managed)

### **Phase 2: App Store Connect Setup**

#### 1. Create App Record
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. **Apps** → **+** → **New App**
3. Fill in:
   - **Name**: "Tides Belgium"
   - **Primary Language**: English (or Dutch)
   - **Bundle ID**: `ngc.TidesBE`
   - **SKU**: `TidesBelgium001` (unique identifier)

#### 2. App Information
- **Category**: Weather (primary), Travel (secondary)
- **Content Rights**: No, it does not contain, show, or access third-party content
- **Age Rating**: 4+ (no restricted content)

#### 3. App Store Listing
**Required Screenshots** (you'll need to take these):
- iPhone 6.7": 3-5 screenshots (iPhone 15 Pro Max size: 1290×2796)
- iPhone 6.5": 3-5 screenshots (iPhone XS Max size: 1242×2688)

**App Store Description**:
```
Accurate tide predictions for Belgian coastal stations. Get precise high and low tide times for Nieuwpoort, Oostende, Blankenberge, Zeebrugge, and Antwerpen.

Features:
• Real-time tide charts with current position indicator
• Today and Tomorrow views
• 48-hour continuous chart
• Multi-language support (English, Dutch, French, German)
• Official data from Flemish Government tide tables
• Clean, easy-to-read interface
• No internet connection required after initial download

Perfect for sailors, fishermen, surfers, and coastal enthusiasts who need reliable Belgian tide information.

Data Source: Official tide tables from the Flemish Government (Vlaamse Regering).
```

**Keywords**: `tides, belgium, coast, sailing, fishing, water, sea, maritime, flemish, nautical`

### **Phase 3: Privacy & Legal Requirements**

#### 1. Create Privacy Policy
Create a simple privacy policy (required for App Store):

```
PRIVACY POLICY - Tides Belgium

This app does not collect, store, or transmit any personal information.

Data Usage:
- The app uses pre-loaded tide data from official Flemish Government sources
- No internet connection required after installation  
- No user data is collected or shared
- No analytics or tracking

Contact: [your email address]
Last updated: August 2025
```

**Host this online** (GitHub Pages, personal website, etc.) and add the URL to App Store Connect.

#### 2. App Review Information
- **Contact Information**: Your email and phone
- **Review Notes**: "This app provides tide information for Belgian coastal areas using official government data. No special configuration needed for testing."

### **Phase 4: Build and Upload**

#### 1. Archive for App Store
```bash
# In Xcode:
# 1. Select "Any iOS Device (arm64)" as destination
# 2. Product → Archive
# 3. When archive completes, select "Distribute App"
# 4. Choose "App Store Connect"
# 5. Follow the prompts to upload
```

#### 2. Alternative: Command Line Upload
```bash
# Build for App Store
xcodebuild archive \
  -project "Tides Belgium.xcodeproj" \
  -scheme "Tides Belgium" \
  -archivePath "TidesBelgium.xcarchive" \
  -destination "generic/platform=iOS"

# Export for App Store
xcodebuild -exportArchive \
  -archivePath "TidesBelgium.xcarchive" \
  -exportPath "AppStoreExport" \
  -exportOptionsPlist exportOptions.plist
```

### **Phase 5: Submit for Review**

#### 1. In App Store Connect
1. **App Store** tab → **iOS App** 
2. **App Review Information** → Fill in contact details
3. **Version Release** → Choose "Automatically release this version"
4. **Submit for Review**

#### 2. Review Timeline
- **Initial Review**: 24-48 hours typically
- **Common Issues**: Missing privacy policy, screenshot issues, metadata problems

## 🚀 Quick Actions You Can Do Now

### **Immediate Tasks:**

<function_calls>
<invoke name="run_in_terminal">
<parameter name="command">cd "/Users/nicolaigosselin/Documents/Github/Persoonlijk/IOS/Tides Belgium" && open "Tides Belgium.xcodeproj"
