//
//  ZipExporter.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import Foundation
import UIKit

class ZipExporter {
    static func createReceiptImagesZip(receipts: [Receipt], period: String) -> Data? {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("ReceiptImages_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
            
            var imageFiles: [URL] = []
            
            // Save all receipt images to temp directory
            for (index, receipt) in receipts.enumerated() {
                if let image = receipt.image,
                   let imageData = image.jpegData(compressionQuality: 0.8) {
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: receipt.date)
                    
                    let restaurantName = receipt.restaurantName.isEmpty ? NSLocalizedString("Unknown", comment: "Unknown restaurant") : receipt.restaurantName
                    let cleanRestaurantName = restaurantName.replacingOccurrences(of: "[^a-zA-Z0-9 ]", with: "_", options: .regularExpression)
                    
                    let filename = "\(String(format: "%03d", index + 1))_\(dateString)_\(cleanRestaurantName)_€\(String(format: "%.2f", receipt.totalPrice)).jpg"
                    let fileURL = tempDirectory.appendingPathComponent(filename)
                    
                    try imageData.write(to: fileURL)
                    imageFiles.append(fileURL)
                }
            }
            
            // Create a tar-like archive since ZIP requires external dependencies
            let archiveData = try createTarArchive(files: imageFiles, basePath: tempDirectory)
            
            // Clean up temp files
            try FileManager.default.removeItem(at: tempDirectory)
            
            return archiveData
            
        } catch {
            print("Error creating archive: \(error)")
            // Clean up on error
            try? FileManager.default.removeItem(at: tempDirectory)
            return nil
        }
    }
    
    private static func createTarArchive(files: [URL], basePath: URL) throws -> Data {
        var archiveData = Data()
        
        // Simple tar-like format with file headers
        for fileURL in files {
            let filename = fileURL.lastPathComponent
            let fileData = try Data(contentsOf: fileURL)
            
            // Create a simple header: filename length + filename + data length + data
            let filenameData = filename.data(using: .utf8) ?? Data()
            
            // Write filename length (4 bytes, big endian)
            var filenameLength = UInt32(filenameData.count).bigEndian
            archiveData.append(Data(bytes: &filenameLength, count: 4))
            
            // Write filename
            archiveData.append(filenameData)
            
            // Write data length (4 bytes, big endian)
            var dataLength = UInt32(fileData.count).bigEndian
            archiveData.append(Data(bytes: &dataLength, count: 4))
            
            // Write file data
            archiveData.append(fileData)
        }
        
        return archiveData
    }
    
    static func shareArchiveFile(data: Data, filename: String, from viewController: UIViewController) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            activityVC.excludedActivityTypes = [.assignToContact, .saveToCameraRoll]
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            viewController.present(activityVC, animated: true)
        } catch {
            print("Error sharing archive file: \(error)")
        }
    }
}


