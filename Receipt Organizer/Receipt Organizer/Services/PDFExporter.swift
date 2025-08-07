//
//  PDFExporter.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import UIKit
import PDFKit
import SwiftUI

class PDFExporter {
    static func createReport(receipts: [Receipt], period: String, totalAmount: Double) -> Data? {
        let pageSize = CGSize(width: 612, height: 792) // US Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        
        do {
            return try renderer.pdfData { context in
                context.beginPage()
                
                let titleFont = UIFont.boldSystemFont(ofSize: 24)
                let headingFont = UIFont.boldSystemFont(ofSize: 16)
                let bodyFont = UIFont.systemFont(ofSize: 12)
                
                var yPosition: CGFloat = 50
                let margin: CGFloat = 50
                let pageWidth = pageSize.width - (margin * 2)
                
                // Title
                let title = NSLocalizedString("Expense Report", comment: "PDF title") + " - \(period)"
                let titleSize = title.size(withAttributes: [.font: titleFont])
                let titleRect = CGRect(x: margin, y: yPosition, width: pageWidth, height: titleSize.height)
                title.draw(in: titleRect, withAttributes: [
                    .font: titleFont,
                    .foregroundColor: UIColor.black
                ])
                
                yPosition += titleSize.height + 20
                
                // Summary section
                let summaryText = "\(NSLocalizedString("Total Expenses", comment: "PDF summary")): €\(String(format: "%.2f", totalAmount))\n\(NSLocalizedString("Number of Receipts", comment: "PDF summary")): \(receipts.count)"
                let summarySize = summaryText.size(withAttributes: [.font: headingFont])
                let summaryRect = CGRect(x: margin, y: yPosition, width: pageWidth, height: summarySize.height * 2)
                summaryText.draw(in: summaryRect, withAttributes: [
                    .font: headingFont,
                    .foregroundColor: UIColor.black
                ])
            
            yPosition += summarySize.height * 2 + 30
            
            // Receipts list header
            let headerText = NSLocalizedString("Receipt Details", comment: "PDF section header")
            let headerSize = headerText.size(withAttributes: [.font: headingFont])
            let headerRect = CGRect(x: margin, y: yPosition, width: pageWidth, height: headerSize.height)
            headerText.draw(in: headerRect, withAttributes: [
                .font: headingFont,
                .foregroundColor: UIColor.black
            ])
            
            yPosition += headerSize.height + 15
            
            // Table headers
            let headers = [NSLocalizedString("Date", comment: "PDF header"), NSLocalizedString("Restaurant", comment: "PDF header"), NSLocalizedString("Amount", comment: "PDF header")]
            let columnWidths: [CGFloat] = [120, 300, 100]
            var xPosition: CGFloat = margin
            
            for (index, header) in headers.enumerated() {
                let headerRect = CGRect(x: xPosition, y: yPosition, width: columnWidths[index], height: 20)
                header.draw(in: headerRect, withAttributes: [
                    .font: headingFont,
                    .foregroundColor: UIColor.black
                ])
                xPosition += columnWidths[index]
            }
            
            yPosition += 25
            
            // Draw line under headers
            context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            context.cgContext.setLineWidth(1)
            context.cgContext.move(to: CGPoint(x: margin, y: yPosition))
            context.cgContext.addLine(to: CGPoint(x: pageSize.width - margin, y: yPosition))
            context.cgContext.strokePath()
            
            yPosition += 10
            
            // Receipt rows
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            
            for receipt in receipts.sorted(by: { $0.date > $1.date }) {
                // Check if we need a new page
                if yPosition > pageSize.height - 100 {
                    context.beginPage()
                    yPosition = 50
                }
                
                xPosition = margin
                let rowData = [
                    dateFormatter.string(from: receipt.date),
                    receipt.restaurantName.isEmpty ? NSLocalizedString("Unknown", comment: "Unknown restaurant") : receipt.restaurantName,
                    "€\(String(format: "%.2f", receipt.totalPrice))"
                ]
                
                for (index, data) in rowData.enumerated() {
                    let cellRect = CGRect(x: xPosition, y: yPosition, width: columnWidths[index], height: 20)
                    data.draw(in: cellRect, withAttributes: [
                        .font: bodyFont,
                        .foregroundColor: UIColor.black
                    ])
                    xPosition += columnWidths[index]
                }
                
                yPosition += 25
            }
            
            // Footer
            yPosition = pageSize.height - 50
            let footerText = NSLocalizedString("Generated on", comment: "PDF footer") + " \(Date().formatted(date: .abbreviated, time: .shortened))"
            let footerRect = CGRect(x: margin, y: yPosition, width: pageWidth, height: 20)
            footerText.draw(in: footerRect, withAttributes: [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ])
        }
        } catch {
            print("Error creating PDF: \(error)")
            return nil
        }
    }
    
    static func shareDocument(data: Data, filename: String, from viewController: UIViewController) {
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
            print("Error sharing document: \(error)")
        }
    }
}
