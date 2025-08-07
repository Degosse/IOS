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
            .navigationTitle("Expense Reports")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
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
                    title: Text("Export Options"),
                    buttons: [
                        .default(Text("Export PDF Report")) {
                            exportPDFReport()
                        },
                        .default(Text("Export Receipt Images")) {
                            exportReceiptImages()
                        },
                        .cancel()
                    ]
                )
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
                    
                    Text(totalExpenses.formatted(.currency(code: "USD")))
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
                    
                    Text(avgExpense.formatted(.currency(code: "USD")))
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
                        
                        Text(amount.formatted(.currency(code: "USD")))
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
                            
                            Text(receipt.totalPrice.formatted(.currency(code: "USD")))
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
        guard !filteredReceipts.isEmpty else { return }
        
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
        
        if let pdfData = PDFExporter.createReport(
            receipts: filteredReceipts,
            period: periodString,
            totalAmount: totalExpenses
        ) {
            // Create a temporary file and share it
            let filename = "ExpenseReport_\(periodString.replacingOccurrences(of: " ", with: "_")).pdf"
            sharePDF(data: pdfData, filename: filename)
        }
    }
    
    private func exportReceiptImages() {
        guard !filteredReceipts.isEmpty else { return }
        
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
        
        if let archiveData = ZipExporter.createReceiptImagesZip(
            receipts: filteredReceipts,
            period: periodString
        ) {
            let filename = "ReceiptImages_\(periodString).archive"
            shareZip(data: archiveData, filename: filename)
        }
    }
    
    private func sharePDF(data: Data, filename: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            activityVC.excludedActivityTypes = [.assignToContact, .saveToCameraRoll]
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = rootVC.view
                    popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("Error sharing PDF: \(error)")
        }
    }
    
    private func shareZip(data: Data, filename: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            activityVC.excludedActivityTypes = [.assignToContact, .saveToCameraRoll]
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = rootVC.view
                    popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            print("Error sharing ZIP: \(error)")
        }
    }
}

enum ReportPeriod: CaseIterable {
    case monthly, quarterly, yearly
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
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
