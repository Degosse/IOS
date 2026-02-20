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
}
