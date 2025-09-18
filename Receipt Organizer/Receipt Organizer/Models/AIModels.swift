//
//  AIModels.swift (previously GeminiResponse.swift)
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import Foundation

// MARK: - Mistral AI Models
struct MistralAPIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [MistralAPIChoice]
    let usage: MistralAPIUsage?
}

struct MistralAPIChoice: Codable {
    let index: Int
    let message: MistralAPIMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }
}

struct MistralAPIMessage: Codable {
    let role: String
    let content: String
}

struct MistralAPIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

struct MistralAPIRequest: Codable {
    let model: String
    let messages: [MistralRequestMessage]
    let maxTokens: Int
    let temperature: Double?
    let topP: Double?
    let randomSeed: Int?
    let stream: Bool?
    
    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
        case topP = "top_p"
        case randomSeed = "random_seed"
        case stream
    }
    
    init(model: String, messages: [MistralRequestMessage], maxTokens: Int, temperature: Double? = nil, topP: Double? = nil, randomSeed: Int? = nil, stream: Bool? = nil) {
        self.model = model
        self.messages = messages
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.topP = topP
        self.randomSeed = randomSeed
        self.stream = stream
    }
}

struct MistralRequestMessage: Codable {
    let role: String
    let content: [MistralMessageContent]
}

struct MistralMessageContent: Codable {
    let type: String
    let text: String?
    let imageUrl: MistralImageURL?
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case imageUrl = "image_url"
    }
    
    init(type: String, text: String? = nil, imageUrl: MistralImageURL? = nil) {
        self.type = type
        self.text = text
        self.imageUrl = imageUrl
    }
}

struct MistralImageURL: Codable {
    let url: String
}



// MARK: - Shared Receipt Data Model
struct ReceiptData: Codable {
    let date: String
    let restaurantName: String
    let totalPrice: Double
}
