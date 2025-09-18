//
//  APIConfiguration.swift
//  Receipt Organizer
//
//  Configuration for API keys and endpoints
//

import Foundation

struct APIConfiguration {
    // MARK: - Mistral AI Configuration
    
    /// Available AI models
    enum AIModel: String, CaseIterable {
        case pixtral12B = "pixtral-12b-latest"
        case pixtralLarge = "pixtral-large-latest"
        case mistralMedium = "mistral-medium-latest"
        case mistralSmall = "mistral-small-latest"
        
        var supportsVision: Bool {
            // All current Mistral models with vision support
            switch self {
            case .pixtral12B, .pixtralLarge, .mistralMedium, .mistralSmall:
                return true
            }
        }
        
        var displayName: String {
            switch self {
            case .pixtral12B:
                return "Pixtral 12B"
            case .pixtralLarge:
                return "Pixtral Large"
            case .mistralMedium:
                return "Mistral Medium"
            case .mistralSmall:
                return "Mistral Small"
            }
        }
    }
    
    /// Current model to use (Pixtral 12B is good for receipt analysis)
    static let selectedModel: AIModel = .pixtral12B
    
    /// Get Mistral API key from environment or fallback
    static var mistralAPIKey: String {
        // First, try to get from environment (for development)
        if let envKey = ProcessInfo.processInfo.environment["MISTRAL_API_KEY"] {
            return envKey
        }
        
        // Fallback to plist file (recommended for production)
        if let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let key = plist["MistralAPIKey"] as? String {
            return key
        }
        
        // Last resort: hardcoded (your new API key)
        return "bYa8Hpcsoog1GPrmIqs3FRoRDwDdFIcJ"
    }
    
    /// Mistral API base URL
    static let mistralBaseURL = "https://api.mistral.ai/v1/chat/completions"
    
    /// Legacy Gemini compatibility properties
    static var geminiAPIKey: String {
        // Fallback to plist file for Gemini key
        if let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let key = plist["GeminiAPIKey"] as? String {
            return key
        }
        return "YOUR_API_KEY_HERE"
    }
    
    static var geminiBaseURL: String { return "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent" }
    
    /// General API configuration
    static let maxRetries = 3
    static let retryDelay: UInt64 = 2_000_000_000 // 2 seconds
    static let requestTimeout: TimeInterval = 30.0
    
    // MARK: - Helper Methods
    
    /// Validate Mistral API key format
    static func isValidMistralKey(_ key: String) -> Bool {
        return !key.isEmpty && key.count >= 20 && key != "YOUR_MISTRAL_API_KEY_HERE"
    }
    
    /// Check if Mistral API is properly configured
    static func isMistralConfigured() -> Bool {
        let key = mistralAPIKey
        return !key.isEmpty && isValidMistralKey(key)
    }
    
    /// Legacy Gemini validation methods
    static func isValidAPIKey(_ key: String) -> Bool {
        return key.hasPrefix("AIza") && key.count >= 35
    }
    
    /// Check if Gemini API is properly configured
    static func isConfigured() -> Bool {
        let key = geminiAPIKey
        return !key.isEmpty && isValidAPIKey(key) && key != "YOUR_API_KEY_HERE"
    }
}