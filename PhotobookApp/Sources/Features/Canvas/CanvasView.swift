import SwiftUI

struct CanvasView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(BookContext.self) private var bookContext
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Pattern
                if themeManager.currentMode == .studio {
                    Color(white: 0.95) // Light gray desk background
                } else {
                    Color.clear
                }
                
                // Content Area
                VStack(spacing: 20) {
                    // Title / Info
                    VStack(spacing: 4) {
                        Text("Current Spread")
                            .font(.headline)
                            .foregroundColor(themeManager.theme.secondaryTextColor)
                        Text("\(bookContext.pageSize.rawValue) • \(bookContext.dimensionString)")
                            .font(.caption)
                            .padding(6)
                            .background(themeManager.theme.searchFieldColor)
                            .cornerRadius(4)
                            .foregroundColor(themeManager.theme.textColor)
                    }
                    
                    // The Book Spread (Left + Right Page)
                    // Logic: We assume the settings (e.g. A6) apply to a SINGLE PAGE.
                    // So a spread is 2x Width.
                    let singlePageSize = bookContext.currentSize
                    let spreadAspectRatio = (singlePageSize.width * 2) / singlePageSize.height
                    
                    ZStack {
                        // Shadow (Book Lift)
                        Color.clear
                            .aspectRatio(spreadAspectRatio, contentMode: .fit)
                            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                        
                        HStack(spacing: 0) {
                            // Left Page
                            BookPage(isLeft: true, size: singlePageSize)
                            
                            // Spine (Gutter) check
                            Rectangle()
                                .fill(LinearGradient(
                                    colors: [.black.opacity(0.1), .clear, .black.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .frame(width: 2)
                                .zIndex(1)
                            
                            // Right Page
                            BookPage(isLeft: false, size: singlePageSize)
                        }
                        .aspectRatio(spreadAspectRatio, contentMode: .fit)
                    }
                    .padding(40) // Padding from window edges
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct BookPage: View {
    let isLeft: Bool
    let size: CGSize
    @Environment(ThemeManager.self) private var themeManager
    @Environment(EditorState.self) private var editorState
    @EnvironmentObject var photoStore: PhotoStore // Needed to look up Photo by URL
    
    var pageModel: PageModel {
        isLeft ? editorState.leftPage : editorState.rightPage
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // MARK: - Background Layer (Non-interactive)
                ZStack {
                    // Paper
                    Rectangle()
                        .fill(Color.white)
                    
                    // Grid Lines (Helper)
                    GridPattern()
                        .stroke(Color.blue.opacity(0.1), lineWidth: 0.5)
                    
                    // Inner Shadow (Simulate binding curve)
                    HStack {
                        if !isLeft {
                            LinearGradient(
                                colors: [.black.opacity(0.15), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 20)
                            Spacer()
                        } else {
                            Spacer()
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.15)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 20)
                        }
                    }
                }
                .allowsHitTesting(false) // CRITICAL: Let clicks pass through to layers
                
                // MARK: - Interactive Layers (On Top)
                ForEach(pageModel.layers) { wrapper in
                    InteractiveLayer(wrapper: wrapper, isLeftPage: isLeft)
                        .zIndex(1000) // Force layers to be on top
                }
                
                // MARK: - Tap to Deselect (Transparent overlay)
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("DEBUG: Tapped background, deselecting")
                        editorState.deselect()
                    }
                    .allowsHitTesting(true)
                    .zIndex(-1) // Behind layers
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            // MARK: - Keyboard Shortcuts
            .focusable() // CRITICAL: Enable keyboard input
            .onKeyPress(.delete) {
                print("DEBUG: Delete key pressed")
                editorState.deleteSelectedLayer()
                return .handled
            }
            .onKeyPress(.deleteForward) {
                print("DEBUG: Delete forward key pressed")
                editorState.deleteSelectedLayer()
                return .handled
            }
            // MARK: - Drop Handling
            .dropDestination(for: URL.self) { items, location in
                guard let url = items.first else { return false }
                
                if let photo = photoStore.allPhotos.first(where: { $0.url == url }) {
                    editorState.addPhotoLayer(photo: photo, isLeftPage: isLeft, center: location)
                    return true
                }
                return false
            }
        }
    }
}

struct InteractiveLayer: View {
    let wrapper: AnyLayer
    let isLeftPage: Bool
    @Environment(EditorState.self) private var editorState
    
    // MARK: - Transient Gesture State
    @State private var transientFrame: CGRect? = nil
    @State private var transientRotation: Double? = nil // Transient rotation state
    
    private func currentDisplayFrame(for layer: PhotoLayer) -> CGRect {
        transientFrame ?? layer.frame
    }
    
    private func currentRotation(for layer: PhotoLayer) -> Double {
        transientRotation ?? layer.rotation
    }
    
    private var currentLayer: (any LayerProtocol)? {
        let _ = editorState.updateCounter
        let pageModel = isLeftPage ? editorState.leftPage : editorState.rightPage
        return pageModel.layers.first(where: { $0.id == wrapper.id })?.layer
    }
    
    var body: some View {
        if let photoLayer = currentLayer as? PhotoLayer {
            let displayFrame = currentDisplayFrame(for: photoLayer)
            let rotation = currentRotation(for: photoLayer)
            let isSelected = editorState.selectedLayerId == photoLayer.id
            
            ZStack {
                // 1. The Photo Content
                PhotoLayerElement(layer: photoLayer)
                    .frame(width: displayFrame.width, height: displayFrame.height)
                    .clipped()
                    .contentShape(Rectangle()) // Hit test for move gesture
                
                // 2. The Selection Border & Handles (Sibling)
                if isSelected {
                    SelectionBorder(
                        frame: Binding(
                            get: { displayFrame },
                            set: { self.transientFrame = $0 }
                        ),
                        rotation: Binding(
                            get: { rotation },
                            set: { self.transientRotation = $0 }
                        ),
                        onCommitFrame: {
                            if let finalFrame = transientFrame {
                                editorState.updateLayerFrame(photoLayer.id, newFrame: finalFrame)
                                transientFrame = nil
                            }
                        },
                        onCommitRotation: {
                            if let finalRot = transientRotation {
                                editorState.updateLayerRotation(photoLayer.id, newRotation: finalRot)
                                transientRotation = nil
                            }
                        }
                    )
                    .frame(width: displayFrame.width, height: displayFrame.height)
                }
            }
            // Center point of the layer
            .position(x: displayFrame.midX, y: displayFrame.midY) 
            // APPLY ROTATION HERE - Affects both visual and hit testing coordinate space?
            // SwiftUI .rotationEffect rotates the view visual but maintains the original frame for layout.
            // However, gestures *inside* the view (like Tap) rotate with it.
            // Gestures *on* the view (like Drag attached relative to parent) might need coordinate conversion.
            // Since our DragGesture handles are INSIDE the rotated view (ZStack), they should rotate with it.
            // BUT the 'DragGesture' translation values will be in the LOCAL coordinate space of the rotated view?
            // No, DragGesture usually reports in global or parent space depending on setup.
            // Let's stick to standard SwiftUI behavior: Rotate the whole container.
            .rotationEffect(Angle(degrees: rotation), anchor: .center)
            
            // MARK: - Gestures
            
            // 1. Tap to Select
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        print("DEBUG: Layer \(photoLayer.id) tapped")
                        editorState.selectLayer(photoLayer.id)
                    }
            )
            
            // 2. Drag to Move (Only if selected)
            // Note: If rotated, the x/y translation needs to be rotated matches the parent coordinate space??
            // Wait, if we use .position() we are placing in PARENT space.
            // If we rotate the view, the axes rotate. 
            // If the user drags UP on screen, they expect the layer to move UP on screen (Parent Y-).
            // But if layer is rotated 90deg, "UP" in local space is "LEFT".
            // DragGesture translation is in the coordinate space of the view it is attached to.
            // If attached HERE (outside rotationEffect), it is in parent space.
            // If attached INSIDE (before rotationEffect), it is in local space.
            // We want MOVE to be in PARENT space (Screen-aligned).
            // So we attach DragGesture AFTER rotation.
            // BUT SwiftUI gesture composition is tricky order-wise.
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        guard isSelected else { return }
                        
                        // Initialize transient frame if needed
                        if transientFrame == nil {
                            transientFrame = photoLayer.frame
                        }
                        
                        let originFrame = photoLayer.frame
                        var newFrame = originFrame
                        // Since we are moving the .position() (Parent Space), we just add the drag translation (Parent Space)
                        newFrame.origin.x += value.translation.width
                        newFrame.origin.y += value.translation.height
                        
                        transientFrame = newFrame
                    }
                    .onEnded { _ in
                        guard isSelected else { return }
                        if let finalFrame = transientFrame {
                            editorState.updateLayerFrame(photoLayer.id, newFrame: finalFrame)
                            transientFrame = nil
                        }
                    }
            )
            .contextMenu {
                // 图层层级调整
                Button {
                    editorState.moveLayerToFront(photoLayer.id)
                } label: {
                    Label("移到最前", systemImage: "square.3.layers.3d.top.filled")
                }
                
                Button {
                    editorState.moveLayerForward(photoLayer.id)
                } label: {
                    Label("前移一层", systemImage: "arrow.up.square")
                }
                
                Button {
                    editorState.moveLayerBackward(photoLayer.id)
                } label: {
                    Label("后移一层", systemImage: "arrow.down.square")
                }
                
                Button {
                    editorState.moveLayerToBack(photoLayer.id)
                } label: {
                    Label("移到最后", systemImage: "square.3.layers.3d.bottom.filled")
                }
                
                Divider()
                
                // 删除
                Button(role: .destructive) {
                    editorState.deleteSelectedLayer()
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
    }
}

struct SelectionBorder: View {
    @Binding var frame: CGRect
    @Binding var rotation: Double
    var onCommitFrame: () -> Void
    var onCommitRotation: () -> Void
    
    @State private var innerInitialFrame: CGRect? = nil
    @State private var innerInitialRotation: Double? = nil
    
    var body: some View {
        ZStack {
            // Blue Border
            Rectangle()
                .stroke(Color.blue, lineWidth: 2)
                .allowsHitTesting(false)
            
            // Top Rotation Handle Stick
            VStack {
                 Rectangle()
                    .fill(Color.blue)
                    .frame(width: 2, height: 20)
                    .offset(y: -20)
                Spacer()
            }
            .allowsHitTesting(false)
            
            // Rotation Handle Knob
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                .frame(width: 20, height: 20)
                // Expanded Hit Area
                .background(Color.black.opacity(0.001).frame(width: 44, height: 44))
                .offset(y: -(frame.height/2 + 30)) // Stick out 30px from center
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if innerInitialRotation == nil {
                                innerInitialRotation = rotation
                            }
                            // Calculate angle logic
                            // We need the center of the layer in screen coordinates vs touch location.
                            // Simplified: Dragging Left/Right rotates? Or following circular path?
                            // Circular path is best.
                            // Vector from Center to Touch.
                            let vector = CGVector(dx: value.location.x, dy: value.location.y) 
                            // *Wait*: value.location is local to the Handle view? Or the ZStack? 
                            // It's local to the Circle if attached there.
                            // We need it relative to the Layer Center.
                            // Let's assume standard rotation: dx drives rotation for simplicity or use atan2.
                            
                            // Better approach for knob: Simple "drag horizontal to rotate" is confusing.
                            // Best approach: Use ATAN2. 
                            // Current touch point relative to center of layer.
                            // Since this handle is part of the rotated view, its coordinate system ROTATES.
                            // This makes calculation hard.
                            
                            // ALTERNATIVE: Don't rotate the SelectionBorder's HANDLES container? 
                            // No, they must follow the rect.
                            
                            // Simple heuristic: Delta X drives rotation speed.
                            let sensitivity: Double = 0.5
                            let delta = value.translation.width * sensitivity
                            let start = innerInitialRotation ?? 0
                            self.rotation = start + delta
                        }
                        .onEnded { _ in
                            innerInitialRotation = nil
                            onCommitRotation()
                        }
                )
            
            // Resize Handles
            handles
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
            .background(Color.black.opacity(0.001).frame(width: 44, height: 44))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .offset(x: offset(for: alignment).width, y: offset(for: alignment).height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if innerInitialFrame == nil {
                            innerInitialFrame = frame
                        }
                        guard let startFrame = innerInitialFrame else { return }
                        // NOTE: If the layer is rotated, value.translation is in ROTATED local space?
                        // If we are just resizing the 'width/height' property, we are effectively resizing in Local Space.
                        // So standard logic works!
                        updateFrame(startFrame: startFrame, drag: value.translation, alignment: alignment)
                    }
                    .onEnded { _ in
                        innerInitialFrame = nil
                        onCommitFrame()
                    }
            )
    }
    
    func offset(for alignment: Alignment) -> CGSize {
        let push: CGFloat = 6
        switch alignment {
        case .topLeading: return CGSize(width: -push, height: -push)
        case .topTrailing: return CGSize(width: push, height: -push)
        case .bottomLeading: return CGSize(width: -push, height: push)
        case .bottomTrailing: return CGSize(width: push, height: push)
        default: return .zero
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
        if newFrame.size.width > 20 && newFrame.size.height > 20 {
            self.frame = newFrame
        }
    }
}

struct PhotoLayerElement: View {
    let layer: PhotoLayer
    
    var body: some View {
        AsyncImage(url: layer.photoUrl) { image in
            image.resizable()
                .aspectRatio(contentMode: .fill) // Fill the frame
        } placeholder: {
            Color.gray.opacity(0.3)
        }
        .clipped()
        .allowsHitTesting(false) // Pass interaction to container
    }
}


// Simple grid pattern helper
struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 20
        
        for x in stride(from: 0, to: rect.width, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        for y in stride(from: 0, to: rect.height, by: spacing) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        return path
    }
}
