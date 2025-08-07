//
//  ImageEditView.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import SwiftUI

struct ImageEditView: View {
    let receipt: Receipt
    @State private var currentImage: UIImage?
    @State private var rotationAngle: CGFloat = 0
    @State private var showingCropper = false
    @State private var showingResetConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    init(receipt: Receipt) {
        self.receipt = receipt
        self._currentImage = State(initialValue: receipt.image)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Image preview
            if let image = currentImage {
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .rotationEffect(.degrees(rotationAngle))
                        .frame(minWidth: 200, minHeight: 200)
                        .clipped()
                }
                .frame(maxHeight: 400)
                .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Controls
            VStack(spacing: 16) {
                // Orientation controls
                VStack {
                    Text(String(localized: "Orientation"))
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 20) {
                        Button(action: { rotateLeft() }) {
                            Image(systemName: "rotate.left")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        
                        Button(action: { rotateRight() }) {
                            Image(systemName: "rotate.right")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: { showingCropper = true }) {
                        HStack {
                            Image(systemName: "crop")
                                .foregroundStyle(.blue)
                            Text("Crop")
                                .foregroundStyle(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: { showingResetConfirmation = true }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.orange)
                            Text(String(localized: "Reset"))
                                .foregroundStyle(.orange)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            
            Spacer()
            
            // Save button
            Button(action: { saveChanges() }) {
                Text("Save Changes")
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .navigationTitle(String(localized: "Edit Image"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingCropper) {
            if let image = currentImage {
                NavigationView {
                    ImageCropView(
                        image: .constant(image),
                        croppedImage: Binding(
                            get: { nil },
                            set: { newImage in
                                if let newImage = newImage {
                                    currentImage = newImage
                                }
                            }
                        ),
                        isPresented: $showingCropper
                    )
                    .navigationTitle("Crop Image")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .confirmationDialog(
            String(localized: "Reset"),
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Reset"), role: .destructive) {
                resetToOriginal()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will reset the image to its original state. All changes will be lost.")
        }
    }
    
    private func rotateLeft() {
        withAnimation(.easeInOut(duration: 0.3)) {
            rotationAngle -= 90
        }
        
        // Apply rotation to the actual image
        if let image = currentImage {
            currentImage = rotateImage(image, by: -90)
        }
    }
    
    private func rotateRight() {
        withAnimation(.easeInOut(duration: 0.3)) {
            rotationAngle += 90
        }
        
        // Apply rotation to the actual image
        if let image = currentImage {
            currentImage = rotateImage(image, by: 90)
        }
    }
    
    private func rotateImage(_ image: UIImage, by degrees: CGFloat) -> UIImage {
        let radians = degrees * CGFloat.pi / 180
        let rotatedSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            image.draw(in: CGRect(
                x: -image.size.width / 2,
                y: -image.size.height / 2,
                width: image.size.width,
                height: image.size.height
            ))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return rotatedImage ?? image
        }
        return image
    }
    
    private func resetToOriginal() {
        currentImage = receipt.image
        rotationAngle = 0
    }
    
    private func saveChanges() {
        if let image = currentImage {
            receipt.setImage(image)
        }
        dismiss()
    }
}

#Preview {
    NavigationView {
        if let receipt = try? Receipt(date: Date(), restaurantName: "Test Restaurant", totalPrice: 25.50) {
            ImageEditView(receipt: receipt)
        }
    }
}
