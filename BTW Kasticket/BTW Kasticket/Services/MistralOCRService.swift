import Foundation
import UIKit

struct OCRResult: Codable {
    var date: Date?
    var restaurantName: String
    var totalPrice: Double
}

class MistralOCRService {
    static let shared = MistralOCRService()
    // In a real app, you shouldn't hardcode this, but we're keeping it simple for the MVP
    private let apiKey = "bYa8Hpcsoog1GPrmIqs3FRoRDwDdFIcJ"
    private let endpoint = "https://api.mistral.ai/v1/ocr"
    
    enum OCRError: Error {
        case invalidURL
        case invalidImageData
        case networkingError(Error)
        case decodingError(Error)
        case apiError(String)
        case missingData
    }
    
    // We construct a JSON Schema so the model knows what to output
    // However, Mistral OCR natively just returns markdown or text. 
    // To extract structured data, we might need a separate chat completion call, 
    // or if the OCR endpoint supports structured output directly.
    // The mistral-ocr-latest endpoint is primarily for extracting text/markdown.
    // So we'll first call the OCR endpoint, get the markdown, and then call a chat completion to extract the JSON.
    
    func processReceipt(image: UIImage) async throws -> OCRResult {
        let markdown = try await performOCR(image: image)
        return try await extractDataLocallyOrWithLLM(markdown: markdown)
    }
    
    private func performOCR(image: UIImage) async throws -> String {
        guard let url = URL(string: endpoint) else { throw OCRError.invalidURL }
        
        // Resize image to avoid massive payloads, but keep it readable
        guard let resized = image.resized(toWidth: 1024),
              let imageData = resized.jpegData(compressionQuality: 0.8) else {
            throw OCRError.invalidImageData
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Construct the payload for the OCR endpoint
        let requestBody: [String: Any] = [
            "model": "mistral-ocr-latest",
            "document": [
                "type": "image_url",
                "image_url": "data:image/jpeg;base64,\(base64Image)"
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown HTTP Error \(httpResponse.statusCode)"
            throw OCRError.apiError(errorString)
        }
        
        struct MistralOCRResponse: Decodable {
            struct Page: Decodable {
                let markdown: String
            }
            let pages: [Page]
        }
        
        let ocrResponse = try JSONDecoder().decode(MistralOCRResponse.self, from: data)
        let fullMarkdown = ocrResponse.pages.map(\.markdown).joined(separator: "\n")
        return fullMarkdown
    }
    
    private func extractDataLocallyOrWithLLM(markdown: String) async throws -> OCRResult {
        // Now call the chat completions API using a small model like 'mistral-small-latest'
        // to parse the markdown into JSON.
        let chatEndpoint = "https://api.mistral.ai/v1/chat/completions"
        guard let url = URL(string: chatEndpoint) else { throw OCRError.invalidURL }
        
        let prompt = """
        Extract the following information from this receipt markdown:
        1. date (in format yyyy-MM-dd)
        2. restaurantName (string)
        3. totalPrice (number, e.g. 45.50)

        Receipt Markdown:
        \(markdown)
        """
        
        let requestBody: [String: Any] = [
            "model": "mistral-small-latest",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            // Request JSON output
            "response_format": ["type": "json_schema", "json_schema": [
                "name": "receipt_extraction",
                "strict": true,
                "schema": [
                    "type": "object",
                    "properties": [
                        "date": ["type": "string"],
                        "restaurantName": ["type": "string"],
                        "totalPrice": ["type": "number"]
                    ],
                    "required": ["date", "restaurantName", "totalPrice"]
                ]
            ]]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown HTTP Error \(httpResponse.statusCode)"
            throw OCRError.apiError(errorString)
        }
        
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let contentString = chatResponse.choices.first?.message.content,
              let contentData = contentString.data(using: .utf8) else {
            throw OCRError.missingData
        }
        
        struct JSONExtraction: Decodable {
            let date: String
            let restaurantName: String
            let totalPrice: Double
        }
        
        let extraction = try JSONDecoder().decode(JSONExtraction.self, from: contentData)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let parsedDate = dateFormatter.date(from: extraction.date)
        
        return OCRResult(date: parsedDate, restaurantName: extraction.restaurantName, totalPrice: extraction.totalPrice)
    }
}

// Helper to resize images to avoid big payload sizes for base64
extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
