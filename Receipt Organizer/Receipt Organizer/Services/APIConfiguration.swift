//
//  APIConfiguration.swift
//  Receipt Organizer
//
//  Configuration for API keys and endpoints
//

import Foundation

struct APIConfiguration {
    // MARK: - Gemini API Configuration
    
    /// Get Gemini API key from environment or fallback
    static var geminiAPIKey: String {
        // First, try to get from environment (for development)
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            return envKey
        }
        
        // Fallback to plist file (recommended for production)
        if let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let key = plist["GeminiAPIKey"] as? String {
            return key
        }
        
        // Last resort: hardcoded (not recommended for production)
        return "AIzaSyDnty6qTaxvDke-7bxl40SdRNp2PtHCdyw"
    }
    
    /// Gemini API base URL
    static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"
    
    /// Gemini API configuration
    static let maxRetries = 3
    static let retryDelay: UInt64 = 2_000_000_000 // 2 seconds
    static let requestTimeout: TimeInterval = 30.0
    
    // MARK: - Helper Methods
    
    /// Validate API key format
    static func isValidAPIKey(_ key: String) -> Bool {
        return key.hasPrefix("AIza") && key.count >= 35
    }
    
    /// Check if API is properly configured
    static func isConfigured() -> Bool {
        let key = geminiAPIKey
        return !key.isEmpty && isValidAPIKey(key) && key != "YOUR_API_KEY_HERE"
    }
}