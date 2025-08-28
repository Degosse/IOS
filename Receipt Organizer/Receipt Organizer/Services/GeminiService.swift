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
    
    // Test method to verify API connection
    func testConnection() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        let testRequest = GeminiRequest(contents: [
            RequestContent(parts: [
                RequestPart(text: "Test connection", inlineData: nil)
            ])
        ])
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 10.0
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(testRequest)
            let (_, response) = try await URLSession.shared.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: Test connection - HTTP Status: \(httpResponse.statusCode)")
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            print("DEBUG: Test connection failed: \(error)")
            throw error
        }
    }
    
    func analyzeReceipt(image: UIImage) async throws -> ReceiptData {
        // Check image processing first
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("DEBUG: Failed to convert image to JPEG data")
            throw GeminiError.imageProcessingFailed
        }
        
        print("DEBUG: Image data size: \(imageData.count) bytes")
        let base64Image = imageData.base64EncodedString()
        print("DEBUG: Base64 image length: \(base64Image.count) characters")
        
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
        urlRequest.timeoutInterval = 30.0 // 30 seconds timeout
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            print("DEBUG: Encoding failed: \(error)")
            throw GeminiError.encodingFailed
        }
        
        print("DEBUG: Making request to: \(url)")
        print("DEBUG: Request headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid response type")
                throw GeminiError.networkError
            }
            
            print("DEBUG: HTTP Status Code: \(httpResponse.statusCode)")
            print("DEBUG: Response Headers: \(httpResponse.allHeaderFields)")
            
            if httpResponse.statusCode != 200 {
                if let responseData = String(data: data, encoding: .utf8) {
                    print("DEBUG: Error Response Body: \(responseData)")
                }
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
                print("DEBUG: JSON parsing failed: \(error)")
                print("DEBUG: Cleaned text: \(cleanedText)")
                throw GeminiError.parsingFailed
            }
        } catch {
            print("DEBUG: URLSession error: \(error)")
            if let urlError = error as? URLError {
                print("DEBUG: URLError code: \(urlError.code)")
                print("DEBUG: URLError description: \(urlError.localizedDescription)")
            }
            throw GeminiError.networkError
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
            return "Afbeelding verwerken mislukt"
        case .invalidURL:
            return "Ongeldige API URL"
        case .encodingFailed:
            return "Verzoek coderen mislukt"
        case .networkError:
            return "Netwerkverzoek mislukt"
        case .noResponse:
            return "Geen respons van de API"
        case .invalidResponse:
            return "Ongeldig respons formaat"
        case .parsingFailed:
            return "Respons verwerken mislukt"
        }
    }
}
