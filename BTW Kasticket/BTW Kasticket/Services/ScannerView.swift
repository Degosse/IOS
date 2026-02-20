import SwiftUI
import VisionKit

struct ScannerView: UIViewControllerRepresentable {
    var completionHandler: ([UIImage]?) -> Void
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(completion: completionHandler)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let completionHandler: ([UIImage]?) -> Void

        init(completion: @escaping ([UIImage]?) -> Void) {
            self.completionHandler = completion
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            let images = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
            controller.dismiss(animated: true) {
                self.completionHandler(images)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true) {
                self.completionHandler(nil)
            }
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document camera error: \(error.localizedDescription)")
            controller.dismiss(animated: true) {
                self.completionHandler(nil)
            }
        }
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
}
