import SwiftUI

struct ReceiptDetailView: View {
    var receipt: ExpenseReceipt
    @AppStorage("appLanguage") private var language = "nl"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Receipt details header
                VStack(alignment: .leading, spacing: 8) {
                    Text(receipt.restaurantName)
                        .font(.largeTitle)
                        .bold()
                    
                    HStack {
                        Text(receipt.date, style: .date)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(String(format: "€%.2f", receipt.totalPrice))
                            .font(.title2)
                            .bold()
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Display saved image if available
                if let data = receipt.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 5)
                        .padding()
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No image saved for this receipt".localized(language))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                }
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Receipt Details".localized(language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    exportSinglePDF()
                } label: {
                    if isGeneratingPDF {
                        ProgressView()
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .disabled(isGeneratingPDF)
            }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .share(let url):
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    // State needed for sharing
    @State private var isGeneratingPDF = false
    @State private var activeSheet: SheetType?
    
    enum SheetType: Identifiable {
        case share(URL)
        var id: String {
            switch self {
            case .share(let url): return url.absoluteString
            }
        }
    }
    
    private func exportSinglePDF() {
        isGeneratingPDF = true
        Task {
            // Tiny delay to let the ProgressView render
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            let generatedURL = await ExportService.shared.generateSingleReceiptPDF(receipt: receipt)
            
            isGeneratingPDF = false
            
            if let url = generatedURL {
                self.activeSheet = .share(url)
            }
        }
    }
}
