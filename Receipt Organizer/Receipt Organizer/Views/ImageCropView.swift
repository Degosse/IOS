//
//  ImageCropView.swift
//  Receipt Organizer
//
//  Created by Nicolaï Gosselin on 07/08/2025.
//

import SwiftUI
import UIKit

struct ImageCropView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var croppedImage: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let cropViewController = CropViewController(image: image ?? UIImage())
        cropViewController.delegate = context.coordinator
        let navigationController = UINavigationController(rootViewController: cropViewController)
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CropViewControllerDelegate {
        let parent: ImageCropView
        
        init(_ parent: ImageCropView) {
            self.parent = parent
        }
        
        func cropViewController(_ cropViewController: CropViewController, didCropImage image: UIImage) {
            parent.croppedImage = image
            parent.isPresented = false
        }
        
        func cropViewControllerDidCancel(_ cropViewController: CropViewController) {
            parent.isPresented = false
        }
    }
}

protocol CropViewControllerDelegate: AnyObject {
    func cropViewController(_ cropViewController: CropViewController, didCropImage image: UIImage)
    func cropViewControllerDidCancel(_ cropViewController: CropViewController)
}

class CropViewController: UIViewController {
    weak var delegate: CropViewControllerDelegate?
    private let originalImage: UIImage
    private var imageView: UIImageView!
    private var cropOverlay: CropOverlayView!
    
    init(image: UIImage) {
        self.originalImage = image
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Navigation bar
        navigationItem.title = "Crop Receipt"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        // Image view
        imageView = UIImageView(image: originalImage)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Crop overlay
        cropOverlay = CropOverlayView()
        cropOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cropOverlay)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            cropOverlay.topAnchor.constraint(equalTo: imageView.topAnchor),
            cropOverlay.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            cropOverlay.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            cropOverlay.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        ])
    }
    
    @objc private func cancelTapped() {
        delegate?.cropViewControllerDidCancel(self)
    }
    
    @objc private func doneTapped() {
        guard let croppedImage = cropImage() else { return }
        delegate?.cropViewController(self, didCropImage: croppedImage)
    }
    
    private func cropImage() -> UIImage? {
        guard let image = imageView.image else { return nil }
        
        let cropRect = cropOverlay.cropRect
        let scale = image.size.width / imageView.bounds.width
        
        let scaledCropRect = CGRect(
            x: cropRect.origin.x * scale,
            y: cropRect.origin.y * scale,
            width: cropRect.size.width * scale,
            height: cropRect.size.height * scale
        )
        
        guard let cgImage = image.cgImage?.cropping(to: scaledCropRect) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

class CropOverlayView: UIView {
    private let borderWidth: CGFloat = 2.0
    private let cornerLength: CGFloat = 20.0
    private let handleSize: CGFloat = 30.0
    private var _cropRect: CGRect = CGRect(x: 50, y: 50, width: 200, height: 300)
    private var activeHandle: Handle = .none
    private var lastPanPoint: CGPoint = .zero
    
    enum Handle {
        case none, move, topLeft, topRight, bottomLeft, bottomRight, top, bottom, left, right
    }
    
    var cropRect: CGRect {
        return _cropRect
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Initialize crop rect to center of view with reasonable size
        if _cropRect.origin.x == 50 && _cropRect.origin.y == 50 {
            let width = bounds.width * 0.8
            let height = bounds.height * 0.6
            _cropRect = CGRect(
                x: (bounds.width - width) / 2,
                y: (bounds.height - height) / 2,
                width: width,
                height: height
            )
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw dark overlay
        context.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
        context.fill(rect)
        
        // Clear crop area
        context.clear(_cropRect)
        
        // Draw crop border
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(borderWidth)
        context.stroke(_cropRect)
        
        // Draw corner indicators
        drawCorners(in: context)
        
        // Draw resize handles
        drawResizeHandles(in: context)
    }
    
    private func drawResizeHandles(in context: CGContext) {
        context.setFillColor(UIColor.white.cgColor)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.0)
        
        let handles = [
            CGPoint(x: _cropRect.minX, y: _cropRect.minY), // Top-left
            CGPoint(x: _cropRect.maxX, y: _cropRect.minY), // Top-right
            CGPoint(x: _cropRect.minX, y: _cropRect.maxY), // Bottom-left
            CGPoint(x: _cropRect.maxX, y: _cropRect.maxY), // Bottom-right
            CGPoint(x: _cropRect.midX, y: _cropRect.minY), // Top
            CGPoint(x: _cropRect.midX, y: _cropRect.maxY), // Bottom
            CGPoint(x: _cropRect.minX, y: _cropRect.midY), // Left
            CGPoint(x: _cropRect.maxX, y: _cropRect.midY)  // Right
        ]
        
        for handle in handles {
            let handleRect = CGRect(
                x: handle.x - 8,
                y: handle.y - 8,
                width: 16,
                height: 16
            )
            
            // Fill handle
            context.fillEllipse(in: handleRect)
            
            // Stroke handle
            context.strokeEllipse(in: handleRect)
        }
    }
    
    private func drawCorners(in context: CGContext) {
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(3.0)
        
        let corners = [
            CGPoint(x: _cropRect.minX, y: _cropRect.minY), // Top-left
            CGPoint(x: _cropRect.maxX, y: _cropRect.minY), // Top-right
            CGPoint(x: _cropRect.minX, y: _cropRect.maxY), // Bottom-left
            CGPoint(x: _cropRect.maxX, y: _cropRect.maxY)  // Bottom-right
        ]
        
        for corner in corners {
            let isLeft = corner.x == _cropRect.minX
            let isTop = corner.y == _cropRect.minY
            
            // Horizontal line
            let hStart = CGPoint(
                x: isLeft ? corner.x : corner.x - cornerLength,
                y: corner.y
            )
            let hEnd = CGPoint(
                x: isLeft ? corner.x + cornerLength : corner.x,
                y: corner.y
            )
            
            // Vertical line
            let vStart = CGPoint(
                x: corner.x,
                y: isTop ? corner.y : corner.y - cornerLength
            )
            let vEnd = CGPoint(
                x: corner.x,
                y: isTop ? corner.y + cornerLength : corner.y
            )
            
            context.move(to: hStart)
            context.addLine(to: hEnd)
            context.move(to: vStart)
            context.addLine(to: vEnd)
            context.strokePath()
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            activeHandle = getHandleAt(location)
            lastPanPoint = location
            
        case .changed:
            let deltaX = location.x - lastPanPoint.x
            let deltaY = location.y - lastPanPoint.y
            
            var newRect = _cropRect
            let minSize: CGFloat = 50.0
            
            switch activeHandle {
            case .move:
                newRect.origin.x = max(0, min(bounds.width - newRect.width, newRect.origin.x + deltaX))
                newRect.origin.y = max(0, min(bounds.height - newRect.height, newRect.origin.y + deltaY))
                
            case .topLeft:
                let newWidth = newRect.maxX - max(0, min(newRect.maxX - minSize, location.x))
                let newHeight = newRect.maxY - max(0, min(newRect.maxY - minSize, location.y))
                newRect = CGRect(
                    x: newRect.maxX - newWidth,
                    y: newRect.maxY - newHeight,
                    width: newWidth,
                    height: newHeight
                )
                
            case .topRight:
                let newWidth = max(minSize, min(bounds.width - newRect.minX, location.x - newRect.minX))
                let newHeight = newRect.maxY - max(0, min(newRect.maxY - minSize, location.y))
                newRect = CGRect(
                    x: newRect.minX,
                    y: newRect.maxY - newHeight,
                    width: newWidth,
                    height: newHeight
                )
                
            case .bottomLeft:
                let newWidth = newRect.maxX - max(0, min(newRect.maxX - minSize, location.x))
                let newHeight = max(minSize, min(bounds.height - newRect.minY, location.y - newRect.minY))
                newRect = CGRect(
                    x: newRect.maxX - newWidth,
                    y: newRect.minY,
                    width: newWidth,
                    height: newHeight
                )
                
            case .bottomRight:
                newRect.size.width = max(minSize, min(bounds.width - newRect.minX, location.x - newRect.minX))
                newRect.size.height = max(minSize, min(bounds.height - newRect.minY, location.y - newRect.minY))
                
            case .top:
                let newHeight = newRect.maxY - max(0, min(newRect.maxY - minSize, location.y))
                newRect = CGRect(
                    x: newRect.minX,
                    y: newRect.maxY - newHeight,
                    width: newRect.width,
                    height: newHeight
                )
                
            case .bottom:
                newRect.size.height = max(minSize, min(bounds.height - newRect.minY, location.y - newRect.minY))
                
            case .left:
                let newWidth = newRect.maxX - max(0, min(newRect.maxX - minSize, location.x))
                newRect = CGRect(
                    x: newRect.maxX - newWidth,
                    y: newRect.minY,
                    width: newWidth,
                    height: newRect.height
                )
                
            case .right:
                newRect.size.width = max(minSize, min(bounds.width - newRect.minX, location.x - newRect.minX))
                
            case .none:
                break
            }
            
            _cropRect = newRect
            lastPanPoint = location
            setNeedsDisplay()
            
        default:
            activeHandle = .none
        }
    }
    
    private func getHandleAt(_ point: CGPoint) -> Handle {
        let handleRect = { (center: CGPoint) -> CGRect in
            CGRect(
                x: center.x - self.handleSize/2,
                y: center.y - self.handleSize/2,
                width: self.handleSize,
                height: self.handleSize
            )
        }
        
        // Check corners first (they have priority)
        if handleRect(CGPoint(x: _cropRect.minX, y: _cropRect.minY)).contains(point) { return .topLeft }
        if handleRect(CGPoint(x: _cropRect.maxX, y: _cropRect.minY)).contains(point) { return .topRight }
        if handleRect(CGPoint(x: _cropRect.minX, y: _cropRect.maxY)).contains(point) { return .bottomLeft }
        if handleRect(CGPoint(x: _cropRect.maxX, y: _cropRect.maxY)).contains(point) { return .bottomRight }
        
        // Check edges
        if handleRect(CGPoint(x: _cropRect.midX, y: _cropRect.minY)).contains(point) { return .top }
        if handleRect(CGPoint(x: _cropRect.midX, y: _cropRect.maxY)).contains(point) { return .bottom }
        if handleRect(CGPoint(x: _cropRect.minX, y: _cropRect.midY)).contains(point) { return .left }
        if handleRect(CGPoint(x: _cropRect.maxX, y: _cropRect.midY)).contains(point) { return .right }
        
        // Check if inside crop area for moving
        if _cropRect.contains(point) { return .move }
        
        return .none
    }
}
