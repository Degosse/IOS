//
//  GeminiResponse.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import Foundation

struct GeminiResponse: Codable {
    let candidates: [Candidate]
}

struct Candidate: Codable {
    let content: Content
}

struct Content: Codable {
    let parts: [Part]
}

struct Part: Codable {
    let text: String
}

struct ReceiptData: Codable {
    let date: String
    let restaurantName: String
    let totalPrice: Double
}

struct GeminiRequest: Codable {
    let contents: [RequestContent]
}

struct RequestContent: Codable {
    let parts: [RequestPart]
}

struct RequestPart: Codable {
    let text: String?
    let inlineData: InlineData?
    
    enum CodingKeys: String, CodingKey {
        case text
        case inlineData = "inline_data"
    }
}

struct InlineData: Codable {
    let mimeType: String
    let data: String
    
    enum CodingKeys: String, CodingKey {
        case mimeType = "mime_type"
        case data
    }
}
