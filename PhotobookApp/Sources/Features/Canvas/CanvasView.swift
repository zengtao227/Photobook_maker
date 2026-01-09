import SwiftUI

struct CanvasView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(BookContext.self) private var bookContext
    @Environment(EditorState.self) private var editorState
    @Environment(LocalizationManager.self) private var localization
    @FocusState private var isCanvasFocused: Bool
    
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
                    
                    // 根据当前编辑目标决定长宽比
                    let spreadAspectRatio: CGFloat = {
                        switch editorState.currentTarget {
                        case .frontCover, .backCover:
                            // 封面和封底只显示一面，使用单页长宽比
                            return singlePageSize.width / singlePageSize.height
                        case .innerSpread(_):
                            // 内页都使用跨页长宽比（包括第一页和最后一页）
                            return (singlePageSize.width * 2) / singlePageSize.height
                        case .fullCoverWrap:
                            // 全包封面使用跨页长宽比
                            return (singlePageSize.width * 2) / singlePageSize.height
                        }
                    }()
                    
                    ZStack {
                        // Shadow (Book Lift)
                        Color.clear
                            .aspectRatio(spreadAspectRatio, contentMode: .fit)
                            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                        
                        // 根据当前编辑目标决定布局
                        Group {
                            if case .innerSpread(let index) = editorState.currentTarget {
                                let isFirstSpread = (index == 0)
                                let isLastSpread = (index == editorState.spreadCount - 1)
                                
                                if isFirstSpread {
                                    // 第一页：左侧显示"封面背面"提示，右侧可编辑
                                    HStack(spacing: 0) {
                                        // 左侧：封面背面（不可编辑）
                                        ZStack {
                                            Rectangle()
                                                .fill(Color.white)
                                            
                                            VStack(spacing: 8) {
                                                Image(systemName: "book.closed")
                                                    .font(.system(size: 48))
                                                    .foregroundColor(Color.gray.opacity(0.2))
                                                Text(localization.currentLanguage == .chinese ? "封面背面" : "Cover Back")
                                                    .font(.title3)
                                                    .foregroundColor(Color.gray.opacity(0.3))
                                                Text(localization.currentLanguage == .chinese ? "(不可编辑)" : "(Non-editable)")
                                                    .font(.caption)
                                                    .foregroundColor(Color.gray.opacity(0.3))
                                            }
                                        }
                                        .aspectRatio(singlePageSize.width / singlePageSize.height, contentMode: .fit)
                                        
                                        // Spine
                                        Rectangle()
                                            .fill(LinearGradient(
                                                colors: [.black.opacity(0.2), .black.opacity(0.05), .black.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ))
                                            .frame(width: 3)
                                            .zIndex(1000)
                                        
                                        // 右侧：第一页内容（可编辑）
                                        BookPage(isLeft: false, size: singlePageSize)
                                            .aspectRatio(singlePageSize.width / singlePageSize.height, contentMode: .fit)
                                    }
                                } else if isLastSpread {
                                    // 最后一页：左侧可编辑，右侧显示"封底背面"提示
                                    HStack(spacing: 0) {
                                        // 左侧：最后一页内容（可编辑）
                                        BookPage(isLeft: true, size: singlePageSize)
                                            .aspectRatio(singlePageSize.width / singlePageSize.height, contentMode: .fit)
                                        
                                        // Spine
                                        Rectangle()
                                            .fill(LinearGradient(
                                                colors: [.black.opacity(0.2), .black.opacity(0.05), .black.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ))
                                            .frame(width: 3)
                                            .zIndex(1000)
                                        
                                        // 右侧：封底背面（不可编辑）
                                        ZStack {
                                            Rectangle()
                                                .fill(Color.white)
                                            
                                            VStack(spacing: 8) {
                                                Image(systemName: "book.closed")
                                                    .font(.system(size: 48))
                                                    .foregroundColor(Color.gray.opacity(0.2))
                                                Text(localization.currentLanguage == .chinese ? "封底背面" : "Back Cover Back")
                                                    .font(.title3)
                                                    .foregroundColor(Color.gray.opacity(0.3))
                                                Text(localization.currentLanguage == .chinese ? "(不可编辑)" : "(Non-editable)")
                                                    .font(.caption)
                                                    .foregroundColor(Color.gray.opacity(0.3))
                                            }
                                        }
                                        .aspectRatio(singlePageSize.width / singlePageSize.height, contentMode: .fit)
                                    }
                                } else {
                                    // 中间的跨页：显示完整两面
                                    HStack(spacing: 0) {
                                        BookPage(isLeft: true, size: singlePageSize)
                                        
                                        // Spine
                                        Rectangle()
                                            .fill(LinearGradient(
                                                colors: [.black.opacity(0.2), .black.opacity(0.05), .black.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ))
                                            .frame(width: 3)
                                            .zIndex(1000)
                                        
                                        BookPage(isLeft: false, size: singlePageSize)
                                    }
                                    .aspectRatio(spreadAspectRatio, contentMode: .fit)
                                }
                            } else {
                                // 封面、封底、全包封面
                                switch editorState.currentTarget {
                                case .frontCover:
                                    // 封面：只显示右侧（封面外侧），使用单页布局
                                    BookPage(isLeft: true, size: singlePageSize)
                                        .aspectRatio(spreadAspectRatio, contentMode: .fit)
                                    
                                case .backCover:
                                    // 封底：只显示左侧（封底外侧），使用单页布局
                                    BookPage(isLeft: false, size: singlePageSize)
                                        .aspectRatio(spreadAspectRatio, contentMode: .fit)
                                    
                                case .fullCoverWrap:
                                    // 全包封面：显示完整跨页
                                    HStack(spacing: 0) {
                                        BookPage(isLeft: true, size: singlePageSize)
                                        
                                        Rectangle()
                                            .fill(LinearGradient(
                                                colors: [.black.opacity(0.2), .black.opacity(0.05), .black.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ))
                                            .frame(width: 3)
                                            .zIndex(1000)
                                        
                                        BookPage(isLeft: false, size: singlePageSize)
                                    }
                                    .aspectRatio(spreadAspectRatio, contentMode: .fit)
                                    
                                default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    .padding(40) // Padding from window edges
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .focused($isCanvasFocused)
        .onAppear {
            isCanvasFocused = true
        }
        .onTapGesture {
            isCanvasFocused = true
        }
    }
}

struct BookPage: View {
    let isLeft: Bool
    let size: CGSize
    @Environment(ThemeManager.self) private var themeManager
    @Environment(EditorState.self) private var editorState
    @Environment(BookContext.self) private var bookContext
    @EnvironmentObject var photoStore: PhotoStore // Needed to look up Photo by URL
    
    var pageModel: PageModel {
        isLeft ? editorState.leftPage : editorState.rightPage
    }
    
    // 背景视图
    @ViewBuilder
    private var backgroundView: some View {
        switch pageModel.backgroundType {
        case .solid:
            Rectangle()
                .fill(Color(hex: pageModel.backgroundColorHex))
            
        case .gradient:
            if let colors = pageModel.gradientColors, !colors.isEmpty {
                LinearGradient(
                    colors: colors.map { Color(hex: $0) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Rectangle()
                    .fill(Color(hex: pageModel.backgroundColorHex))
            }
            
        case .pattern:
            ZStack {
                Rectangle()
                    .fill(Color(hex: pageModel.backgroundColorHex))
                
                if let patternType = pageModel.patternType {
                    patternView(for: patternType)
                }
            }
            
        case .texture:
            ZStack {
                Rectangle()
                    .fill(Color(hex: pageModel.backgroundColorHex))
                
                if let textureType = pageModel.textureType {
                    textureView(for: textureType)
                }
            }
        }
    }
    
    @ViewBuilder
    private func patternView(for type: String) -> some View {
        switch type {
        case "dots":
            DotsPattern()
        case "stripes":
            StripesPattern()
        case "grid":
            GridPattern()
        case "diagonal":
            DiagonalPattern()
        case "hearts":
            HeartsPattern()
        case "stars":
            StarsPattern()
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func textureView(for type: String) -> some View {
        // 纹理可以用半透明图案模拟
        switch type {
        case "paper":
            DotsPattern()
                .opacity(0.1)
        case "fabric":
            DiagonalPattern()
                .opacity(0.15)
        case "wood":
            StripesPattern()
                .opacity(0.2)
        case "marble":
            GridPattern()
                .opacity(0.1)
        default:
            EmptyView()
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            // 计算缩放比例：显示尺寸 / 逻辑尺寸
            let logicalSize = bookContext.logicalPageSizeInPoints
            let displaySize = geometry.size
            let scale = displaySize.width / logicalSize.width
            
            ZStack(alignment: .topLeading) {
                // MARK: - Background Layer (Non-interactive)
                ZStack {
                    // 背景渲染
                    backgroundView
                    
                    // 如果是空白占位页，显示提示
                    // -98和-99是空白占位页，-1是封底，0是封面
                    if pageModel.pageNumber == -98 || pageModel.pageNumber == -99 {
                        VStack(spacing: 8) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 48))
                                .foregroundColor(Color.gray.opacity(0.2))
                            Text("内页")
                                .font(.title3)
                                .foregroundColor(Color.gray.opacity(0.3))
                            Text("(不可编辑)")
                                .font(.caption)
                                .foregroundColor(Color.gray.opacity(0.3))
                        }
                    } else {
                        // Grid Lines (Helper) - 只在可编辑页面显示
                        GridPattern()
                            .stroke(Color.blue.opacity(0.1), lineWidth: 0.5)
                    }
                    
                    // Inner Shadow (Simulate binding curve)
                    // 封面（pageNumber=0）：左边有阴影（装订边）
                    // 封底（pageNumber=-1）：右边有阴影（装订边）
                    // 内页左页：右边有阴影（装订边）
                    // 内页右页：左边有阴影（装订边）
                    HStack {
                        if pageModel.pageNumber == 0 {
                            // 封面：左边阴影
                            LinearGradient(
                                colors: [.black.opacity(0.15), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 20)
                            Spacer()
                        } else if pageModel.pageNumber == -1 {
                            // 封底：右边阴影
                            Spacer()
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.15)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 20)
                        } else if !isLeft {
                            // 右页：左边阴影
                            LinearGradient(
                                colors: [.black.opacity(0.15), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 20)
                            Spacer()
                        } else {
                            // 左页：右边阴影
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
                    InteractiveLayer(
                        wrapper: wrapper, 
                        isLeftPage: isLeft,
                        scale: scale,
                        logicalPageSize: logicalSize
                    )
                    .zIndex(1000) // Force layers to be on top
                }
                
                // MARK: - Bleed Guide Overlay (Phase 3)
                if editorState.showBleedGuide {
                    BleedGuideOverlay(
                        bleedPoints: editorState.bleedPoints,
                        pageSize: geometry.size
                    )
                    .allowsHitTesting(false)
                    .zIndex(2000) // On top of everything
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
            // MARK: - Bleed Guide Overlay
            .overlay(
                Group {
                    if editorState.showBleedGuide && pageModel.pageNumber >= -1 {
                        // 只在可编辑页面显示出血线
                        let bleedInset = editorState.bleedPoints * scale
                        
                        Rectangle()
                            .strokeBorder(
                                style: StrokeStyle(
                                    lineWidth: 1,
                                    dash: [5, 3]
                                )
                            )
                            .foregroundColor(.red.opacity(0.6))
                            .padding(bleedInset)
                        
                        // 出血区域标签
                        VStack {
                            HStack {
                                Text("BLEED: \(String(format: "%.1f", editorState.bleedMM))mm")
                                    .font(.system(size: 8))
                                    .foregroundColor(.red.opacity(0.8))
                                    .padding(2)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(2)
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(bleedInset + 4)
                    }
                }
            )
            // MARK: - Keyboard Shortcuts
            .focusable() // CRITICAL: Enable keyboard input
            .onKeyPress(.delete) {
                print("DEBUG: Delete key pressed, selected layer: \(String(describing: editorState.selectedLayerId))")
                if editorState.selectedLayerId != nil {
                    editorState.deleteSelectedLayer()
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(.deleteForward) {
                print("DEBUG: Delete forward key pressed, selected layer: \(String(describing: editorState.selectedLayerId))")
                if editorState.selectedLayerId != nil {
                    editorState.deleteSelectedLayer()
                    return .handled
                }
                return .ignored
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
                        onSave: { filterType, brightness, contrast, saturation, vignette, sharpen, temperature in
                            editorState.updateLayerFilter(
                                id: photoLayer.id,
                                filterType: filterType,
                                brightness: brightness,
                                contrast: contrast,
                                saturation: saturation,
                                vignette: vignette,
                                sharpen: sharpen,
                                temperature: temperature
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
                // 只有-98和-99是空白占位页（不可编辑）
                // -1是封底，0是封面，>0是内页，都可以编辑
                guard pageModel.pageNumber != -98 && pageModel.pageNumber != -99 else {
                    print("DEBUG: Cannot drop on blank placeholder page (pageNumber: \(pageModel.pageNumber))")
                    return false
                }
                
                // 封面（pageNumber=0）只能在左页编辑
                if pageModel.pageNumber == 0 && !isLeft {
                    print("DEBUG: Cannot drop on front cover right page (inner side)")
                    return false
                }
                
                // 封底（pageNumber=-1）只能在右页编辑
                if pageModel.pageNumber == -1 && isLeft {
                    print("DEBUG: Cannot drop on back cover left page (inner side)")
                    return false
                }
                
                guard let url = items.first else { return false }
                
                if let photo = photoStore.allPhotos.first(where: { $0.url == url }) {
                    // 传递scale，让EditorState将显示坐标转换为逻辑坐标
                    editorState.addPhotoLayer(
                        photo: photo, 
                        isLeftPage: isLeft, 
                        center: location,
                        scale: scale
                    )
                    return true
                }
                return false
            }
        }
    }
}

// MARK: - Text Layer Display

struct TextLayerElement: View {
    let layer: TextLayer
    
    private var swiftUIAlignment: SwiftUI.TextAlignment {
        switch layer.alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
    
    var body: some View {
        Text(layer.text)
            .font(.custom(layer.fontName, size: layer.fontSize))
            .fontWeight(layer.isBold ? .bold : .regular)
            .italic(layer.isItalic)
            .foregroundColor(Color(hex: layer.colorHex))
            .multilineTextAlignment(swiftUIAlignment)
            .frame(width: layer.frame.width, height: layer.frame.height, alignment: alignmentForFrame)
            .background(
                layer.backgroundColorHex != nil 
                    ? Color(hex: layer.backgroundColorHex!) 
                    : Color.clear
            )
            .contentShape(Rectangle())
    }
    
    private var alignmentForFrame: Alignment {
        switch layer.alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
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
        // 不在这里设置frame，由外部InteractiveLayer控制
        .contentShape(Rectangle())
        .clipped()
        // Apply Feathering (Masking)
        .mask(
            Group {
                if layer.borderStyle == .stamp {
                    StampShape().fill(style: FillStyle(eoFill: true))
                } else if layer.feathering > 0 {
                    RoundedRectangle(cornerRadius: layer.borderCornerRadius)
                        .padding(layer.feathering / 2)
                        .blur(radius: layer.feathering / 2)
                } else {
                    RoundedRectangle(cornerRadius: layer.borderCornerRadius)
                }
            }
        )
        // Apply border
        .overlay(
            Group {
                if layer.borderWidth > 0 {
                    if layer.borderStyle == .double {
                        // Double border style
                        ZStack {
                            RoundedRectangle(cornerRadius: layer.borderCornerRadius)
                                .stroke(Color(hex: layer.borderColorHex), lineWidth: layer.borderWidth)
                            
                            // Inner line
                            RoundedRectangle(cornerRadius: max(0, layer.borderCornerRadius - 4))
                                .stroke(Color(hex: layer.borderColorHex), lineWidth: max(1, layer.borderWidth / 3))
                                .padding(4)
                        }
                    } else if layer.borderStyle == .stamp {
                        StampShape()
                            .stroke(Color(hex: layer.borderColorHex), lineWidth: layer.borderWidth)
                    } else {
                        // Solid, Dashed, Dotted
                        RoundedRectangle(cornerRadius: layer.borderCornerRadius)
                            .stroke(
                                Color(hex: layer.borderColorHex),
                                style: StrokeStyle(
                                    lineWidth: layer.borderWidth,
                                    dash: layer.borderStyle.dashPattern
                                )
                            )
                    }
                }
            }
        )
        // Apply shadow
        .shadow(
            color: Color.black.opacity(layer.shadowOpacity),
            radius: layer.shadowRadius,
            x: 0,
            y: layer.shadowRadius / 3
        )
        // Apply layer opacity
        .opacity(layer.opacity)
        .allowsHitTesting(false)
        .onAppear {
            loadFilteredImage()
        }
        .onChange(of: layer.filterType) { _, _ in loadFilteredImage() }
        .onChange(of: layer.brightness) { _, _ in loadFilteredImage() }
        .onChange(of: layer.contrast) { _, _ in loadFilteredImage() }
        .onChange(of: layer.saturation) { _, _ in loadFilteredImage() }
        .onChange(of: layer.vignetteIntensity) { _, _ in loadFilteredImage() }
        .onChange(of: layer.sharpenIntensity) { _, _ in loadFilteredImage() }
        .onChange(of: layer.temperature) { _, _ in loadFilteredImage() }
    }
    
    private func loadFilteredImage() {
        // Only apply filter if needed
        guard layer.filterType != .none || 
              layer.brightness != 0 || 
              layer.contrast != 1 || 
              layer.saturation != 1 ||
              layer.vignetteIntensity > 0 ||
              layer.sharpenIntensity > 0 ||
              layer.temperature != 6500 else {
            filteredImage = nil
            return
        }
        
        Task {
            filteredImage = await generateFilteredImage(
                from: layer.photoUrl,
                filter: layer.filterType,
                brightness: layer.brightness,
                contrast: layer.contrast,
                saturation: layer.saturation,
                vignette: layer.vignetteIntensity,
                sharpen: layer.sharpenIntensity,
                temperature: layer.temperature
            )
        }
    }
}

struct InteractiveLayer: View {
    let wrapper: AnyLayer
    let isLeftPage: Bool
    let scale: CGFloat // 显示缩放比例
    let logicalPageSize: CGSize // 逻辑页面尺寸
    @Environment(EditorState.self) private var editorState
    
    // MARK: - Transient Gesture State
    @State private var transientFrame: CGRect? = nil
    @State private var transientRotation: Double? = nil // Transient rotation state
    
    /// 将逻辑坐标转换为显示坐标
    private func toDisplayFrame(_ logicalFrame: CGRect) -> CGRect {
        return CGRect(
            x: logicalFrame.origin.x * scale,
            y: logicalFrame.origin.y * scale,
            width: logicalFrame.size.width * scale,
            height: logicalFrame.size.height * scale
        )
    }
    
    /// 将显示坐标转换为逻辑坐标
    private func toLogicalFrame(_ displayFrame: CGRect) -> CGRect {
        return CGRect(
            x: displayFrame.origin.x / scale,
            y: displayFrame.origin.y / scale,
            width: displayFrame.size.width / scale,
            height: displayFrame.size.height / scale
        )
    }
    
    private func currentDisplayFrame(for layer: PhotoLayer) -> CGRect {
        if let transient = transientFrame {
            return transient
        }
        // 将逻辑坐标转换为显示坐标
        return toDisplayFrame(layer.frame)
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
                                if let finalDisplayFrame = transientFrame {
                                    // 转换为逻辑坐标再保存
                                    let logicalFrame = toLogicalFrame(finalDisplayFrame)
                                    editorState.updateLayerFrame(photoLayer.id, newFrame: logicalFrame)
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
            
            // 2. Drag to Move
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        guard isSelected, !isCropping else { return }
                        
                        // FIXED: Compensate for rotation when dragging
                        let radians = -rotation * .pi / 180.0
                        let cos = Darwin.cos(radians)
                        let sin = Darwin.sin(radians)
                        
                        // Rotate the translation vector
                        let adjustedX = value.translation.width * cos - value.translation.height * sin
                        let adjustedY = value.translation.width * sin + value.translation.height * cos
                        
                        // 从初始显示frame开始计算新位置
                        let originalDisplayFrame = toDisplayFrame(photoLayer.frame)
                        var newDisplayFrame = originalDisplayFrame
                        newDisplayFrame.origin.x += adjustedX
                        newDisplayFrame.origin.y += adjustedY
                        
                        // 不做任何边界限制，允许自由移动
                        transientFrame = newDisplayFrame
                    }
                    .onEnded { _ in
                        guard isSelected, !isCropping else { return }
                        if let finalDisplayFrame = transientFrame {
                            // 转换为逻辑坐标再保存
                            let logicalFrame = toLogicalFrame(finalDisplayFrame)
                            editorState.updateLayerFrame(photoLayer.id, newFrame: logicalFrame)
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
        // MARK: - Text Layer Rendering
        else if let textLayer = currentLayer as? TextLayer {
            // 转换为显示坐标
            let displayFrame = transientFrame ?? toDisplayFrame(textLayer.frame)
            let rotation = transientRotation ?? textLayer.rotation
            let isSelected = editorState.selectedLayerId == textLayer.id
            let isEditing = editorState.editingTextLayerId == textLayer.id
            
            ZStack {
                // Text Content
                if isEditing {
                    // Inline editing mode
                    InlineTextEditor(
                        layer: textLayer,
                        onCommit: { newText in
                            editorState.updateTextContent(id: textLayer.id, text: newText)
                            editorState.endTextEditing()
                        },
                        onCancel: {
                            editorState.endTextEditing()
                        }
                    )
                    .frame(width: displayFrame.width, height: displayFrame.height)
                } else {
                    TextLayerElement(layer: textLayer)
                }
                
                // Selection handles
                if isSelected && !isEditing {
                    SelectionBorder(
                        frame: Binding(
                            get: { displayFrame },
                            set: { transientFrame = $0 }
                        ),
                        rotation: Binding(
                            get: { rotation },
                            set: { transientRotation = $0 }
                        ),
                        lockAspectRatio: false, // Text can resize freely
                        onCommitFrame: {
                            if let finalDisplayFrame = transientFrame {
                                // 转换为逻辑坐标
                                let logicalFrame = toLogicalFrame(finalDisplayFrame)
                                editorState.updateLayerFrame(textLayer.id, newFrame: logicalFrame)
                            }
                            transientFrame = nil
                        },
                        onCommitRotation: {
                            if let rot = transientRotation {
                                editorState.updateLayerRotation(textLayer.id, newRotation: rot)
                            }
                            transientRotation = nil
                        }
                    )
                }
            }
            .frame(width: displayFrame.width, height: displayFrame.height)
            .rotationEffect(.degrees(rotation))
            .position(x: displayFrame.midX, y: displayFrame.midY)
            // Drag gesture
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isEditing {
                            if transientFrame == nil {
                                transientFrame = toDisplayFrame(textLayer.frame)
                            }
                            
                            // 从原始frame开始计算
                            let originalDisplayFrame = toDisplayFrame(textLayer.frame)
                            let newOrigin = CGPoint(
                                x: originalDisplayFrame.origin.x + value.translation.width,
                                y: originalDisplayFrame.origin.y + value.translation.height
                            )
                            transientFrame = CGRect(origin: newOrigin, size: originalDisplayFrame.size)
                        }
                    }
                    .onEnded { _ in
                        if let finalDisplayFrame = transientFrame {
                            // 转换为逻辑坐标
                            let logicalFrame = toLogicalFrame(finalDisplayFrame)
                            editorState.updateLayerFrame(textLayer.id, newFrame: logicalFrame)
                        }
                        transientFrame = nil
                    }
            )
            // Single tap to select
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        editorState.selectLayer(textLayer.id)
                    }
            )
            // Double tap to edit
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        editorState.startTextEditing(textLayer.id)
                    }
            )
            .contextMenu {
                Button {
                    editorState.startTextEditing(textLayer.id)
                } label: {
                    Label("编辑文字", systemImage: "pencil")
                }
                
                Divider()
                
                Button {
                    editorState.moveLayerToFront(textLayer.id)
                } label: {
                    Label("移到最前", systemImage: "square.3.layers.3d.top.filled")
                }
                
                Button {
                    editorState.moveLayerToBack(textLayer.id)
                } label: {
                    Label("移到最后", systemImage: "square.3.layers.3d.bottom.filled")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    editorState.deleteSelectedLayer()
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
        }
        // MARK: - Sticker Layer Rendering
        else if let stickerLayer = currentLayer as? StickerLayer {
            // 转换为显示坐标
            let displayFrame = transientFrame ?? toDisplayFrame(stickerLayer.frame)
            let rotation = transientRotation ?? stickerLayer.rotation
            let isSelected = editorState.selectedLayerId == stickerLayer.id
            
            ZStack {
                StickerLayerElement(layer: stickerLayer)
                .frame(width: displayFrame.width, height: displayFrame.height)
                .contentShape(Rectangle())
                
                if isSelected {
                    SelectionBorder(
                        frame: Binding(
                            get: { displayFrame },
                            set: { transientFrame = $0 }
                        ),
                        rotation: Binding(
                            get: { rotation },
                            set: { transientRotation = $0 }
                        ),
                        onCommitFrame: {
                            if let finalDisplayFrame = transientFrame {
                                // 转换为逻辑坐标
                                let logicalFrame = toLogicalFrame(finalDisplayFrame)
                                editorState.updateLayerFrame(stickerLayer.id, newFrame: logicalFrame)
                                transientFrame = nil
                            }
                        },
                        onCommitRotation: {
                            if let finalRot = transientRotation {
                                editorState.updateLayerRotation(stickerLayer.id, newRotation: finalRot)
                                transientRotation = nil
                            }
                        }
                    )
                    .frame(width: displayFrame.width, height: displayFrame.height)
                }
            }
            .position(x: displayFrame.midX, y: displayFrame.midY)
            .rotationEffect(Angle(degrees: rotation), anchor: .center)
            .zIndex(Double(stickerLayer.zIndex) + (isSelected ? 100 : 0))
            
            // Gestures
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        guard isSelected else { return }
                        if transientFrame == nil { 
                            transientFrame = toDisplayFrame(stickerLayer.frame)
                        }
                        
                        // 从原始frame开始计算
                        let originalDisplayFrame = toDisplayFrame(stickerLayer.frame)
                        var newFrame = originalDisplayFrame
                        newFrame.origin.x += value.translation.width
                        newFrame.origin.y += value.translation.height
                        
                        transientFrame = newFrame
                    }
                    .onEnded { _ in
                        guard isSelected else { return }
                        if let finalDisplayFrame = transientFrame {
                            // 转换为逻辑坐标
                            let logicalFrame = toLogicalFrame(finalDisplayFrame)
                            editorState.updateLayerFrame(stickerLayer.id, newFrame: logicalFrame)
                            transientFrame = nil
                        }
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        editorState.selectLayer(stickerLayer.id)
                    }
            )
            .contextMenu {
                Button {
                    editorState.moveLayerToFront(stickerLayer.id)
                } label: {
                    Label("移到最前", systemImage: "square.3.layers.3d.top.filled")
                }
                
                Button {
                    editorState.moveLayerToBack(stickerLayer.id)
                } label: {
                    Label("移到最后", systemImage: "square.3.layers.3d.bottom.filled")
                }
                
                Divider()
                
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
    
    // Normalize rotation to -180 to 180 range for display
    private var normalizedRotation: Double {
        var r = rotation.truncatingRemainder(dividingBy: 360)
        if r > 180 { r -= 360 }
        if r < -180 { r += 360 }
        return r
    }
    
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
            
            // Rotation Handle Knob with angle display
            VStack(spacing: 4) {
                // Rotation angle display (shows when rotating or when angle != 0)
                if innerInitialRotation != nil || abs(rotation) > 0.1 {
                    Text(String(format: "%.1f°", normalizedRotation))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
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
        let minSize: CGFloat = 30
        
        if lockAspectRatio {
            // 最简单的缩放：只用水平拖动距离来决定宽度变化
            var deltaW: CGFloat = 0
            
            switch alignment {
            case .bottomTrailing, .topTrailing:
                // 右侧角：向右拖动放大
                deltaW = drag.width
            case .topLeading, .bottomLeading:
                // 左侧角：向左拖动放大（负方向）
                deltaW = -drag.width
            default: break
            }
            
            let newW = max(minSize, startFrame.width + deltaW)
            let newH = newW / ar
            
            switch alignment {
            case .bottomTrailing:
                // 右下角：origin不变
                newFrame.size.width = newW
                newFrame.size.height = newH
                
            case .topLeading:
                // 左上角：origin随尺寸变化
                newFrame.origin.x = startFrame.maxX - newW
                newFrame.origin.y = startFrame.maxY - newH
                newFrame.size.width = newW
                newFrame.size.height = newH
                
            case .topTrailing:
                // 右上角：x不变，y随高度变化
                newFrame.origin.y = startFrame.maxY - newH
                newFrame.size.width = newW
                newFrame.size.height = newH
                
            case .bottomLeading:
                // 左下角：y不变，x随宽度变化
                newFrame.origin.x = startFrame.maxX - newW
                newFrame.size.width = newW
                newFrame.size.height = newH
                
            default: break
            }
        } else {
            // Freeform
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
        
        if newFrame.size.width > minSize && newFrame.size.height > minSize {
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
// MARK: - Sticker Layer Element

struct StickerLayerElement: View {
    let layer: StickerLayer
    
    var body: some View {
        Group {
            switch layer.content {
            case .url(let url):
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                
            case .systemImage(let name):
                Image(systemName: name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(hex: layer.colorHex ?? "#000000"))
                    
            case .emoji(let char):
                Text(char)
                    .font(.system(size: min(layer.frame.width, layer.frame.height)))
                    .minimumScaleFactor(0.1)
            }
        }
        .frame(width: layer.frame.width, height: layer.frame.height)
        .rotationEffect(.degrees(layer.rotation))
        .contentShape(Rectangle())
        .shadow(
            color: Color.black.opacity(layer.shadowOpacity),
            radius: layer.shadowRadius,
            x: 0,
            y: layer.shadowRadius / 3
        )
    }
}

// MARK: - Bleed Guide Overlay (Phase 3)

/// Displays a red dashed line indicating the print bleed/trim area
struct BleedGuideOverlay: View {
    let bleedPoints: CGFloat
    let pageSize: CGSize
    
    var body: some View {
        ZStack {
            // Outer edge (bleed line - will be trimmed)
            Rectangle()
                .stroke(
                    Color.red.opacity(0.6),
                    style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                )
                .frame(width: pageSize.width, height: pageSize.height)
            
            // Inner edge (safe zone - content should stay inside)
            Rectangle()
                .stroke(
                    Color.red.opacity(0.8),
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                )
                .frame(
                    width: pageSize.width - bleedPoints * 2,
                    height: pageSize.height - bleedPoints * 2
                )
            
            // Corner labels
            VStack {
                HStack {
                    BleedLabel(text: "裁切线 (3mm)")
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    BleedLabel(text: "安全区域")
                }
                .padding(.bottom, bleedPoints + 4)
                .padding(.trailing, bleedPoints + 4)
            }
            .padding(4)
        }
    }
}

/// Small label for bleed guide annotations
struct BleedLabel: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.red)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.85))
            .cornerRadius(3)
    }
}

// MARK: - Stamp Shape

struct StampShape: Shape {
    func path(in rect: CGRect) -> Path {
        let holeRadius: CGFloat = 8
        let spacing: CGFloat = 20
        
        var path = Path()
        // 1. The main rectangle
        path.addRect(rect)
        
        // 2. The holes (ellipses)
        // By using eoFill (Even-Odd rule), overlapping areas will be removed (holes)
        
        // Top edge
        let countX = Int(rect.width / spacing)
        let gapX = rect.width / CGFloat(countX) // Adjusted spacing to fit perfectly
        
        for i in 0...countX {
             let x = CGFloat(i) * gapX
             path.addEllipse(in: CGRect(x: x - holeRadius, y: -holeRadius, width: holeRadius*2, height: holeRadius*2))
        }
        
        // Bottom edge
        for i in 0...countX {
             let x = CGFloat(i) * gapX
             path.addEllipse(in: CGRect(x: x - holeRadius, y: rect.height - holeRadius, width: holeRadius*2, height: holeRadius*2))
        }
        
        // Y-axis holes
        let countY = Int(rect.height / spacing)
        let gapY = rect.height / CGFloat(countY)
        
        // Left edge
        for i in 0...countY {
             let y = CGFloat(i) * gapY
             path.addEllipse(in: CGRect(x: -holeRadius, y: y - holeRadius, width: holeRadius*2, height: holeRadius*2))
        }
        
        // Right edge
        for i in 0...countY {
             let y = CGFloat(i) * gapY
             path.addEllipse(in: CGRect(x: rect.width - holeRadius, y: y - holeRadius, width: holeRadius*2, height: holeRadius*2))
        }
        
        return path
    }
}
