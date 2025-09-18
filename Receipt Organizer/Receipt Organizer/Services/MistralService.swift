//
//  MistralService.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import Foundation
import UIKit

class MistralService: ObservableObject {
    private let apiKey = APIConfiguration.mistralAPIKey
    private let baseURL = APIConfiguration.mistralBaseURL
    
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
        print("DEBUG: Testing Mistral API connection...")
        print("DEBUG: API Key present: \(!apiKey.isEmpty)")
        print("DEBUG: Base URL: \(baseURL)")
        
        guard let url = URL(string: baseURL) else {
            print("DEBUG: Failed to create URL")
            throw MistralError.invalidURL
        }
        
        let testRequest = MistralAPIRequest(
            model: APIConfiguration.selectedModel.rawValue,
            messages: [
                MistralRequestMessage(role: "user", content: [
                    MistralMessageContent(type: "text", text: "Hello, can you respond with 'test successful'?")
                ])
            ],
            maxTokens: 100
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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
                        if httpResponse.statusCode == 429 {
                            throw MistralError.quotaExceeded
                        } else if httpResponse.statusCode == 403 {
                            throw MistralError.accessDenied
                        } else if httpResponse.statusCode == 401 {
                            throw MistralError.invalidAPIKey
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
        print("=== MISTRAL AI DIAGNOSTICS ===")
        
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
        let isValidFormat = APIConfiguration.isValidMistralKey(apiKey)
        let isConfigured = APIConfiguration.isMistralConfigured()
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
        if let _ = URL(string: baseURL) {
            print("   URL construction: ✓")
        } else {
            print("   URL construction: ✗")
            return
        }
        
        // Test 4: API connection test
        print("4. Testing Mistral API connection...")
        do {
            let success = try await testConnection()
            print("   Mistral API connection: \(success ? "✓" : "✗")")
        } catch {
            print("   Mistral API connection: ✗")
            
            if let mistralError = error as? MistralError {
                switch mistralError {
                case .quotaExceeded:
                    print("   Error: Rate limit exceeded")
                    print("")
                    print("   💡 SOLUTIONS:")
                    print("   → Option 1: Check your Mistral AI account usage")
                    print("   → Option 2: Upgrade your plan at https://console.mistral.ai")
                    print("   → Option 3: Wait and try again later")
                    print("")
                case .accessDenied:
                    print("   Error: Access denied - Check API permissions")
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
            "🔑 Check your API key at https://console.mistral.ai",
            "💳 Upgrade your plan at https://console.mistral.ai/plans",
            "� Monitor usage at https://console.mistral.ai/usage",
            "⏰ Wait and try again later (rate limits may reset)",
            "🔄 Generate a new API key if needed"
        ]
    }
    
    // Simple API test that returns results instead of just console output
    func performSimpleConnectionTest() async -> (success: Bool, message: String, details: String) {
        var resultMessage = ""
        var detailMessage = ""
        
        // Test 1: Internet connectivity
        let hasInternet = await testInternetConnectivity()
        if !hasInternet {
            return (false, "❌ Geen internetverbinding", "Controleer je netwerkverbinding en probeer opnieuw.")
        }
        
        // Test 2: API Key validation
        let isValidFormat = APIConfiguration.isValidMistralKey(apiKey)
        if !isValidFormat {
            let keyPreview = apiKey.count > 10 ? "\(apiKey.prefix(10))..." : apiKey
            let keySource = apiKey == "YOUR_MISTRAL_API_KEY_HERE" ? "APIKeys.plist (placeholder)" : 
                           ProcessInfo.processInfo.environment["MISTRAL_API_KEY"] != nil ? "Environment variable" : 
                           "APIKeys.plist of hardcoded"
            
            return (false, "❌ Ongeldige API key format", 
                   """
                   API key: \(keyPreview)
                   Bron: \(keySource)
                   Lengte: \(apiKey.count) karakters
                   
                   Vereisten:
                   • Minimaal 20 karakters lang
                   • Mag niet 'YOUR_MISTRAL_API_KEY_HERE' zijn
                   
                   Controleer APIKeys.plist en vervang de placeholder.
                   """)
        }
        
        // Test 3: Connection test
        do {
            let success = try await testConnection()
            if success {
                return (true, "✅ Mistral API verbinding succesvol!", 
                       """
                       Model: \(APIConfiguration.selectedModel.rawValue)
                       Endpoint: \(baseURL)
                       Status: Verbonden en werkend
                       
                       Je API verbinding werkt correct!
                       """)
            } else {
                return (false, "❌ API verbinding mislukt", "Verbinding gemaakt maar geen geldig antwoord ontvangen.")
            }
        } catch {
            if let mistralError = error as? MistralError {
                switch mistralError {
                case .quotaExceeded:
                    return (false, "❌ API limiet overschreden", 
                           """
                           Rate limit bereikt voor Mistral API.
                           
                           Oplossingen:
                           • Plan upgraden op https://console.mistral.ai/plans
                           • Usage controleren op https://console.mistral.ai/usage
                           • Later opnieuw proberen
                           """)
                case .invalidAPIKey:
                    return (false, "❌ Ongeldige API key", 
                           """
                           Je API key is niet geldig.
                           
                           Controleer:
                           • API key spelling in APIKeys.plist
                           • Key is geactiveerd in Mistral Console
                           • Key heeft correcte permissies
                           """)
                case .accessDenied:
                    return (false, "❌ Toegang geweigerd", 
                           """
                           Geen toegang tot de Mistral API.
                           
                           Mogelijke oorzaken:
                           • Account beperking
                           • Regio restricties
                           • Plan limitaties
                           """)
                default:
                    return (false, "❌ API fout", "Error: \(error.localizedDescription)")
                }
            } else {
                return (false, "❌ Netwerkfout", "Error: \(error.localizedDescription)")
            }
        }
    }
    
    func analyzeReceipt(image: UIImage) async throws -> ReceiptData {
        // Check image processing first
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("DEBUG: Failed to convert image to JPEG data")
            throw MistralError.imageProcessingFailed
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
        
        let request = MistralAPIRequest(
            model: APIConfiguration.selectedModel.rawValue,
            messages: [
                MistralRequestMessage(role: "user", content: [
                    MistralMessageContent(type: "text", text: prompt),
                    MistralMessageContent(type: "image_url", imageUrl: MistralImageURL(url: "data:image/jpeg;base64,\(base64Image)"))
                ])
            ],
            maxTokens: 1000
        )
        
        guard let url = URL(string: baseURL) else {
            throw MistralError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.timeoutInterval = APIConfiguration.requestTimeout
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            print("DEBUG: Encoding failed: \(error)")
            throw MistralError.encodingFailed
        }
        
        print("DEBUG: Making request to: \(url)")
        print("DEBUG: Request headers: \(urlRequest.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
            guard let httpResponse = response as? HTTPURLResponse else {
                print("DEBUG: Invalid response type")
                throw MistralError.networkError
            }
            
            print("DEBUG: HTTP Status Code: \(httpResponse.statusCode)")
            print("DEBUG: Response Headers: \(httpResponse.allHeaderFields)")
            
            if httpResponse.statusCode != 200 {
                if let responseData = String(data: data, encoding: .utf8) {
                    print("DEBUG: Error Response Body: \(responseData)")
                    
                    // Check for specific error types
                    if httpResponse.statusCode == 429 {
                        throw MistralError.quotaExceeded
                    } else if httpResponse.statusCode == 401 {
                        throw MistralError.invalidAPIKey
                    } else if httpResponse.statusCode == 403 {
                        throw MistralError.accessDenied
                    }
                }
                throw MistralError.networkError
            }
        
            let mistralResponse = try JSONDecoder().decode(MistralAPIResponse.self, from: data)
            
            guard let text = mistralResponse.choices.first?.message.content else {
                throw MistralError.noResponse
            }
            
            // Clean the response text and parse JSON
            let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let jsonData = cleanedText.data(using: .utf8) else {
                throw MistralError.invalidResponse
            }
            
            do {
                return try JSONDecoder().decode(ReceiptData.self, from: jsonData)
            } catch {
                print("DEBUG: JSON parsing failed: \(error)")
                print("DEBUG: Cleaned text: \(cleanedText)")
                throw MistralError.parsingFailed
            }
        } catch {
            print("DEBUG: URLSession error: \(error)")
            if let urlError = error as? URLError {
                print("DEBUG: URLError code: \(urlError.code)")
                print("DEBUG: URLError description: \(urlError.localizedDescription)")
            }
            throw MistralError.networkError
        }
    }
}

enum MistralError: Error, LocalizedError {
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
            return "API limiet overschreden. Controleer je Mistral AI account of probeer later opnieuw."
        case .invalidAPIKey:
            return "Ongeldige API sleutel. Controleer je Mistral API configuratie."
        case .accessDenied:
            return "Toegang geweigerd. Controleer of de Mistral API key correct is geconfigureerd."
        case .noResponse:
            return "Geen respons van de API"
        case .invalidResponse:
            return "Ongeldig respons formaat"
        case .parsingFailed:
            return "Respons verwerken mislukt"
        }
    }
}
