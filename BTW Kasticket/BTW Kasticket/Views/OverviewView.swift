import SwiftUI
import SwiftData

struct OverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseReceipt.date, order: .reverse) private var receipts: [ExpenseReceipt]
    
    @State private var selectedPeriod: Period = .quarterly
    @State private var isShowingSignature = false
    @State private var signatureImage: UIImage?
    @State private var isShowingShareSheet = false
    @State private var pdfURL: URL?

    enum Period: String, CaseIterable, Identifiable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
        var id: Self { self }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Filter")) {
                    Picker("Time Period", selection: $selectedPeriod) {
                        ForEach(Period.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Summary")) {
                    HStack {
                        Text("Total Expenses")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "€%.2f", totalExpenses))
                            .font(.title3)
                            .bold()
                    }
                    
                    HStack {
                        Text("Receipts Count")
                        Spacer()
                        Text("\(filteredReceipts.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button {
                        isShowingSignature = true
                    } label: {
                        Text(signatureImage == nil ? "Add Signature" : "Update Signature")
                    }
                    
                    if let sig = signatureImage {
                        Image(uiImage: sig)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                    }
                }
                
                Section {
                    Button {
                        exportPDF()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export for Accountant")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .listRowInsets(EdgeInsets())
            }
            .navigationTitle("Overview")
            .sheet(isPresented: $isShowingSignature) {
                SignatureView(signatureImage: $signatureImage)
            }
            .sheet(isPresented: $isShowingShareSheet) {
                if let url = pdfURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
    
    private func exportPDF() {
        if let url = ExportService.shared.generatePDF(for: selectedPeriod.rawValue, receipts: filteredReceipts, signatureImage: signatureImage) {
            self.pdfURL = url
            self.isShowingShareSheet = true
        }
    }
    
    // Simplistic filtering for MVP purposes.
    // In a real app, we'd calculate exactly the start/end of the current week/month/quarter.
    private var filteredReceipts: [ExpenseReceipt] {
        let calendar = Calendar.current
        let now = Date()
        
        return receipts.filter { receipt in
            let date = receipt.date
            switch selectedPeriod {
            case .weekly:
                return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
            case .monthly:
                return calendar.isDate(date, equalTo: now, toGranularity: .month)
            case .quarterly:
                return calendar.isDate(date, equalTo: now, toGranularity: .quarter)
            case .yearly:
                return calendar.isDate(date, equalTo: now, toGranularity: .year)
            }
        }
    }
    
    private var totalExpenses: Double {
        filteredReceipts.reduce(0) { $0 + $1.totalPrice }
    }
}

#Preview {
    OverviewView()
        .modelContainer(for: ExpenseReceipt.self, inMemory: true)
}
