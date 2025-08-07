//
//  EditReceiptView.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import SwiftUI
import SwiftData

struct EditReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let receipt: Receipt
    
    @State private var restaurantName: String
    @State private var totalPrice: String
    @State private var selectedDate: Date
    @State private var showingImageEditor = false
    
    init(receipt: Receipt) {
        self.receipt = receipt
        _restaurantName = State(initialValue: receipt.restaurantName)
        _totalPrice = State(initialValue: String(format: "%.2f", receipt.totalPrice))
        _selectedDate = State(initialValue: receipt.date)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Image section
                    imageSection
                    
                    // Form section
                    formSection
                }
                .padding()
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
            .sheet(isPresented: $showingImageEditor) {
                NavigationStack {
                    ImageEditView(receipt: receipt)
                }
            }
        }
    }
    
    private var imageSection: some View {
        VStack(spacing: 16) {
            if let image = receipt.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Button("Edit Image") {
                    showingImageEditor = true
                }
                .buttonStyle(.borderedProminent)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(.gray)
                    
                    Text("No image available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Receipt Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Restaurant Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter restaurant name", text: $restaurantName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Total Amount")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter total amount", text: $totalPrice)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        DatePicker("Receipt Date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                }
            }
        }
    }
    
    private var canSave: Bool {
        !restaurantName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !totalPrice.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(totalPrice) != nil
    }
    
    private func saveChanges() {
        guard let priceValue = Double(totalPrice) else { return }
        
        receipt.restaurantName = restaurantName.trimmingCharacters(in: .whitespaces)
        receipt.totalPrice = priceValue
        receipt.date = selectedDate
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Handle error - could show an alert
            print("Error saving changes: \(error)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Receipt.self, configurations: config)
    
    let receipt = Receipt(date: Date(), restaurantName: "Sample Restaurant", totalPrice: 25.99)
    container.mainContext.insert(receipt)
    
    return EditReceiptView(receipt: receipt)
        .modelContainer(container)
}
