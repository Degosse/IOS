//
//  ReportsView.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var receipts: [Receipt]
    @State private var selectedPeriod: ReportPeriod = .monthly
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedQuarter = 1
    @State private var showingExportOptions = false
    @State private var showingExportError = false
    @State private var exportError: String?
    @State private var isExporting = false
    
    private var availableYears: [Int] {
        let years = Set(receipts.map { Calendar.current.component(.year, from: $0.date) })
        return Array(years).sorted(by: >)
    }
    
    private var filteredReceipts: [Receipt] {
        receipts.filter { receipt in
            let receiptYear = Calendar.current.component(.year, from: receipt.date)
            let receiptMonth = Calendar.current.component(.month, from: receipt.date)
            let receiptQuarter = (receiptMonth - 1) / 3 + 1
            
            switch selectedPeriod {
            case .monthly:
                return receiptYear == selectedYear && receiptMonth == selectedMonth
            case .quarterly:
                return receiptYear == selectedYear && receiptQuarter == selectedQuarter
            case .yearly:
                return receiptYear == selectedYear
            }
        }
    }
    
    private var totalExpenses: Double {
        filteredReceipts.reduce(0) { $0 + $1.totalPrice }
    }
    
    private var expensesByRestaurant: [(String, Double)] {
        Dictionary(grouping: filteredReceipts) { $0.restaurantName }
            .mapValues { receipts in receipts.reduce(0) { $0 + $1.totalPrice } }
            .sorted { $0.value > $1.value }
    }
    
    private var monthlyData: [MonthlyExpense] {
        guard selectedPeriod == .yearly else { return [] }
        
        let yearReceipts = receipts.filter { 
            Calendar.current.component(.year, from: $0.date) == selectedYear 
        }
        
        var monthlyTotals: [Int: Double] = [:]
        
        for receipt in yearReceipts {
            let month = Calendar.current.component(.month, from: receipt.date)
            monthlyTotals[month, default: 0] += receipt.totalPrice
        }
        
        return (1...12).map { month in
            let monthName = DateFormatter().monthSymbols[month - 1]
            return MonthlyExpense(month: monthName, amount: monthlyTotals[month] ?? 0)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Period selector
                    periodSelector
                    
                    // Summary card
                    summaryCard
                    
                    // Chart section
                    if selectedPeriod == .yearly && !monthlyData.isEmpty {
                        monthlyChartSection
                    }
                    
                    // Top expenses by restaurant
                    topExpensesSection
                    
                    // All receipts list
                    receiptsList
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("Reports", comment: "Navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("Close", comment: "Close button")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingExportOptions = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(filteredReceipts.isEmpty)
                }
            }
            .actionSheet(isPresented: $showingExportOptions) {
                ActionSheet(
                    title: Text(NSLocalizedString("Export Options", comment: "Export action sheet title")),
                    buttons: [
                        .default(Text(NSLocalizedString("Export PDF", comment: "Export option"))) {
                            exportPDFReport()
                        },
                        .default(Text(NSLocalizedString("Save Images to Photos", comment: "Export option"))) {
                            saveImagesToPhotos()
                        },
                        .default(Text(NSLocalizedString("Share Images as Files", comment: "Export option"))) {
                            shareImagesAsFiles()
                        },
                        .cancel(Text(NSLocalizedString("Cancel", comment: "Cancel button")))
                    ]
                )
            }
            .alert(NSLocalizedString("Export Error", comment: "Alert title"), isPresented: $showingExportError) {
                Button(NSLocalizedString("OK", comment: "OK button")) { }
            } message: {
                Text(exportError ?? NSLocalizedString("Unknown error occurred", comment: "Generic error"))
            }
        }
    }
    
    private var periodSelector: some View {
        VStack(spacing: 16) {
            Picker("Period", selection: $selectedPeriod) {
                ForEach(ReportPeriod.allCases, id: \.self) { period in
                    Text(period.displayName).tag(period)
                }
            }
            .pickerStyle(.segmented)
            
            HStack {
                // Year picker
                Picker("Year", selection: $selectedYear) {
                    ForEach(availableYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.menu)
                
                Spacer()
                
                // Additional picker based on period
                switch selectedPeriod {
                case .monthly:
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(DateFormatter().monthSymbols[month - 1])
                                .tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                    
                case .quarterly:
                    Picker("Quarter", selection: $selectedQuarter) {
                        ForEach(1...4, id: \.self) { quarter in
                            Text("Q\(quarter)").tag(quarter)
                        }
                    }
                    .pickerStyle(.menu)
                    
                case .yearly:
                    EmptyView()
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Expenses")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(totalExpenses.formatted(.currency(code: "EUR")))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Receipts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(filteredReceipts.count)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            }
            
            if !filteredReceipts.isEmpty {
                let avgExpense = totalExpenses / Double(filteredReceipts.count)
                HStack {
                    Text("Average per receipt:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(avgExpense.formatted(.currency(code: "EUR")))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var monthlyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart(monthlyData, id: \.month) { data in
                BarMark(
                    x: .value("Month", data.month),
                    y: .value("Amount", data.amount)
                )
                .foregroundStyle(.blue.gradient)
            }
            .frame(height: 200)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var topExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Expenses by Restaurant")
                .font(.headline)
                .fontWeight(.semibold)
            
            if expensesByRestaurant.isEmpty {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(expensesByRestaurant.prefix(5).enumerated()), id: \.offset) { index, item in
                    let (name, amount) = item
                    HStack {
                        Text("\(index + 1).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(name.isEmpty ? "Unknown" : name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(amount.formatted(.currency(code: "EUR")))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var receiptsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Receipts (\(filteredReceipts.count))")
                .font(.headline)
                .fontWeight(.semibold)
            
            if filteredReceipts.isEmpty {
                Text("No receipts found for the selected period")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredReceipts.sorted(by: { $0.date > $1.date }), id: \.id) { receipt in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(receipt.restaurantName.isEmpty ? "Unknown" : receipt.restaurantName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(receipt.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(receipt.totalPrice.formatted(.currency(code: "EUR")))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func exportPDFReport() {
        guard !isExporting else { return }
        isExporting = true
        
        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isExporting = false
            }
        }
        
        guard !filteredReceipts.isEmpty else { 
            showingExportError = true
            exportError = NSLocalizedString("No receipts for selected period", comment: "Export error")
            return 
        }
        
        let periodString: String
        switch selectedPeriod {
        case .monthly:
            let monthName = DateFormatter().monthSymbols[selectedMonth - 1]
            periodString = "\(monthName) \(selectedYear)"
        case .quarterly:
            periodString = "Q\(selectedQuarter) \(selectedYear)"
        case .yearly:
            periodString = String(selectedYear)
        }
        
        guard let pdfData = PDFExporter.createReport(
            receipts: filteredReceipts,
            period: periodString,
            totalAmount: totalExpenses
        ) else {
            showingExportError = true
            exportError = NSLocalizedString("Failed to create PDF", comment: "Export error")
            return
        }
        
        // Create a temporary file and share it
        let filename = "ExpenseReport_\(periodString.replacingOccurrences(of: " ", with: "_")).pdf"
        sharePDF(data: pdfData, filename: filename)
    }
    
    private func saveImagesToPhotos() {
        guard !isExporting else { return }
        isExporting = true
        
        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isExporting = false
            }
        }
        
        guard !filteredReceipts.isEmpty else { 
            showingExportError = true
            exportError = NSLocalizedString("No receipts for selected period", comment: "Export error")
            return 
        }
        
        ImageExporter.saveImagesToPhotos(receipts: filteredReceipts) { result in
            switch result {
            case .success(let count):
                // Success feedback could be added here if desired
                print("Successfully saved \(count) images to Photos")
            case .failure(let error):
                showingExportError = true
                exportError = error.localizedDescription
            }
        }
    }
    
    private func shareImagesAsFiles() {
        guard !isExporting else { return }
        isExporting = true
        
        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isExporting = false
            }
        }
        
        guard !filteredReceipts.isEmpty else { 
            showingExportError = true
            exportError = NSLocalizedString("No receipts for selected period", comment: "Export error")
            return 
        }
        
        let periodString: String
        switch selectedPeriod {
        case .monthly:
            let monthName = DateFormatter().monthSymbols[selectedMonth - 1]
            periodString = "\(monthName)_\(selectedYear)"
        case .quarterly:
            periodString = "Q\(selectedQuarter)_\(selectedYear)"
        case .yearly:
            periodString = String(selectedYear)
        }
        
        guard let imageURLs = ImageExporter.prepareImagesForSharing(receipts: filteredReceipts, period: periodString) else {
            showingExportError = true
            exportError = NSLocalizedString("Failed to prepare images for sharing", comment: "Export error")
            return
        }
        
        // Find the topmost view controller to present the share sheet
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = scene.windows.first(where: \.isKeyWindow),
           let rootViewController = window.rootViewController {
            
            var topController = rootViewController
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            ImageExporter.shareImages(imageURLs: imageURLs, from: topController)
        }
    }

    private func sharePDF(data: Data, filename: String) {
        // Use temporary directory for better compatibility
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
            
            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                activityVC.excludedActivityTypes = [.assignToContact, .saveToCameraRoll]
                
                // Add completion handler to clean up temporary file
                activityVC.completionWithItemsHandler = { _, _, _, _ in
                    try? FileManager.default.removeItem(at: tempURL)
                }
                
                // Find the topmost view controller
                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                   let window = scene.windows.first(where: \.isKeyWindow),
                   let rootVC = window.rootViewController {
                    
                    var topVC = rootVC
                    while let presentedVC = topVC.presentedViewController {
                        topVC = presentedVC
                    }
                    
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = topVC.view
                        popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                    
                    topVC.present(activityVC, animated: true)
                } else {
                    // Fallback: clean up if we can't present
                    try? FileManager.default.removeItem(at: tempURL)
                    showingExportError = true
                    exportError = NSLocalizedString("Unable to share document", comment: "Export error")
                }
            }
        } catch {
            print("Error sharing PDF: \(error)")
            showingExportError = true
            exportError = NSLocalizedString("Failed to prepare document for sharing", comment: "Export error")
        }
    }
}

enum ReportPeriod: CaseIterable {
    case monthly, quarterly, yearly
    
    var displayName: String {
        switch self {
        case .monthly: return NSLocalizedString("Monthly", comment: "Report period")
        case .quarterly: return NSLocalizedString("Quarterly", comment: "Report period")
        case .yearly: return NSLocalizedString("Yearly", comment: "Report period")
        }
    }
}

struct MonthlyExpense {
    let month: String
    let amount: Double
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Receipt.self, configurations: config)
    
    // Add sample data
    let sampleReceipts = [
        Receipt(date: Date(), restaurantName: "McDonald's", totalPrice: 12.50),
        Receipt(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, restaurantName: "Starbucks", totalPrice: 8.75),
        Receipt(date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!, restaurantName: "Pizza Hut", totalPrice: 25.99)
    ]
    
    for receipt in sampleReceipts {
        container.mainContext.insert(receipt)
    }
    
    return ReportsView()
        .modelContainer(container)
}
