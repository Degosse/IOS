//
//  GeminiService.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import Foundation
import UIKit

class GeminiService: ObservableObject {
    private let apiKey = APIConfiguration.geminiAPIKey
    private let baseURL = APIConfiguration.geminiBaseURL
    
    // Retry configuration for quota errors
    private let maxRetries = APIConfiguration.maxRetries
    private let retryDelay = APIConfiguration.retryDelay
    
    // Simple connectivity test
    func testInternetConnectivity() async -> Bool {
        guard let url = URL(string: "https://www.google.com") else { return false }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: Internet connectivity test - Status: \(httpResponse.statusCode)")
                return httpResponse.statusCode == 200
            }
        } catch {
            print("DEBUG: Internet connectivity test failed: \(error)")
        }
        return false
    }
    
    // Test method to verify API connection
    func testConnection() async throws -> Bool {
        print("DEBUG: Testing Gemini API connection...")
        print("DEBUG: API Key present: \(!apiKey.isEmpty)")
        print("DEBUG: Base URL: \(baseURL)")
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            print("DEBUG: Failed to create URL")
            throw GeminiError.invalidURL
        }
        
        let testRequest = GeminiRequest(contents: [
            RequestContent(parts: [
                RequestPart(text: "Hello, can you respond with 'test successful'?", inlineData: nil)
            ])
        ])
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 15.0
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(testRequest)
            print("DEBUG: Test request created successfully")
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: Test connection - HTTP Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("DEBUG: Test error response: \(responseString)")
                        
                        // Check for specific quota errors
                        if httpResponse.statusCode == 429 && responseString.contains("RATE_LIMIT_EXCEEDED") {
                            throw GeminiError.quotaExceeded
                        } else if httpResponse.statusCode == 403 {
                            throw GeminiError.accessDenied
                        } else if httpResponse.statusCode == 401 {
                            throw GeminiError.invalidAPIKey
                        }
                    }
                    return false
                }
                
                // Try to parse the response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("DEBUG: Test success response: \(responseString)")
                }
                
                return true
            }
            return false
        } catch {
            print("DEBUG: Test connection failed: \(error)")
            if let urlError = error as? URLError {
                print("DEBUG: URLError code: \(urlError.code.rawValue)")
                print("DEBUG: URLError description: \(urlError.localizedDescription)")
                
                switch urlError.code {
                case .notConnectedToInternet:
                    print("DEBUG: No internet connection")
                case .timedOut:
                    print("DEBUG: Request timed out")
                case .cannotFindHost:
                    print("DEBUG: Cannot find host")
                case .networkConnectionLost:
                    print("DEBUG: Network connection lost")
                default:
                    print("DEBUG: Other network error: \(urlError.code)")
                }
            }
            throw error
        }
    }
    
    // Comprehensive diagnostic method
    func runDiagnostics() async {
        print("=== GEMINI API DIAGNOSTICS ===")
        
        // Test 1: Internet connectivity
        print("1. Testing internet connectivity...")
        let hasInternet = await testInternetConnectivity()
        print("   Internet connectivity: \(hasInternet ? "✓" : "✗")")
        
        if !hasInternet {
            print("   ⚠️ No internet connection - this is likely the issue")
            return
        }
        
        // Test 2: API Key format validation
        print("2. Validating API key format...")
        let isValidFormat = APIConfiguration.isValidAPIKey(apiKey)
        let isConfigured = APIConfiguration.isConfigured()
        print("   API key format: \(isValidFormat ? "✓" : "✗")")
        print("   API configured: \(isConfigured ? "✓" : "✗")")
        
        if !isValidFormat {
            print("   ⚠️ API key format appears invalid")
        }
        
        if !isConfigured {
            print("   ⚠️ API key appears to be a placeholder - check APIKeys.plist")
        }
        
        // Test 3: URL construction
        print("3. Testing URL construction...")
        if let _ = URL(string: "\(baseURL)?key=\(apiKey)") {
            print("   URL construction: ✓")
        } else {
            print("   URL construction: ✗")
            return
        }
        
        // Test 4: API connection test
        print("4. Testing Gemini API connection...")
        do {
            let success = try await testConnection()
            print("   Gemini API connection: \(success ? "✓" : "✗")")
        } catch {
            print("   Gemini API connection: ✗")
            
            if let geminiError = error as? GeminiError {
                switch geminiError {
                case .quotaExceeded:
                    print("   Error: Quota exceeded (Rate limit: 0 requests/minute)")
                    print("")
                    print("   💡 SOLUTIONS:")
                    print("   → Option 1: Create new API key at https://aistudio.google.com")
                    print("   → Option 2: Enable billing in Google Cloud Console")
                    print("   → Option 3: Request quota increase for project 939128185854")
                    print("   → Option 4: Wait and try again later")
                    print("")
                case .accessDenied:
                    print("   Error: Access denied - API may not be enabled")
                case .invalidAPIKey:
                    print("   Error: Invalid API key")
                default:
                    print("   Error: \(error.localizedDescription)")
                }
            } else {
                print("   Error: \(error.localizedDescription)")
            }
        }
        
        print("=== END DIAGNOSTICS ===")
    }
    
    // Method to provide quota solutions to the user
    func getQuotaSolutions() -> [String] {
        return [
            "🆕 Create a new API key at https://aistudio.google.com",
            "💳 Enable billing in Google Cloud Console for project 939128185854",
            "📈 Request a quota increase at https://cloud.google.com/docs/quotas/help/request_increase",
            "⏰ Wait and try again later (rate limits may reset)",
            "🌍 Try switching to a different Google Cloud region",
            "🔄 Use a different Google account for a fresh API key"
        ]
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
        urlRequest.timeoutInterval = APIConfiguration.requestTimeout
        
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
                    
                    // Check for specific error types
                    if httpResponse.statusCode == 429 {
                        throw GeminiError.quotaExceeded
                    } else if httpResponse.statusCode == 401 {
                        throw GeminiError.invalidAPIKey
                    } else if httpResponse.statusCode == 403 {
                        throw GeminiError.accessDenied
                    }
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
    case quotaExceeded
    case invalidAPIKey
    case accessDenied
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
        case .quotaExceeded:
            return "API limiet overschreden. Controleer je Google Cloud quota instellingen of probeer later opnieuw."
        case .invalidAPIKey:
            return "Ongeldige API sleutel. Controleer je API configuratie."
        case .accessDenied:
            return "Toegang geweigerd. Controleer of de Gemini API is ingeschakeld voor je project."
        case .noResponse:
            return "Geen respons van de API"
        case .invalidResponse:
            return "Ongeldig respons formaat"
        case .parsingFailed:
            return "Respons verwerken mislukt"
        }
    }
}
