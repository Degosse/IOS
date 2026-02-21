import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseReceipt.date, order: .reverse) private var receipts: [ExpenseReceipt]

    var body: some View {
        NavigationView {
            List {
                ForEach(groupedReceipts, id: \.0) { group in
                    Section(header: Text(group.0).font(.headline).foregroundColor(.white)) {
                        ForEach(group.1) { receipt in
                            NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                                VStack(alignment: .leading) {
                                    Text(receipt.restaurantName)
                                        .font(.headline)
                                    
                                    HStack {
                                        Text(receipt.date, style: .date)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(String(format: "€%.2f", receipt.totalPrice))
                                            .font(.subheadline)
                                            .bold()
                                    }
                                }
                            }
                        }
                        .onDelete { offsets in
                            deleteReceipts(offsets: offsets, in: group.1)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Receipt History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .overlay {
                if receipts.isEmpty {
                    ContentUnavailableView("No Receipts", systemImage: "doc.text.magnifyingglass", description: Text("Scan a receipt to see it here."))
                }
            }
        }
    }

    // Group receipts by Quarter and Year
    private var groupedReceipts: [(String, [ExpenseReceipt])] {
        let calendar = Calendar.current
        
        let groupedDictionary = Dictionary(grouping: receipts) { receipt in
            let components = calendar.dateComponents([.year, .quarter], from: receipt.date)
            let year = components.year ?? calendar.component(.year, from: Date())
            let quarter = components.quarter ?? 1
            return "Q\(quarter) \(year)"
        }
        
        // Sort the groups by the actual date of the first receipt in that group (newest first)
        return groupedDictionary.sorted {
            ($0.value.first?.date ?? Date()) > ($1.value.first?.date ?? Date())
        }
    }

    private func deleteReceipts(offsets: IndexSet, in group: [ExpenseReceipt]) {
        withAnimation {
            for index in offsets {
                let receiptToDelete = group[index]
                modelContext.delete(receiptToDelete)
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: ExpenseReceipt.self, inMemory: true)
}
