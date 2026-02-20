import SwiftUI

struct SignatureView: View {
    @Binding var signatureImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    @State private var lines: [Line] = []
    
    struct Line {
        var points: [CGPoint]
        var color: Color = .black
    }

    var body: some View {
        NavigationView {
            VStack {
                Text("Draw your signature")
                    .font(.headline)
                    .padding()
                
                Canvas { context, size in
                    for line in lines {
                        var path = Path()
                        path.addLines(line.points)
                        context.stroke(path, with: .color(line.color), lineWidth: 3)
                    }
                }
                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged({ value in
                        let newPoint = value.location
                        if value.translation.width + value.translation.height == 0 {
                            lines.append(Line(points: [newPoint]))
                        } else {
                            let index = lines.count - 1
                            if index >= 0 {
                                lines[index].points.append(newPoint)
                            }
                        }
                    })
                )
                .background(Color.white)
                .border(Color.gray, width: 2)
                .padding()
                
                HStack {
                    Button("Clear") {
                        lines.removeAll()
                    }
                    .buttonStyle(.bordered)
                    .padding()
                    
                    Spacer()
                    
                    Button("Save") {
                        let image = renderImage()
                        signatureImage = image
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .navigationTitle("Signature")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    @MainActor
    private func renderImage() -> UIImage {
        let renderer = ImageRenderer(content: Canvas { context, size in
            for line in lines {
                var path = Path()
                path.addLines(line.points)
                context.stroke(path, with: .color(line.color), lineWidth: 3)
            }
        }.frame(width: 300, height: 150).background(Color.clear))
        
        if let uiImage = renderer.uiImage {
            return uiImage
        }
        return UIImage()
    }
}
