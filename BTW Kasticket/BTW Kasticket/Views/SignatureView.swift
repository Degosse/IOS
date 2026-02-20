import SwiftUI

struct SignatureView: View {
    @Binding var signatureImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    @State private var lines: [Line] = []
    @State private var canvasSize: CGSize = .zero
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Draw your signature below")
                    .foregroundColor(.secondary)
                    .padding()
                
                GeometryReader { geometry in
                    Canvas { context, size in
                        for line in lines {
                            var path = Path()
                            path.addLines(line.points)
                            context.stroke(path, with: .color(.black), lineWidth: line.lineWidth)
                        }
                    }
                    .background(Color.white) // Force white to see black ink in Dark Mode
                    .cornerRadius(10)
                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged({ value in
                            let newPoint = value.location
                            if value.translation.width == 0 && value.translation.height == 0 {
                                lines.append(Line(points: [newPoint]))
                            } else {
                                let index = lines.count - 1
                                lines[index].points.append(newPoint)
                            }
                        })
                    )
                    .onAppear {
                        self.canvasSize = geometry.size
                    }
                    .onChange(of: geometry.size) { newSize in
                        self.canvasSize = newSize
                    }
                }
                .padding()
                
                HStack {
                    Button(role: .destructive) {
                        lines.removeAll()
                    } label: {
                        Text("Clear")
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button {
                        saveSignature()
                        dismiss()
                    } label: {
                        Text("Save Signature")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Signature")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
    
    private func saveSignature() {
        let targetSize = canvasSize == .zero ? CGSize(width: 400, height: 200) : canvasSize
        
        let renderer = ImageRenderer(content: Canvas { context, size in
            for line in lines {
                var path = Path()
                path.addLines(line.points)
                // Draw a slightly thicker line for PDF legibility
                context.stroke(path, with: .color(.black), lineWidth: line.lineWidth * 1.5)
            }
        }.frame(width: targetSize.width, height: targetSize.height))
        
        renderer.scale = UIScreen.main.scale
        
        if let uiImage = renderer.uiImage {
            self.signatureImage = uiImage
        }
    }
}

struct Line {
    var points = [CGPoint]()
    var padding: CGFloat = 0
    var lineWidth: CGFloat = 3.0
}
