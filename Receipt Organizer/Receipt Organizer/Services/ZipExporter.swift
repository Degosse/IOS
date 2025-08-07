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
            
            // Create a folder to zip
            let imagesFolder = tempDirectory.appendingPathComponent("Receipt_Images_\(period)")
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
            
            // Save all receipt images to temp directory
            for (index, receipt) in receipts.enumerated() {
                if let image = receipt.image,
                   let imageData = image.jpegData(compressionQuality: 0.8) {
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    let dateString = dateFormatter.string(from: receipt.date)
                    
                    let restaurantName = receipt.restaurantName.isEmpty ? "Unknown" : receipt.restaurantName
                    let cleanRestaurantName = restaurantName.replacingOccurrences(of: "[^a-zA-Z0-9 ]", with: "_", options: .regularExpression)
                    
                    let filename = "\(String(format: "%03d", index + 1))_\(dateString)_\(cleanRestaurantName)_$\(String(format: "%.2f", receipt.totalPrice)).jpg"
                    let fileURL = imagesFolder.appendingPathComponent(filename)
                    
                    try imageData.write(to: fileURL)
                }
            }
            
            // Create a simple tar-like archive (since we can't use ZIP without external library)
            let archiveData = try createSimpleArchive(from: imagesFolder)
            
            // Clean up temp files
            try FileManager.default.removeItem(at: tempDirectory)
            
            return archiveData
            
        } catch {
            print("Error creating archive: \(error)")
            return nil
        }
    }
    
    private static func createSimpleArchive(from directory: URL) throws -> Data {
        // Create a simple archive by concatenating all files with metadata
        // This is a simplified approach - in production, use a proper ZIP library
        var archiveData = Data()
        
        let fileManager = FileManager.default
        let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
        
        // Add header
        let header = "RECEIPT_ARCHIVE_V1\n"
        archiveData.append(header.data(using: .utf8) ?? Data())
        
        for fileURL in files {
            let filename = fileURL.lastPathComponent
            let fileData = try Data(contentsOf: fileURL)
            
            // Add file entry: filename length, filename, data length, data
            let filenameData = filename.data(using: .utf8) ?? Data()
            
            // Write filename length (4 bytes)
            var filenameLength = UInt32(filenameData.count).bigEndian
            archiveData.append(Data(bytes: &filenameLength, count: 4))
            
            // Write filename
            archiveData.append(filenameData)
            
            // Write data length (4 bytes) 
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

enum ArchiveError: Error {
    case cannotCreateDirectory
    case cannotWriteFile
    
    var localizedDescription: String {
        switch self {
        case .cannotCreateDirectory:
            return "Cannot create directory for archive"
        case .cannotWriteFile:
            return "Cannot write file to archive"
        }
    }
}
