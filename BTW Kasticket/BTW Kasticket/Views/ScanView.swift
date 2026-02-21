import SwiftUI
import SwiftData

struct ScanView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingScanner = false
    @State private var scannedImage: UIImage?
    @State private var isProcessing = false
    @State private var ocrResult: OCRResult?
    @State private var errorMessage: String?
    
    // Extracted state for manual editing before save
    @State private var editedRestaurantName = ""
    @State private var editedTotalPrice: Double = 0.0
    @State private var editedDate = Date()
    @AppStorage("appLanguage") private var language = "nl"
    
    var switchToHistory: () -> Void

    var body: some View {
        NavigationView {
            VStack {
                if isProcessing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Extracting with Mistral AI...".localized(language))
                            .font(.headline)
                    }
                } else if ocrResult != nil {
                    Form {
                        Section(header: Text("Review Scanned Data".localized(language))) {
                            TextField("Restaurant Name".localized(language), text: $editedRestaurantName)
                            
                            DatePicker("Date".localized(language), selection: $editedDate, displayedComponents: .date)
                            
                            HStack {
                                Text("Total (€)".localized(language))
                                Spacer()
                                TextField("Total Price".localized(language), value: $editedTotalPrice, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        
                        if let image = scannedImage {
                            Section(header: Text("Receipt Image".localized(language))) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                        
                        Button {
                            saveReceipt()
                        } label: {
                            Text("Save to History".localized(language))
                                .frame(maxWidth: .infinity)
                                .bold()
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundColor(.appBackground)
                        .listRowInsets(EdgeInsets())
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color.appBackground)
                } else {
                    VStack(spacing: 30) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Scan a new Receipt".localized(language))
                            .font(.title2)
                        
                        Button("Open Camera".localized(language)) {
                            isShowingScanner = true
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundColor(.appBackground)
                        .controlSize(.large)
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
            .navigationTitle("Scan Receipt".localized(language))
            .sheet(isPresented: $isShowingScanner) {
                // Pass completion handler to ScannerView
                ScannerView { images in
                    if let firstImage = images?.first {
                        self.scannedImage = firstImage
                        Task {
                            await processImage(firstImage)
                        }
                    }
                }
            }
        }
    }
    
    private func processImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        ocrResult = nil
        
        do {
            let result = try await MistralOCRService.shared.processReceipt(image: image)
            await MainActor.run {
                self.ocrResult = result
                self.editedRestaurantName = result.restaurantName
                self.editedTotalPrice = result.totalPrice
                self.editedDate = result.date ?? Date()
                self.isProcessing = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to extract data: \(error.localizedDescription)"
                self.isProcessing = false
            }
        }
    }
    
    private func saveReceipt() {
        let imageData = scannedImage?.jpegData(compressionQuality: 0.8)
        
        let newReceipt = ExpenseReceipt(
            date: editedDate,
            restaurantName: editedRestaurantName,
            totalPrice: editedTotalPrice,
            imageData: imageData
        )
        
        modelContext.insert(newReceipt)
        
        // Reset state
        ocrResult = nil
        scannedImage = nil
        
        // Switch tab
        switchToHistory()
    }
}

#Preview {
    ScanView(switchToHistory: {})
        .modelContainer(for: ExpenseReceipt.self, inMemory: true)
}
