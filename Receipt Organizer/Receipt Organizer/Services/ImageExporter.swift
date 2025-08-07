//
//  ImageExporter.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import Foundation
import UIKit
import Photos

class ImageExporter {
    
    /// Save receipt images directly to the Photos library
    static func saveImagesToPhotos(receipts: [Receipt], completion: @escaping (Result<Int, Error>) -> Void) {
        // Request photo library permission
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    performSaveToPhotos(receipts: receipts, completion: completion)
                case .denied, .restricted:
                    completion(.failure(ImageExportError.photoLibraryAccessDenied))
                case .notDetermined:
                    completion(.failure(ImageExportError.photoLibraryAccessNotDetermined))
                @unknown default:
                    completion(.failure(ImageExportError.unknownPhotoLibraryError))
                }
            }
        }
    }
    
    private static func performSaveToPhotos(receipts: [Receipt], completion: @escaping (Result<Int, Error>) -> Void) {
        var savedCount = 0
        var errors: [Error] = []
        let dispatchGroup = DispatchGroup()
        
        for receipt in receipts {
            guard let image = receipt.image else { continue }
            
            dispatchGroup.enter()
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    savedCount += 1
                } else if let error = error {
                    errors.append(error)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if errors.isEmpty {
                completion(.success(savedCount))
            } else {
                completion(.failure(ImageExportError.saveFailed(errors.first!)))
            }
        }
    }
    
    /// Create individual image files for sharing (without zipping)
    static func prepareImagesForSharing(receipts: [Receipt], period: String) -> [URL]? {
        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("ReceiptImages_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
            
            var imageFiles: [URL] = []
            
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
            
            return imageFiles
            
        } catch {
            print("Error preparing images for sharing: \(error)")
            try? FileManager.default.removeItem(at: tempDirectory)
            return nil
        }
    }
    
    /// Share multiple images as individual files
    static func shareImages(imageURLs: [URL], from viewController: UIViewController, completion: @escaping () -> Void = {}) {
        guard !imageURLs.isEmpty else {
            completion()
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: imageURLs, applicationActivities: nil)
        activityVC.excludedActivityTypes = [.assignToContact]
        
        // Clean up temporary files after sharing
        activityVC.completionWithItemsHandler = { _, _, _, _ in
            // Clean up all temporary files
            for url in imageURLs {
                try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
            }
            completion()
        }
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityVC, animated: true)
    }
}

enum ImageExportError: LocalizedError {
    case photoLibraryAccessDenied
    case photoLibraryAccessNotDetermined
    case unknownPhotoLibraryError
    case saveFailed(Error)
    case noImages
    
    var errorDescription: String? {
        switch self {
        case .photoLibraryAccessDenied:
            return NSLocalizedString("Photo library access denied. Please enable it in Settings.", comment: "Photo access error")
        case .photoLibraryAccessNotDetermined:
            return NSLocalizedString("Photo library access not determined.", comment: "Photo access error")
        case .unknownPhotoLibraryError:
            return NSLocalizedString("Unknown photo library error.", comment: "Photo access error")
        case .saveFailed(let error):
            return NSLocalizedString("Failed to save images: \(error.localizedDescription)", comment: "Save error")
        case .noImages:
            return NSLocalizedString("No images to export.", comment: "Export error")
        }
    }
}
