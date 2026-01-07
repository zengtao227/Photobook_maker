import SwiftUI

struct SelectionOverlay: ViewModifier {
    let isSelected: Bool
    @Binding var frame: CGRect
    let minSize: CGSize = CGSize(width: 20, height: 20)
    
    // Internal state to track the drag start
    @State private var initialFrame: CGRect? = nil
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .frame(width: max(frame.width, 0), height: max(frame.height, 0))
                .position(x: frame.midX, y: frame.midY)
            
            if isSelected {
                // Selection Border
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
                    .allowsHitTesting(false) // Let taps pass through
                
                // Resize Handles
                handles
            }
        }
    }
    
    var handles: some View {
        ZStack {
            handle(alignment: .topLeading)
            handle(alignment: .topTrailing)
            handle(alignment: .bottomLeading)
            handle(alignment: .bottomTrailing)
        }
    }
    
    func handle(alignment: Alignment) -> some View {
        Circle()
            .fill(Color.white)
            .shadow(radius: 1)
            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
            .frame(width: 12, height: 12)
            .position(
                x: getPosition(for: alignment).x,
                y: getPosition(for: alignment).y
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if initialFrame == nil {
                            initialFrame = frame
                        }
                        
                        guard let startFrame = initialFrame else { return }
                        updateFrame(startFrame: startFrame, drag: value.translation, alignment: alignment)
                    }
                    .onEnded { _ in
                        initialFrame = nil
                    }
            )
    }
    
    func getPosition(for alignment: Alignment) -> CGPoint {
        switch alignment {
        case .topLeading:
            return CGPoint(x: frame.minX, y: frame.minY)
        case .topTrailing:
            return CGPoint(x: frame.maxX, y: frame.minY)
        case .bottomLeading:
            return CGPoint(x: frame.minX, y: frame.maxY)
        case .bottomTrailing:
            return CGPoint(x: frame.maxX, y: frame.maxY)
        default:
            return .zero
        }
    }
    
    func updateFrame(startFrame: CGRect, drag: CGSize, alignment: Alignment) {
        var newFrame = startFrame
        
        switch alignment {
        case .topLeading:
            newFrame.origin.x += drag.width
            newFrame.origin.y += drag.height
            newFrame.size.width -= drag.width
            newFrame.size.height -= drag.height
        case .topTrailing:
            newFrame.origin.y += drag.height
            newFrame.size.width += drag.width
            newFrame.size.height -= drag.height
        case .bottomLeading:
            newFrame.origin.x += drag.width
            newFrame.size.width -= drag.width
            newFrame.size.height += drag.height
        case .bottomTrailing:
            newFrame.size.width += drag.width
            newFrame.size.height += drag.height
        default: break
        }
        
        // Enforce min size
        if newFrame.size.width > minSize.width && newFrame.size.height > minSize.height {
            self.frame = newFrame
        }
    }
}
