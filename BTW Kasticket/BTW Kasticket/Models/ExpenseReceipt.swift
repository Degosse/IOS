import Foundation
import SwiftData

@Model
class ExpenseReceipt {
    var id: UUID
    var date: Date
    var restaurantName: String
    var totalPrice: Double
    @Attribute(.externalStorage) var imageData: Data?
    
    init(id: UUID = UUID(), date: Date, restaurantName: String, totalPrice: Double, imageData: Data? = nil) {
        self.id = id
        self.date = date
        self.restaurantName = restaurantName
        self.totalPrice = totalPrice
        self.imageData = imageData
    }
}
