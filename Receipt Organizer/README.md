# Receipt Organizer - iOS App

A sleek iOS app designed to help you capture, organize, and manage your receipts using AI-powered analysis and automated reporting features.

## Features

### 📸 Smart Receipt Capture
- Take photos of receipts using the built-in camera
- Crop and adjust images to focus on the receipt content
- Automatic image optimization for better AI analysis

### 🤖 AI-Powered Analysis
- Uses Google Gemini AI to automatically extract:
  - Date of purchase
  - Restaurant/store name  
  - Total price


### 📊 Smart Organization
- Automatically stores receipts with extracted data
- Search and filter receipts by name, date, or amount
- Sort by various criteria (date, price, restaurant name)

### 📈 Comprehensive Reporting
- Generate expense reports by month, quarter, or year
- Visual charts showing spending patterns
- Export reports as PDF for accountants
- Export receipt images as archive files

### 🔒 Privacy & Storage
- All data stored locally using SwiftData
- No cloud dependency for personal data
- Receipt images saved securely on device

## Architecture

### Key Technologies
- **SwiftUI** - Modern iOS user interface
- **SwiftData** - Local data persistence
- **Charts** - Data visualization
- **PDFKit** - Report generation
- **UIKit integration** - Camera and image handling

### Design Philosophy
- Follows Apple's Human Interface Guidelines
- Clean, intuitive user experience
- Accessibility-first design approach
- Performance optimized for all iOS devices

## App Structure

```
Receipt Organizer/
├── Models/
│   ├── Receipt.swift              # Core data model
│   └── GeminiResponse.swift       # API response models
├── Views/
│   ├── ReceiptListView.swift      # Main receipt list
│   ├── AddReceiptView.swift       # Add new receipt
│   ├── ReceiptDetailView.swift    # View/edit receipt
│   ├── ReportsView.swift          # Expense reports
│   ├── CameraView.swift          # Camera integration
│   └── ImageCropView.swift       # Image cropping
├── Services/
│   ├── GeminiService.swift       # AI integration
│   ├── PDFExporter.swift         # PDF report generation
│   └── ZipExporter.swift         # Image archive creation
└── App Files/
    ├── ContentView.swift         # Root view
    └── Receipt_OrganizerApp.swift # App entry point
```

## Key Features in Detail

### 1. Receipt Capture Workflow
1. Tap camera button to open camera
2. Take photo of receipt
3. Crop image to focus on receipt content
4. AI automatically analyzes and extracts data
5. Review and edit extracted information
6. Save receipt to local database

### 2. Intelligent Data Extraction
The app sends receipt images to Google Gemini with a carefully crafted prompt:
- Extracts date in YYYY-MM-DD format
- Identifies restaurant/store name
- Finds total amount spent
- Handles edge cases and unclear text

### 3. Advanced Reporting
- **Monthly Reports**: View spending for any month
- **Quarterly Reports**: Q1, Q2, Q3, Q4 breakdowns  
- **Yearly Reports**: Annual spending with monthly charts
- **Export Options**: PDF reports and receipt image archives

### 4. Search & Organization
- Real-time search across receipt data
- Multiple sorting options
- Filter by date ranges
- Category-based organization

## Technical Implementation

### Data Model
```swift
@Model
class Receipt {
    var id: UUID
    var date: Date
    var restaurantName: String
    var totalPrice: Double
    var imageData: Data?
    var createdAt: Date
}
```

### AI Integration
Uses Google Gemini 1.5 Flash model for:
- Fast image analysis
- Accurate text extraction  
- Structured data output
- Cost-effective processing

### Export Capabilities
- **PDF Reports**: Professional formatted expense reports
- **Image Archives**: Compressed receipt image collections
- **Share Integration**: Native iOS sharing for easy distribution

## Building & Running

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Active internet connection for AI analysis

### Setup
1. Open `Receipt Organizer.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the project

### API Configuration
The Google Gemini API key is already configured in the app. For production use, consider:
- Moving API key to secure configuration
- Adding API key validation
- Implementing usage monitoring

## Privacy & Security

### Data Handling
- Receipt images stored locally on device
- No personal data sent to third parties (except AI analysis)
- Users can delete all data at any time
- No analytics or tracking implemented

### Permissions Required
- **Camera**: Required for taking receipt photos
- **Photo Library**: Optional for saving processed images

## Future Enhancements

### Planned Features
- OCR fallback when AI is unavailable
- Receipt categorization (meals, office supplies, etc.)
- Tax calculation and deduction tracking  
- Multi-currency support
- Cloud backup integration
- Expense limit alerts

### Technical Improvements
- Offline OCR capabilities
- Background processing for large image sets
- Advanced image preprocessing
- Machine learning model training
- Enhanced accessibility features

## Usage Tips

### Best Practices
1. **Good Lighting**: Take photos in well-lit conditions
2. **Flat Surface**: Lay receipts flat for better recognition
3. **Clean Crop**: Remove background elements when cropping
4. **Regular Review**: Check AI-extracted data for accuracy
5. **Consistent Dating**: Use receipt date rather than photo date

### Troubleshooting
- **AI Extraction Fails**: Manual entry is always available
- **Image Quality Issues**: Retake photo with better lighting
- **App Performance**: Restart app if processing seems slow
- **Export Problems**: Ensure sufficient storage space

## Contributing

This app demonstrates modern iOS development practices:
- SwiftUI declarative UI
- SwiftData local persistence
- AI service integration  
- Native iOS design patterns
- Accessibility considerations
- Professional code organization

The codebase serves as a reference for building production-quality iOS applications with AI integration and comprehensive data management capabilities.

## License

This project is created as a demonstration of iOS development best practices and AI integration techniques.

---

**Built with ❤️ following Apple's design guidelines and best practices for iOS development.**
