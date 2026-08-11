import Foundation
import SwiftData

@Model
class ExpenseReceipt {
    var id: UUID = UUID()
    var date: Date = Date.now
    var restaurantName: String = ""
    var totalPrice: Double = 0.0
    @Attribute(.externalStorage) var imageData: Data?
    var modifiedAt: Date = Date.now

    init(id: UUID = UUID(), date: Date, restaurantName: String, totalPrice: Double, imageData: Data? = nil, modifiedAt: Date = Date.now) {
        self.id = id
        self.date = date
        self.restaurantName = restaurantName
        self.totalPrice = totalPrice
        self.imageData = imageData
        self.modifiedAt = modifiedAt
    }
}
