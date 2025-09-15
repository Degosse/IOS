//
//  ReceiptListView.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import SwiftUI
import SwiftData

struct ReceiptListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var receipts: [Receipt]
    @State private var showingAddReceipt = false
    @State private var selectedSortOption = SortOption.dateDescending
    @State private var searchText = ""
    @State private var showingReports = false
    @State private var showingNetworkTest = false
    
    private var filteredAndSortedReceipts: [Receipt] {
        let filtered = receipts.filter { receipt in
            searchText.isEmpty ||
            receipt.restaurantName.localizedCaseInsensitiveContains(searchText) ||
            receipt.totalPrice.formatted(.currency(code: "EUR")).contains(searchText)
        }
        
        return filtered.sorted { receipt1, receipt2 in
            switch selectedSortOption {
            case .dateAscending:
                return receipt1.date < receipt2.date
            case .dateDescending:
                return receipt1.date > receipt2.date
            case .nameAscending:
                return receipt1.restaurantName < receipt2.restaurantName
            case .nameDescending:
                return receipt1.restaurantName > receipt2.restaurantName
            case .priceAscending:
                return receipt1.totalPrice < receipt2.totalPrice
            case .priceDescending:
                return receipt1.totalPrice > receipt2.totalPrice
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if receipts.isEmpty {
                    emptyStateView
                } else {
                    receiptListContent
                }
            }
            .navigationTitle("Receipts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingNetworkTest = true }) {
                        Image(systemName: "network")
                            .foregroundStyle(.orange)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Button(action: { showingReports = true }) {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .foregroundStyle(.blue)
                        }
                        
                        Button(action: { showingAddReceipt = true }) {
                            Image(systemName: "camera.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search receipts...")
            .sheet(isPresented: $showingAddReceipt) {
                AddReceiptView()
            }
            .sheet(isPresented: $showingReports) {
                ReportsView()
            }
            .sheet(isPresented: $showingNetworkTest) {
                NetworkTestView()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "receipt")
                .font(.system(size: 64))
                .foregroundStyle(.gray)
            
            VStack(spacing: 8) {
                Text("No Receipts Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Tap the camera button to add your first receipt")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingAddReceipt = true }) {
                Label("Add Receipt", systemImage: "camera.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .padding()
    }
    
    private var receiptListContent: some View {
        VStack(spacing: 0) {
            // Sort options
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: { selectedSortOption = option }) {
                            Text(option.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    selectedSortOption == option ? .blue : .gray.opacity(0.2),
                                    in: Capsule()
                                )
                                .foregroundStyle(selectedSortOption == option ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            // Receipt list
            List {
                ForEach(filteredAndSortedReceipts, id: \.id) { receipt in
                    NavigationLink(destination: ReceiptDetailView(receipt: receipt)) {
                        ReceiptRowView(receipt: receipt)
                    }
                }
                .onDelete(perform: deleteReceipts)
            }
        }
    }
    
    private func deleteReceipts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredAndSortedReceipts[index])
            }
        }
    }
}

struct ReceiptRowView: View {
    let receipt: Receipt
    
    var body: some View {
        HStack(spacing: 12) {
            // Receipt image thumbnail
            Group {
                if let image = receipt.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "receipt")
                        .font(.title2)
                        .foregroundStyle(.gray)
                }
            }
            .frame(width: 50, height: 50)
            .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .clipped()
            
            // Receipt details
            VStack(alignment: .leading, spacing: 4) {
                Text(receipt.restaurantName.isEmpty ? "Unknown Restaurant" : receipt.restaurantName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(receipt.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(receipt.totalPrice.formatted(.currency(code: "EUR")))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

enum SortOption: CaseIterable {
    case dateDescending, dateAscending
    case nameAscending, nameDescending
    case priceAscending, priceDescending
    
    var displayName: String {
        switch self {
        case .dateDescending: return "Newest First"
        case .dateAscending: return "Oldest First"
        case .nameAscending: return "Name A-Z"
        case .nameDescending: return "Name Z-A"
        case .priceAscending: return "Price Low-High"
        case .priceDescending: return "Price High-Low"
        }
    }
}

#Preview {
    NavigationStack {
        ReceiptListView()
    }
    .modelContainer(for: Receipt.self, inMemory: true)
}
