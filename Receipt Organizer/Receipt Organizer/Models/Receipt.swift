//
//  Receipt.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import Foundation
import SwiftData
import UIKit

@Model
class Receipt {
    var id: UUID
    var date: Date
    var restaurantName: String
    var totalPrice: Double
    var imageData: Data?
    var createdAt: Date
    
    init(date: Date = Date(), restaurantName: String = "", totalPrice: Double = 0.0, imageData: Data? = nil) {
        self.id = UUID()
        self.date = date
        self.restaurantName = restaurantName
        self.totalPrice = totalPrice
        self.imageData = imageData
        self.createdAt = Date()
    }
    
    var image: UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }
    
    func setImage(_ image: UIImage?) {
        self.imageData = image?.jpegData(compressionQuality: 0.8)
    }
}
