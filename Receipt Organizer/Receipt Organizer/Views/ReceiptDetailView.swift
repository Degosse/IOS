//
//  ReceiptDetailView.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import SwiftUI
import SwiftData

struct ReceiptDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let receipt: Receipt
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Receipt image
                if let image = receipt.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.gray.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.1))
                        .frame(height: 200)
                        .overlay {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.gray)
                                Text("No Image Available")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
                
                // Receipt details card
                VStack(spacing: 20) {
                    receiptDetailRow(
                        title: "Restaurant",
                        value: receipt.restaurantName.isEmpty ? "Unknown" : receipt.restaurantName,
                        icon: "building.2"
                    )
                    
                    receiptDetailRow(
                        title: "Date",
                        value: receipt.date.formatted(date: .abbreviated, time: .omitted),
                        icon: "calendar"
                    )
                    
                    receiptDetailRow(
                        title: "Total Amount",
                        value: receipt.totalPrice.formatted(.currency(code: "USD")),
                        icon: "dollarsign.circle"
                    )
                    
                    receiptDetailRow(
                        title: "Added",
                        value: receipt.createdAt.formatted(date: .abbreviated, time: .shortened),
                        icon: "clock"
                    )
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .navigationTitle("Receipt Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
                .fontWeight(.medium)
            }
        }
        .sheet(isPresented: $isEditing) {
            EditReceiptView(receipt: receipt)
        }
    }
    
    private func receiptDetailRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct EditReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var receipt: Receipt
    @State private var editedName: String
    @State private var editedPrice: String
    @State private var editedDate: Date
    
    init(receipt: Receipt) {
        self.receipt = receipt
        self._editedName = State(initialValue: receipt.restaurantName)
        self._editedPrice = State(initialValue: String(format: "%.2f", receipt.totalPrice))
        self._editedDate = State(initialValue: receipt.date)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Restaurant Details") {
                    TextField("Restaurant Name", text: $editedName)
                    
                    TextField("Total Amount", text: $editedPrice)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Date", selection: $editedDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Edit Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var canSave: Bool {
        !editedName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !editedPrice.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(editedPrice) != nil
    }
    
    private func saveChanges() {
        guard let price = Double(editedPrice) else { return }
        
        receipt.restaurantName = editedName.trimmingCharacters(in: .whitespaces)
        receipt.totalPrice = price
        receipt.date = editedDate
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Handle error
            print("Failed to save changes: \(error)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Receipt.self, configurations: config)
    let receipt = Receipt(
        date: Date(),
        restaurantName: "Sample Restaurant",
        totalPrice: 25.99
    )
    container.mainContext.insert(receipt)
    
    return NavigationStack {
        ReceiptDetailView(receipt: receipt)
    }
    .modelContainer(container)
}
