//
//  ZipExporter.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import Foundation
import UIKit
import Compression

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
            
            // Create a ZIP archive using iOS compression
            let zipData = try createZipArchive(files: imageFiles, basePath: tempDirectory)
            
            // Clean up temp files
            try FileManager.default.removeItem(at: tempDirectory)
            
            return zipData
            
        } catch {
            print("Error creating ZIP archive: \(error)")
            // Clean up on error
            try? FileManager.default.removeItem(at: tempDirectory)
            return nil
        }
    }
    
    private static func createZipArchive(files: [URL], basePath: URL) throws -> Data {
        // Create a simple ZIP file using basic ZIP structure
        var zipData = Data()
        var centralDirectory = Data()
        var fileOffset: UInt32 = 0
        
        for fileURL in files {
            let filename = fileURL.lastPathComponent
            let fileData = try Data(contentsOf: fileURL)
            let filenameData = filename.data(using: .utf8) ?? Data()
            
            // Local file header
            let localHeader = createLocalFileHeader(filename: filenameData, fileSize: UInt32(fileData.count))
            zipData.append(localHeader)
            zipData.append(filenameData)
            zipData.append(fileData)
            
            // Central directory entry
            let centralEntry = createCentralDirectoryEntry(
                filename: filenameData,
                fileSize: UInt32(fileData.count),
                localHeaderOffset: fileOffset
            )
            centralDirectory.append(centralEntry)
            centralDirectory.append(filenameData)
            
            fileOffset = UInt32(zipData.count)
        }
        
        // Central directory end record
        let centralDirOffset = UInt32(zipData.count)
        zipData.append(centralDirectory)
        
        let endOfCentralDir = createEndOfCentralDirectoryRecord(
            entriesCount: UInt16(files.count),
            centralDirSize: UInt32(centralDirectory.count),
            centralDirOffset: centralDirOffset
        )
        zipData.append(endOfCentralDir)
        
        return zipData
    }
    
    private static func createLocalFileHeader(filename: Data, fileSize: UInt32) -> Data {
        var header = Data()
        
        // Local file header signature (4 bytes)
        header.append(Data([0x50, 0x4B, 0x03, 0x04]))
        
        // Version needed to extract (2 bytes)
        header.append(Data([0x14, 0x00]))
        
        // General purpose bit flag (2 bytes)
        header.append(Data([0x00, 0x00]))
        
        // Compression method (2 bytes) - no compression
        header.append(Data([0x00, 0x00]))
        
        // File last modification time (2 bytes)
        header.append(Data([0x00, 0x00]))
        
        // File last modification date (2 bytes)
        header.append(Data([0x00, 0x00]))
        
        // CRC-32 (4 bytes) - simplified, using 0
        header.append(Data([0x00, 0x00, 0x00, 0x00]))
        
        // Compressed size (4 bytes)
        var compressedSize = fileSize.littleEndian
        header.append(Data(bytes: &compressedSize, count: 4))
        
        // Uncompressed size (4 bytes)
        var uncompressedSize = fileSize.littleEndian
        header.append(Data(bytes: &uncompressedSize, count: 4))
        
        // File name length (2 bytes)
        var filenameLength = UInt16(filename.count).littleEndian
        header.append(Data(bytes: &filenameLength, count: 2))
        
        // Extra field length (2 bytes)
        header.append(Data([0x00, 0x00]))
        
        return header
    }
    
    private static func createCentralDirectoryEntry(filename: Data, fileSize: UInt32, localHeaderOffset: UInt32) -> Data {
        var entry = Data()
        
        // Central directory file header signature (4 bytes)
        entry.append(Data([0x50, 0x4B, 0x01, 0x02]))
        
        // Version made by (2 bytes)
        entry.append(Data([0x14, 0x00]))
        
        // Version needed to extract (2 bytes)
        entry.append(Data([0x14, 0x00]))
        
        // General purpose bit flag (2 bytes)
        entry.append(Data([0x00, 0x00]))
        
        // Compression method (2 bytes) - no compression
        entry.append(Data([0x00, 0x00]))
        
        // File last modification time (2 bytes)
        entry.append(Data([0x00, 0x00]))
        
        // File last modification date (2 bytes)
        entry.append(Data([0x00, 0x00]))
        
        // CRC-32 (4 bytes)
        entry.append(Data([0x00, 0x00, 0x00, 0x00]))
        
        // Compressed size (4 bytes)
        var compressedSize = fileSize.littleEndian
        entry.append(Data(bytes: &compressedSize, count: 4))
        
        // Uncompressed size (4 bytes)
        var uncompressedSize = fileSize.littleEndian
        entry.append(Data(bytes: &uncompressedSize, count: 4))
        
        // File name length (2 bytes)
        var filenameLength = UInt16(filename.count).littleEndian
        entry.append(Data(bytes: &filenameLength, count: 2))
        
        // Extra field length (2 bytes)
        entry.append(Data([0x00, 0x00]))
        
        // File comment length (2 bytes)
        entry.append(Data([0x00, 0x00]))
        
        // Disk number where file starts (2 bytes)
        entry.append(Data([0x00, 0x00]))
        
        // Internal file attributes (2 bytes)
        entry.append(Data([0x00, 0x00]))
        
        // External file attributes (4 bytes)
        entry.append(Data([0x00, 0x00, 0x00, 0x00]))
        
        // Relative offset of local file header (4 bytes)
        var offset = localHeaderOffset.littleEndian
        entry.append(Data(bytes: &offset, count: 4))
        
        return entry
    }
    
    private static func createEndOfCentralDirectoryRecord(entriesCount: UInt16, centralDirSize: UInt32, centralDirOffset: UInt32) -> Data {
        var record = Data()
        
        // End of central directory signature (4 bytes)
        record.append(Data([0x50, 0x4B, 0x05, 0x06]))
        
        // Number of this disk (2 bytes)
        record.append(Data([0x00, 0x00]))
        
        // Disk where central directory starts (2 bytes)
        record.append(Data([0x00, 0x00]))
        
        // Number of central directory entries on this disk (2 bytes)
        var entriesOnDisk = entriesCount.littleEndian
        record.append(Data(bytes: &entriesOnDisk, count: 2))
        
        // Total number of central directory entries (2 bytes)
        var totalEntries = entriesCount.littleEndian
        record.append(Data(bytes: &totalEntries, count: 2))
        
        // Size of central directory (4 bytes)
        var dirSize = centralDirSize.littleEndian
        record.append(Data(bytes: &dirSize, count: 4))
        
        // Offset of start of central directory (4 bytes)
        var dirOffset = centralDirOffset.littleEndian
        record.append(Data(bytes: &dirOffset, count: 4))
        
        // ZIP file comment length (2 bytes)
        record.append(Data([0x00, 0x00]))
        
        return record
    }
    
    static func shareZipFile(data: Data, filename: String, from viewController: UIViewController) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            activityVC.excludedActivityTypes = [.assignToContact, .saveToCameraRoll]
            
            // Clean up temporary file after sharing
            activityVC.completionWithItemsHandler = { _, _, _, _ in
                try? FileManager.default.removeItem(at: tempURL)
            }
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            viewController.present(activityVC, animated: true)
        } catch {
            print("Error sharing ZIP: \(error)")
        }
    }
}


