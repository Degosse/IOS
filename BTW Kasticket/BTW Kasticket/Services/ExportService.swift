import Foundation
import UIKit
import PDFKit
import WebKit

class ExportWebPDFGenerator: NSObject, WKNavigationDelegate {
    private var webView: WKWebView?
    private var continuation: CheckedContinuation<URL?, Never>?
    private var targetURL: URL?

    @MainActor
    func generate(html: String, targetURL: URL) async -> URL? {
        self.targetURL = targetURL
        return await withCheckedContinuation { cont in
            self.continuation = cont
            let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 595.2, height: 841.8))
            self.webView = webView
            webView.navigationDelegate = self
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let printFormatter = webView.viewPrintFormatter()
        let render = UIPrintPageRenderer()
        render.addPrintFormatter(printFormatter, startingAtPageAt: 0)
        
        // A4 paper size setup
        let pageRange = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 points
        render.setValue(NSValue(cgRect: pageRange), forKey: "paperRect")
        render.setValue(NSValue(cgRect: pageRange), forKey: "printableRect")
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageRange, nil)
        
        // Render all generated pages
        let numberOfPages = render.numberOfPages
        if numberOfPages > 0 {
            for i in 0..<numberOfPages {
                UIGraphicsBeginPDFPage()
                render.drawPage(at: i, in: UIGraphicsGetPDFContextBounds())
            }
        } else {
            // Failsafe in case nothing rendered
            UIGraphicsBeginPDFPage()
        }
        UIGraphicsEndPDFContext()
        
        if let target = self.targetURL {
            do {
                try pdfData.write(to: target, options: .atomic)
                self.continuation?.resume(returning: target)
            } catch {
                self.continuation?.resume(returning: nil)
            }
        } else {
            self.continuation?.resume(returning: nil)
        }
        
        self.continuation = nil
    }
}

class ExportService {
    static let shared = ExportService()
    
    private var webGenerator: ExportWebPDFGenerator?
    
    @MainActor
    func generatePDF(for periodName: String, receipts: [ExpenseReceipt], signatureImage: UIImage? = nil) async -> URL? {
        let total = receipts.reduce(0) { $0 + $1.totalPrice }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let todayString = dateFormatter.string(from: Date())
        
        // WKWebView natively supports base64 embedded images perfectly.
        var signatureHTML = ""
        if let sigImage = signatureImage, let sigData = sigImage.pngData() {
            let base64 = sigData.base64EncodedString()
            signatureHTML = "<img src='data:image/png;base64,\(base64)' width='150' />"
        } else {
            signatureHTML = "<br/><br/><i>[Handtekening hier]</i>"
        }
        
        var rowsHTML = ""
        for receipt in receipts {
            let dateStr = dateFormatter.string(from: receipt.date)
            rowsHTML += """
            <tr>
                <td>\(dateStr)</td>
                <td>\(receipt.restaurantName)</td>
                <td>Bancontact</td>
                <td style="text-align: right;">\(String(format: "%.2f", receipt.totalPrice).replacingOccurrences(of: ".", with: ","))</td>
            </tr>
            """
        }
        
        let htmlBody = """
        <html>
        <head>
            <style>
                body { font-family: Helvetica, Arial, sans-serif; font-size: 14px; margin: 40px; }
                h1 { font-size: 18px; text-align: center; border: 2px solid black; padding: 10px; background-color: #f2f2f2; }
                .header-info { display: flex; justify-content: space-between; margin-bottom: 30px; }
                table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
                th, td { border: 1px solid black; padding: 5px; }
                th { background-color: #f2f2f2; text-align: left; }
                .total-row td { font-weight: bold; }
                .signature-section { display: flex; justify-content: space-between; margin-top: 50px; }
            </style>
        </head>
        <body>
            <h1>OVERZICHT DIVERSE KOSTEN \(periodName)</h1>
            
            <div class="header-info">
                <div>
                    <b>BEDRIJF</b><br/>
                    Nicolaï Gosselin Consulting<br/>
                    Hulstbaan 201<br/>
                    9112 Sinaai-Waas
                </div>
                <div>
                    <b>BTW-nummer</b><br/>
                    BE0770360439
                </div>
            </div>
            
            <table>
                <tr>
                    <th width="15%">Datum</th>
                    <th width="45%">Leverancier</th>
                    <th width="20%">Betaalwijze</th>
                    <th width="20%" style="text-align: right;">Bedrag incl btw</th>
                </tr>
                <tr>
                    <td colspan="4" style="background-color: #e6e6e6; font-weight: bold;">Restaurantkosten</td>
                </tr>
                \(rowsHTML)
                <tr>
                    <td colspan="3" style="text-align: right;"></td>
                    <td style="text-align: right; border-bottom: 2px solid black; border-top: 2px solid black; font-weight: bold;">\(String(format: "%.2f", total).replacingOccurrences(of: ".", with: ","))</td>
                </tr>
            </table>
            
            <div style="font-size: 18px; font-weight: bold; border: 2px solid black; padding: 5px; display: flex; justify-content: space-between;">
                <span>Totaal</span>
                <span>\(String(format: "%.2f", total).replacingOccurrences(of: ".", with: ","))</span>
            </div>
            
            <div class="signature-section">
                <div>
                    Datum,<br/>
                    \(todayString)
                </div>
                <div>
                    Handtekening,<br/>
                    \(signatureHTML)
                </div>
            </div>
        </body>
        </html>
        """
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Kostenoverzicht_\(periodName).pdf")
        
        let generator = ExportWebPDFGenerator()
        self.webGenerator = generator
        let result = await generator.generate(html: htmlBody, targetURL: url)
        self.webGenerator = nil
        return result
    }

    @MainActor
    func generateSingleReceiptPDF(receipt: ExpenseReceipt) async -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let dateStr = dateFormatter.string(from: receipt.date)
        
        // Convert the raw receipt scan image to base64 if it exists
        var receiptImageHTML = ""
        if let data = receipt.imageData {
            let base64 = data.base64EncodedString()
            receiptImageHTML = """
            <div style="margin-top: 40px; text-align: center;">
                <h3>Scanned Image / Origineel Ticket</h3>
                <img src='data:image/jpeg;base64,\(base64)' style="max-width: 100%; max-height: 500px; border: 1px solid #ccc; padding: 5px;"/>
            </div>
            """
        }
        
        let htmlBody = """
        <html>
        <head>
            <style>
                body { font-family: Helvetica, Arial, sans-serif; font-size: 14px; margin: 40px; }
                h1 { font-size: 22px; text-align: center; border-bottom: 2px solid black; padding-bottom: 10px; }
                table { width: 100%; border-collapse: collapse; margin-top: 30px; }
                th, td { border: 1px solid black; padding: 10px; text-align: left; }
                th { background-color: #f2f2f2; width: 30%; }
                .amount { font-size: 18px; font-weight: bold; }
            </style>
        </head>
        <body>
            <h1>Receipt Details / Kasticket Info</h1>
            
            <table>
                <tr>
                    <th>Leverancier / Restaurant</th>
                    <td>\(receipt.restaurantName)</td>
                </tr>
                <tr>
                    <th>Datum / Date</th>
                    <td>\(dateStr)</td>
                </tr>
                <tr>
                    <th>Bedrag / Total Price</th>
                    <td class="amount">€\(String(format: "%.2f", receipt.totalPrice).replacingOccurrences(of: ".", with: ","))</td>
                </tr>
            </table>
            
            \(receiptImageHTML)
        </body>
        </html>
        """
        
        let safeName = receipt.restaurantName.replacingOccurrences(of: " ", with: "_").components(separatedBy: .punctuationCharacters).joined()
        let filename = "Receipt_\(safeName)_\(dateStr.replacingOccurrences(of: "/", with: "-")).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        // Reuse the WebKit HTML-to-PDF generator since it correctly renders Base64
        let generator = ExportWebPDFGenerator()
        self.webGenerator = generator
        let result = await generator.generate(html: htmlBody, targetURL: url)
        self.webGenerator = nil
        return result
    }

    func generateZIP(for periodName: String, receipts: [ExpenseReceipt]) async -> URL? {
        let fileManager = FileManager.default
        let bundleDir = fileManager.temporaryDirectory.appendingPathComponent("Kastickets_Archive_\(periodName)")
        
        do {
            if fileManager.fileExists(atPath: bundleDir.path) {
                try fileManager.removeItem(at: bundleDir)
            }
            try fileManager.createDirectory(at: bundleDir, withIntermediateDirectories: true, attributes: nil)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            // Write all images to the temporary folder
            for (index, receipt) in receipts.enumerated() {
                if let data = receipt.imageData {
                    let dateStr = dateFormatter.string(from: receipt.date)
                    let safeName = receipt.restaurantName.replacingOccurrences(of: " ", with: "_").components(separatedBy: .punctuationCharacters).joined()
                    let filename = "\(dateStr)_\(safeName)_\(index).jpg"
                    let fileURL = bundleDir.appendingPathComponent(filename)
                    try data.write(to: fileURL)
                }
            }
            
            // NSFileCoordinator will securely zip the directory for us when using .forUploading
            return await withCheckedContinuation { continuation in
                let coordinator = NSFileCoordinator()
                var error: NSError?
                
                coordinator.coordinate(readingItemAt: bundleDir, options: [.forUploading], error: &error) { zipURL in
                    do {
                        let finalZipURL = fileManager.temporaryDirectory.appendingPathComponent("Kastickets_Archive_\(periodName).zip")
                        if fileManager.fileExists(atPath: finalZipURL.path) {
                            try fileManager.removeItem(at: finalZipURL)
                        }
                        try fileManager.copyItem(at: zipURL, to: finalZipURL)
                        continuation.resume(returning: finalZipURL)
                    } catch {
                        print("Failed to copy built zip: \(error)")
                        continuation.resume(returning: nil)
                    }
                }
                
                if let coordinatorError = error {
                    print("Coordinator zip error: \(coordinatorError)")
                    continuation.resume(returning: nil)
                }
            }
        } catch {
            print("Failed to build directory for zip: \(error)")
            return nil
        }
    }
}
