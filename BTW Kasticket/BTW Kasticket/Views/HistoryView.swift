import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseReceipt.date, order: .reverse) private var receipts: [ExpenseReceipt]

    var body: some View {
        NavigationView {
            List {
                ForEach(receipts) { receipt in
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
                .onDelete(perform: deleteReceipts)
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

    private func deleteReceipts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(receipts[index])
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: ExpenseReceipt.self, inMemory: true)
}
