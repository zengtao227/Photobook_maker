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
            // MARK: - Full Screen Crop Modal
            // We use fullScreenCover to provide a dedicated editing environment
            // mimicking standard tools like Mantis or Apple Photos.
            // MARK: - Crop Modal
            // Use .sheet for macOS compatibility
            .sheet(item: Binding(
                get: {
                    if let id = editorState.croppingLayerId {
                        // Manual Lookup since helper is missing
                        if let found = editorState.leftPage.layers.first(where: { $0.id == id }) {
                            return found
                        }
                        if let found = editorState.rightPage.layers.first(where: { $0.id == id }) {
                            return found
                        }
                    }
                    return nil
                },
                set: { (wrapper: AnyLayer?) in
                    if wrapper == nil {
                        editorState.endCropping()
                    }
                }
            )) { wrapper in
                if let photoLayer = wrapper.layer as? PhotoLayer {
                    CropEditor(
                        layer: photoLayer,
                        onSave: { scale, offset, newFrame, cropRotation, newNormalizedRect in
                            // 1. Update Layout
                            if let frame = newFrame {
                                editorState.updateLayerFrame(photoLayer.id, newFrame: frame)
                            }
                            // 2. Update Crop & INTERNAL Rotation
                            editorState.updateLayerCrop(
                                id: photoLayer.id, 
                                scale: scale, 
                                offset: offset, 
                                normalizedRect: newNormalizedRect,
                                cropRotation: cropRotation
                            )
                            // 3. Close
                            editorState.endCropping()
                        },
                        onCancel: {
                            editorState.endCropping()
                        }
                    )
                } 
            }
            // MARK: - Filter Modal
            .sheet(item: Binding(
                get: {
                    if let id = editorState.filteringLayerId {
                        if let found = editorState.leftPage.layers.first(where: { $0.id == id }) {
                            return found
                        }
                        if let found = editorState.rightPage.layers.first(where: { $0.id == id }) {
                            return found
                        }
                    }
                    return nil
                },
                set: { (wrapper: AnyLayer?) in
                    if wrapper == nil {
                        editorState.endFiltering()
                    }
                }
            )) { wrapper in
                if let photoLayer = wrapper.layer as? PhotoLayer {
                    FilterEditor(
                        layer: photoLayer,
                        onSave: { filterType, brightness, contrast, saturation in
                            editorState.updateLayerFilter(
                                id: photoLayer.id,
                                filterType: filterType,
                                brightness: brightness,
                                contrast: contrast,
                                saturation: saturation
                            )
                            editorState.endFiltering()
                        },
                        onCancel: {
                            editorState.endFiltering()
                        }
                    )
                }
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

struct PhotoLayerElement: View {
    let layer: PhotoLayer
    
    @State private var filteredImage: NSImage?
    
    var body: some View {
        Group {
            if let filtered = filteredImage {
                // Use pre-filtered image
                Image(nsImage: filtered)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .rotationEffect(.degrees(layer.cropRotation))
                    .scaleEffect(layer.cropScale)
                    .offset(layer.cropOffset)
            } else {
                // Fallback to async loading
                AsyncImage(url: layer.photoUrl) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .rotationEffect(.degrees(layer.cropRotation))
                        .scaleEffect(layer.cropScale)
                        .offset(layer.cropOffset)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
            }
        }
        .frame(width: layer.frame.width, height: layer.frame.height)
        .contentShape(Rectangle())
        .clipped()
        // Apply border
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color(hex: layer.borderColorHex) ?? .white, lineWidth: layer.borderWidth)
        )
        // Apply shadow
        .shadow(
            color: Color.black.opacity(layer.shadowOpacity),
            radius: layer.shadowRadius,
            x: 0,
            y: layer.shadowRadius / 3
        )
        .allowsHitTesting(false)
        .onAppear {
            loadFilteredImage()
        }
        .onChange(of: layer.filterType) { _, _ in loadFilteredImage() }
        .onChange(of: layer.brightness) { _, _ in loadFilteredImage() }
        .onChange(of: layer.contrast) { _, _ in loadFilteredImage() }
        .onChange(of: layer.saturation) { _, _ in loadFilteredImage() }
    }
    
    private func loadFilteredImage() {
        // Only apply filter if needed
        guard layer.filterType != .none || layer.brightness != 0 || layer.contrast != 1 || layer.saturation != 1 else {
            filteredImage = nil
            return
        }
        
        Task {
            filteredImage = await generateFilteredImage(
                from: layer.photoUrl,
                filter: layer.filterType,
                brightness: layer.brightness,
                contrast: layer.contrast,
                saturation: layer.saturation
            )
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
            let isCropping = editorState.croppingLayerId == photoLayer.id
            
            ZStack {
                if isCropping {
                    // CROP MODE ACTIVE (Handled by Global FullScreenCover)
                    // We just show a placeholder or the original image dimmed
                    PhotoLayerElement(layer: photoLayer)
                        .frame(width: displayFrame.width, height: displayFrame.height)
                        .clipped()
                        .opacity(0.3) // Dim it to show it's being edited elsewhere
                        .allowsHitTesting(false)
                } else {
                    // NORMAL MODE
                    
                    // 1. The Photo Content
                    PhotoLayerElement(layer: photoLayer)
                        .frame(width: displayFrame.width, height: displayFrame.height)
                        .clipped() // Clip in normal mode
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
            }
            // Center point of the layer
            .position(x: displayFrame.midX, y: displayFrame.midY) 
            .rotationEffect(Angle(degrees: rotation), anchor: .center)
            .zIndex(isCropping ? 9999 : (Double(photoLayer.zIndex) + (isSelected ? 100 : 0)))
            
            // MARK: - Gestures
            
            // Priority: Double Tap > Drag > Single Tap
            
            // 1. Double Tap to Crop (High Priority)
            .highPriorityGesture(
                TapGesture(count: 2)
                    .onEnded {
                        editorState.startCropping(photoLayer.id)
                    }
            )
            
            // 2. Drag to Move (Normal Priority, but blocked by high priority double tap if it fails?)
            // Actually, DragGesture usually overrides Tap. 
            // So we leave Drag as standard .gesture
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        guard isSelected, !isCropping else { return }
                        
                        if transientFrame == nil {
                            transientFrame = photoLayer.frame
                        }
                        
                        let originFrame = photoLayer.frame
                        var newFrame = originFrame
                        newFrame.origin.x += value.translation.width
                        newFrame.origin.y += value.translation.height
                        
                        transientFrame = newFrame
                    }
                    .onEnded { _ in
                        guard isSelected, !isCropping else { return }
                        if let finalFrame = transientFrame {
                            editorState.updateLayerFrame(photoLayer.id, newFrame: finalFrame)
                            transientFrame = nil
                        }
                    }
            )
            
            // 3. Single Tap to Select (Simultaneous)
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        if !isCropping {
                            editorState.selectLayer(photoLayer.id)
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
                
                // Crop
                 Button {
                    editorState.startCropping(photoLayer.id)
                } label: {
                    Label("裁剪", systemImage: "crop")
                }
                
                // Filter
                Button {
                    editorState.startFiltering(photoLayer.id)
                } label: {
                    Label("滤镜", systemImage: "camera.filters")
                }
                
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
    var lockAspectRatio: Bool = true // Photos should scale proportionally
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
                .frame(width: 24, height: 24)
                .background(Color.black.opacity(0.001).frame(width: 44, height: 44))
                .offset(y: -(frame.height/2 + 32)) 
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { value in
                            if innerInitialRotation == nil {
                                innerInitialRotation = rotation
                            }
                            // Simple rotation logic: Horizontal drag rotates
                            let sensitivity: Double = 0.8
                            let delta = value.translation.width * sensitivity
                            self.rotation = (innerInitialRotation ?? 0) + delta
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
            .shadow(radius: 2)
            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
            .frame(width: 14, height: 14)
            .background(Color.black.opacity(0.001).frame(width: 40, height: 40))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .offset(x: offset(for: alignment).width, y: offset(for: alignment).height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if innerInitialFrame == nil {
                            innerInitialFrame = frame
                        }
                        guard let startFrame = innerInitialFrame else { return }
                        updateFrame(startFrame: startFrame, drag: value.translation, alignment: alignment)
                    }
                    .onEnded { _ in
                        innerInitialFrame = nil
                        onCommitFrame()
                    }
            )
    }
    
    func offset(for alignment: Alignment) -> CGSize {
        let push: CGFloat = 6 // Push handles slightly outward
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
        let ar = startFrame.width / startFrame.height
        
        if lockAspectRatio {
            // Proportional scaling
            let multiplier: CGFloat
            switch alignment {
            case .bottomTrailing:
                multiplier = 1.0 + (max(drag.width / startFrame.width, drag.height / startFrame.height))
                newFrame.size.width = startFrame.width * multiplier
                newFrame.size.height = newFrame.size.width / ar
                // Origin remains same
            case .topLeading:
                multiplier = 1.0 - (max(-drag.width / startFrame.width, -drag.height / startFrame.height))
                let newW = startFrame.width * multiplier
                let newH = newW / ar
                newFrame.origin.x = startFrame.maxX - newW
                newFrame.origin.y = startFrame.maxY - newH
                newFrame.size.width = newW
                newFrame.size.height = newH
            case .topTrailing:
                multiplier = 1.0 + (max(drag.width / startFrame.width, -drag.height / startFrame.height))
                let newW = startFrame.width * multiplier
                let newH = newW / ar
                newFrame.origin.y = startFrame.maxY - newH
                newFrame.size.width = newW
                newFrame.size.height = newH
            case .bottomLeading:
                multiplier = 1.0 + (max(-drag.width / startFrame.width, drag.height / startFrame.height))
                let newW = startFrame.width * multiplier
                let newH = newW / ar
                newFrame.origin.x = startFrame.maxX - newW
                newFrame.size.width = newW
                newFrame.size.height = newH
            default: break
            }
        } else {
            // Freeform (not used for photos)
            switch alignment {
            case .topLeading:
                newFrame.origin.x += drag.width; newFrame.origin.y += drag.height
                newFrame.size.width -= drag.width; newFrame.size.height -= drag.height
            case .topTrailing:
                newFrame.origin.y += drag.height; newFrame.size.width += drag.width; newFrame.size.height -= drag.height
            case .bottomLeading:
                newFrame.origin.x += drag.width; newFrame.size.width -= drag.width; newFrame.size.height += drag.height
            case .bottomTrailing:
                newFrame.size.width += drag.width; newFrame.size.height += drag.height
            default: break
            }
        }
        
        if newFrame.size.width > 30 && newFrame.size.height > 30 {
            self.frame = newFrame
        }
    }
}

// PhotoLayerElement definition moved above InteractiveLayer to avoid duplication


// ... Rest of the file grid pattern ...
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
