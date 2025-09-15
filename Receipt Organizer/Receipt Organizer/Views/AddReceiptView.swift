//
//  AddReceiptView.swift
//  Receipt Organizer
//
//  Created by Nicola            //
//  AddReceiptView.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//selin on 07/08/2025.
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var geminiService = GeminiService()
    
    @State private var showingCamera = false
    @State private var showingCropper = false
    @State private var showingCropConfirmation = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var croppedImage: UIImage?
    
    @State private var restaurantName = ""
    @State private var totalPrice = ""
    @State private var selectedDate = Date()
    
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Image section
                    imageSection
                    
                    // Form section
                    if croppedImage != nil || capturedImage != nil {
                        formSection
                    }
                }
                .padding()
            }
            .navigationTitle("Add Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveReceipt()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $capturedImage, isPresented: $showingCamera)
            }
            .sheet(isPresented: $showingCropper) {
                NavigationStack {
                    ImageCropView(
                        image: $capturedImage,
                        croppedImage: $croppedImage,
                        isPresented: $showingCropper
                    )
                }
            }
            .alert("Analyse Fout", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                if let error = analysisError {
                    if error.contains("API limiet overschreden") {
                        Text("\(error)\n\n💡 Oplossing: Ga naar Google Cloud Console en verhoog je Gemini API quotum, of wacht een minuut en probeer opnieuw.")
                    } else if error.contains("Ongeldige API sleutel") {
                        Text("\(error)\n\n💡 Oplossing: Genereer een nieuwe API sleutel in Google AI Studio of Cloud Console.")
                    } else if error.contains("Toegang geweigerd") {
                        Text("\(error)\n\n💡 Oplossing: Schakel de Generative Language API in via Google Cloud Console.")
                    } else if error.contains("Netwerkverzoek mislukt") {
                        Text("\(error)\n\n💡 Tip: Controleer je internetverbinding en probeer het opnieuw.")
                    } else {
                        Text(error)
                    }
                } else {
                    Text("Onbekende fout opgetreden")
                }
            }
            .confirmationDialog("Crop Receipt?", isPresented: $showingCropConfirmation) {
                Button("Crop Image") {
                    showingCropper = true
                }
                Button("Use as is") {
                    if let image = capturedImage {
                        croppedImage = image
                    }
                }
                Button("Cancel", role: .cancel) {
                    capturedImage = nil
                    selectedPhotoItem = nil
                }
            } message: {
                Text("Would you like to crop the image to focus on the receipt?")
            }
            .onChange(of: capturedImage) { oldValue, newValue in
                if newValue != nil {
                    showingCropConfirmation = true
                }
            }
            .onChange(of: croppedImage) { oldValue, newValue in
                if let image = newValue {
                    analyzeImage(image)
                }
            }
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                Task {
                    do {
                        if let item = newValue,
                           let data = try await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                capturedImage = image
                                selectedPhotoItem = nil
                            }
                        }
                    } catch {
                        await MainActor.run {
                            analysisError = "Failed to load photo: \(error.localizedDescription)"
                            showingError = true
                            selectedPhotoItem = nil
                        }
                    }
                }
            }
        }
    }
    
    private var imageSection: some View {
        VStack(spacing: 16) {
            if let image = croppedImage ?? capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
                
                HStack(spacing: 12) {
                    Button("Retake Photo") {
                        capturedImage = nil
                        croppedImage = nil
                        selectedPhotoItem = nil
                        showingCamera = true
                    }
                    .buttonStyle(.bordered)
                    
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Text("Choose Photo")
                    }
                    .buttonStyle(.bordered)
                    
                    if capturedImage != nil && croppedImage == nil {
                        Button("Crop Image") {
                            showingCropper = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    
                    VStack(spacing: 8) {
                        Text("Add Receipt Photo")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Take a photo or choose from your library")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    HStack(spacing: 12) {
                        Button("Take Photo") {
                            showingCamera = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Text("Choose Photo")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 20) {
            if isAnalyzing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing receipt with AI...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            
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
        Double(totalPrice) != nil &&
        (croppedImage != nil || capturedImage != nil)
    }
    
    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        analysisError = nil
        
        Task {
            do {
                let receiptData = try await geminiService.analyzeReceipt(image: image)
                
                await MainActor.run {
                    self.restaurantName = receiptData.restaurantName
                    self.totalPrice = String(format: "%.2f", receiptData.totalPrice)
                    
                    // Parse date
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    if let date = formatter.date(from: receiptData.date) {
                        self.selectedDate = date
                    }
                    
                    self.isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    self.analysisError = error.localizedDescription
                    self.showingError = true
                    self.isAnalyzing = false
                }
            }
        }
    }
    
    private func saveReceipt() {
        guard let priceValue = Double(totalPrice),
              let finalImage = croppedImage ?? capturedImage else { return }
        
        let receipt = Receipt(
            date: selectedDate,
            restaurantName: restaurantName.trimmingCharacters(in: .whitespaces),
            totalPrice: priceValue
        )
        receipt.setImage(finalImage)
        
        modelContext.insert(receipt)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            analysisError = "Failed to save receipt: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    AddReceiptView()
        .modelContainer(for: Receipt.self, inMemory: true)
}
