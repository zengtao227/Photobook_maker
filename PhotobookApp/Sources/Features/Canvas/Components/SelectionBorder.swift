import SwiftUI

struct SelectionBorder: View {
    @Binding var frame: CGRect
    @Binding var rotation: Double
    var lockAspectRatio: Bool = true
    var onCommitFrame: () -> Void
    var onCommitRotation: () -> Void
    
    @State private var innerInitialFrame: CGRect? = nil
    @State private var innerInitialRotation: Double? = nil
    
    private var normalizedRotation: Double {
        var r = rotation.truncatingRemainder(dividingBy: 360)
        if r > 180 { r -= 360 }
        if r < -180 { r += 360 }
        return r
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .stroke(Color.blue, lineWidth: 2)
                .allowsHitTesting(false)
            
            VStack {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 2, height: 20)
                    .offset(y: -20)
                Spacer()
            }
            .allowsHitTesting(false)
            
            rotationHandle
            handles
        }
    }
    
    private var rotationHandle: some View {
        VStack(spacing: 4) {
            if innerInitialRotation != nil || abs(rotation) > 0.1 {
                Text(String(format: "%.1f°", normalizedRotation))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue))
            }
            
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                .frame(width: 24, height: 24)
                .background(Color.black.opacity(0.001).frame(width: 44, height: 44))
        }
        .offset(y: -(frame.height/2 + 32 + (innerInitialRotation != nil || abs(rotation) > 0.1 ? 10 : 0)))
        .gesture(
            DragGesture(coordinateSpace: .global)
                .onChanged { value in
                    if innerInitialRotation == nil {
                        innerInitialRotation = rotation
                    }
                    let sensitivity: Double = 0.8
                    let delta = value.translation.width * sensitivity
                    self.rotation = (innerInitialRotation ?? 0) + delta
                }
                .onEnded { _ in
                    innerInitialRotation = nil
                    onCommitRotation()
                }
        )
    }
    
    private var handles: some View {
        ZStack {
            handle(alignment: .topLeading)
            handle(alignment: .topTrailing)
            handle(alignment: .bottomLeading)
            handle(alignment: .bottomTrailing)
        }
    }
    
    private func handle(alignment: Alignment) -> some View {
        Circle()
            .fill(Color.white)
            .shadow(radius: 2)
            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
            .frame(width: 14, height: 14)
            .background(Color.black.opacity(0.001).frame(width: 40, height: 40))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .offset(x: offset(for: alignment).width, y: offset(for: alignment).height)
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        if innerInitialFrame == nil {
                            innerInitialFrame = frame
                        }
                        guard let startFrame = innerInitialFrame else { return }
                        
                        // Use global translation to avoid jitter
                        let drag = CGSize(
                            width: value.translation.width,
                            height: value.translation.height
                        )
                        updateFrame(startFrame: startFrame, drag: drag, alignment: alignment)
                    }
                    .onEnded { _ in
                        innerInitialFrame = nil
                        onCommitFrame()
                    }
            )
    }
    
    private func offset(for alignment: Alignment) -> CGSize {
        let push: CGFloat = 6
        switch alignment {
        case .topLeading: return CGSize(width: -push, height: -push)
        case .topTrailing: return CGSize(width: push, height: -push)
        case .bottomLeading: return CGSize(width: -push, height: push)
        case .bottomTrailing: return CGSize(width: push, height: push)
        default: return .zero
        }
    }
    
    private func updateFrame(startFrame: CGRect, drag: CGSize, alignment: Alignment) {
        let ar = startFrame.width / startFrame.height
        let minSize: CGFloat = 30
        var newFrame = startFrame
        
        if lockAspectRatio {
            switch alignment {
            case .bottomTrailing:
                let newW = max(minSize, startFrame.width + drag.width)
                let newH = newW / ar
                newFrame.size = CGSize(width: newW, height: newH)
                
            case .topTrailing:
                let newW = max(minSize, startFrame.width + drag.width)
                let newH = newW / ar
                newFrame.size = CGSize(width: newW, height: newH)
                newFrame.origin.y = startFrame.maxY - newH
                
            case .bottomLeading:
                let newW = max(minSize, startFrame.width - drag.width)
                let newH = newW / ar
                newFrame.size = CGSize(width: newW, height: newH)
                newFrame.origin.x = startFrame.maxX - newW
                
            case .topLeading:
                let newW = max(minSize, startFrame.width - drag.width)
                let newH = newW / ar
                newFrame.size = CGSize(width: newW, height: newH)
                newFrame.origin.x = startFrame.maxX - newW
                newFrame.origin.y = startFrame.maxY - newH
                
            default: break
            }
        } else {
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
        }
        
        if newFrame.size.width >= minSize && newFrame.size.height >= minSize {
            self.frame = newFrame
        }
    }
}
