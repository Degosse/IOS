import SwiftUI

struct ReceiptDetailView: View {
    var receipt: ExpenseReceipt
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Receipt details header
                VStack(alignment: .leading, spacing: 8) {
                    Text(receipt.restaurantName)
                        .font(.largeTitle)
                        .bold()
                    
                    HStack {
                        Text(receipt.date, style: .date)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(String(format: "€%.2f", receipt.totalPrice))
                            .font(.title2)
                            .bold()
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Display saved image if available
                if let data = receipt.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 5)
                        .padding()
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No image saved for this receipt")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                }
            }
        }
        .navigationTitle("Receipt Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}
