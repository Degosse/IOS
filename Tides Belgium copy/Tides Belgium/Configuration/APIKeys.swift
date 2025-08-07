//
//  APIKeys.swift
//  Tides Belgium
//
//  Configuration file for API keys and external services
//

import Foundation

struct APIKeys {
    // WorldTides API (Free tier available)
    // Sign up at: https://www.worldtides.info/register
    // Free tier includes: 1000 API calls per month
    static let worldTidesAPIKey = ""
    
    // Alternative API sources (for backup/comparison)
    // Tide-API.com, NOAA, etc.
    static let alternativeAPIKey = ""
    
    // Get the active WorldTides API key
    static func getWorldTidesKey() -> String {
        // Priority order:
        // 1. Environment variable (for CI/CD)
        // 2. This file (for development)
        // 3. Info.plist (for production)
        
        if let envKey = ProcessInfo.processInfo.environment["WORLDTIDES_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        if !worldTidesAPIKey.isEmpty {
            return worldTidesAPIKey
        }
        
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let apiKey = plist["WorldTidesAPIKey"] as? String, !apiKey.isEmpty {
            return apiKey
        }
        
        return ""
    }
}

/*
 SETUP INSTRUCTIONS:
 
 1. Get a free API key from WorldTides:
    - Go to https://www.worldtides.info/register
    - Sign up for a free account (1000 calls/month)
    - Copy your API key
 
 2. Add the key to this file:
    - Replace the empty string above with your key
    - Example: static let worldTidesAPIKey = "your-api-key-here"
 
 3. Alternative setup methods:
    - Environment variable: WORLDTIDES_API_KEY=your-key
    - Info.plist: Add WorldTidesAPIKey key with your API key value
 
 4. The app will automatically use real tide data when a key is configured,
    and fall back to realistic synthetic data otherwise.
 
 Note: Never commit real API keys to version control!
 Add APIKeys.swift to .gitignore in production projects.
 */
