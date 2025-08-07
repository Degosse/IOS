//
//  GeminiService.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import Foundation
import UIKit

class GeminiService: ObservableObject {
    private let apiKey = "AIzaSyA0KAKmK7ffkuhs35f9XF1ZNqkn-Zp4hVk"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    func analyzeReceipt(image: UIImage) async throws -> ReceiptData {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.imageProcessingFailed
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let prompt = """
        Analyze this receipt image and extract the following information in JSON format:
        {
            "date": "YYYY-MM-DD",
            "restaurantName": "Name of the restaurant/store",
            "totalPrice": 0.00
        }
        
        Please be as accurate as possible. If you cannot find a specific piece of information, use these defaults:
        - date: today's date
        - restaurantName: "Unknown"
        - totalPrice: 0.00
        
        Return ONLY the JSON object, no additional text.
        """
        
        let request = GeminiRequest(contents: [
            RequestContent(parts: [
                RequestPart(text: prompt, inlineData: nil),
                RequestPart(text: nil, inlineData: InlineData(mimeType: "image/jpeg", data: base64Image))
            ])
        ])
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw GeminiError.encodingFailed
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GeminiError.networkError
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let text = geminiResponse.candidates.first?.content.parts.first?.text else {
            throw GeminiError.noResponse
        }
        
        // Clean the response text and parse JSON
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw GeminiError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(ReceiptData.self, from: jsonData)
        } catch {
            throw GeminiError.parsingFailed
        }
    }
}

enum GeminiError: Error, LocalizedError {
    case imageProcessingFailed
    case invalidURL
    case encodingFailed
    case networkError
    case noResponse
    case invalidResponse
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process the image"
        case .invalidURL:
            return "Invalid API URL"
        case .encodingFailed:
            return "Failed to encode the request"
        case .networkError:
            return "Network request failed"
        case .noResponse:
            return "No response from the API"
        case .invalidResponse:
            return "Invalid response format"
        case .parsingFailed:
            return "Failed to parse the response"
        }
    }
}
