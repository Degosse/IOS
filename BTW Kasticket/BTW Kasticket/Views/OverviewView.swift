import SwiftUI
import SwiftData

struct OverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseReceipt.date, order: .reverse) private var receipts: [ExpenseReceipt]
    
    @State private var selectedPeriod: Period = .quarterly
    @State private var signatureImage: UIImage?
    @State private var activeSheet: SheetType?
    @State private var isGeneratingPDF = false
    @State private var isGeneratingZIP = false
    @AppStorage("appLanguage") private var language = "nl"

    enum Period: String, CaseIterable, Identifiable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
        var id: Self { self }
    }
    
    enum SheetType: Identifiable {
        case signature
        case share(URL)
        var id: String {
            switch self {
            case .signature: return "signature"
            case .share(let url): return url.absoluteString
            }
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Settings".localized(language))) {
                    Picker("Language".localized(language), selection: $language) {
                        ForEach(AppLanguage.allCases, id: \.rawValue) { lang in
                            Text(lang.displayName).tag(lang.rawValue)
                        }
                    }
                }
                
                Section(header: Text("Filter".localized(language))) {
                    Picker("Time Period".localized(language), selection: $selectedPeriod) {
                        ForEach(Period.allCases) { period in
                            Text(period.rawValue.localized(language)).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Totaal Overzicht".localized(language))) {
                    HStack {
                        Text("Total Expenses".localized(language))
                            .font(.headline)
                        Spacer()
                        Text(String(format: "€%.2f", totalExpenses))
                            .font(.title3)
                            .bold()
                    }
                }
                
                // Show categorized grouped receipts
                ForEach(groupedReceipts, id: \.0) { group in
                    Section(header: Text(group.0)) {
                        ForEach(group.1) { receipt in
                            HStack {
                                Text(receipt.restaurantName)
                                Spacer()
                                Text(String(format: "€%.2f", receipt.totalPrice))
                            }
                        }
                    }
                }
                
                Section {
                    HStack {
                        Button {
                            activeSheet = .signature
                        } label: {
                            Text(signatureImage == nil ? "Add Signature".localized(language) : "Update Signature".localized(language))
                        }
                        
                        Spacer()
                        
                        if let sig = signatureImage {
                            Image(uiImage: sig)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 40)
                                .background(Color.white)
                                .cornerRadius(4)
                        }
                    }
                }
                
                Section {
                    Button {
                        exportPDF()
                    } label: {
                        HStack {
                            if isGeneratingPDF {
                                ProgressView()
                                    .padding(.trailing, 5)
                            } else {
                                Image(systemName: "doc.text")
                            }
                            Text(isGeneratingPDF ? "Generating PDF...".localized(language) : "Export to Accountant".localized(language))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(.appBackground)
                    .disabled(isGeneratingPDF || isGeneratingZIP)
                    
                    Button {
                        exportZIP()
                    } label: {
                        HStack {
                            if isGeneratingZIP {
                                ProgressView()
                                    .padding(.trailing, 5)
                            } else {
                                Image(systemName: "shippingbox")
                            }
                            Text(isGeneratingZIP ? "Zipping PDFs...".localized(language) : "Export ZIP".localized(language))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.white)
                    .disabled(isGeneratingPDF || isGeneratingZIP)
                }
                .listRowInsets(EdgeInsets())
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Overview".localized(language))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadSignature()
            }
            .onChange(of: signatureImage) { _ in
                saveSignature()
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .signature:
                    SignatureView(signatureImage: $signatureImage)
                case .share(let url):
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private func exportPDF() {
        isGeneratingPDF = true
        Task {
            // Yield the main thread briefly so SwiftUI can render the ProgressView
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // PDF generation bounds explicitly to the @MainActor cleanly using modern concurrency
            let generatedURL = await ExportService.shared.generatePDF(for: selectedPeriod.rawValue.localized(language), receipts: filteredReceipts, signatureImage: signatureImage)
            
            isGeneratingPDF = false
            
            // Show the UI Activity Sheet
            if let url = generatedURL {
                self.activeSheet = .share(url)
            }
        }
    }
    
    private func exportZIP() {
        isGeneratingZIP = true
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            let generatedURL = await ExportService.shared.generateZIP(for: selectedPeriod.rawValue.localized(language), receipts: filteredReceipts)
            
            await MainActor.run {
                isGeneratingZIP = false
                if let url = generatedURL {
                    self.activeSheet = .share(url)
                }
            }
        }
    }
    
    // Group receipts by Month-Year for a nicer overview
    var groupedReceipts: [(String, [ExpenseReceipt])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        let groupedDictionary = Dictionary(grouping: filteredReceipts) { receipt in
            formatter.string(from: receipt.date)
        }
        
        // Sort the groups by the actual date of the first receipt in that group (newest first)
        return groupedDictionary.sorted {
            ($0.value.first?.date ?? Date()) > ($1.value.first?.date ?? Date())
        }
    }
    
    // Simplistic filtering for MVP purposes.
    private var filteredReceipts: [ExpenseReceipt] {
        let calendar = Calendar.current
        let now = Date()
        
        return receipts.filter { receipt in
            let date = receipt.date
            switch selectedPeriod {
            case .weekly:
                return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
            case .monthly:
                // If they select monthly, we actually might want to show everything grouped by month
                // But keeping the current month filter if they just want this month's total
                return calendar.isDate(date, equalTo: now, toGranularity: .month)
            case .quarterly:
                // .quarter is not a valid granularity for isDate(_:equalTo:toGranularity:)
                // We need to manually check if the dates fall in the same quarter and year
                let receiptComponents = calendar.dateComponents([.year, .quarter], from: date)
                let nowComponents = calendar.dateComponents([.year, .quarter], from: now)
                return receiptComponents.year == nowComponents.year && receiptComponents.quarter == nowComponents.quarter
            case .yearly:
                return calendar.isDate(date, equalTo: now, toGranularity: .year)
            }
        }
    }
    
    private var totalExpenses: Double {
        filteredReceipts.reduce(0) { $0 + $1.totalPrice }
    }
    
    // MARK: - Signature Persistence
    private var signatureFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("saved_signature.png")
    }
    
    private func loadSignature() {
        if let data = try? Data(contentsOf: signatureFileURL), let image = UIImage(data: data) {
            signatureImage = image
        }
    }
    
    private func saveSignature() {
        if let image = signatureImage, let data = image.pngData() {
            try? data.write(to: signatureFileURL)
        }
    }
}

#Preview {
    OverviewView()
        .modelContainer(for: ExpenseReceipt.self, inMemory: true)
}
