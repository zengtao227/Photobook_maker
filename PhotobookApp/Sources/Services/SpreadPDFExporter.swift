import Foundation
import AppKit
import SwiftUI
import PDFKit

// MARK: - Export Configuration

/// Configuration for PDF export
public struct PDFExportConfig {
    /// Target DPI for print quality (300 is print standard)
    public var dpi: CGFloat = 300
    
    /// Bleed margin in millimeters (3mm is standard for print)
    public var bleedMM: CGFloat = 3
    
    /// Whether to include bleed area in export
    public var includeBleed: Bool = true
    
    /// Page size in points (without bleed)
    public var pageSize: CGSize
    
    /// Include crop marks
    public var includeCropMarks: Bool = false
    
    /// Include registration marks
    public var includeRegistrationMarks: Bool = false
    
    /// Include color bars
    public var includeColorBars: Bool = false
    
    /// Include page info
    public var includePageInfo: Bool = false
    
    /// Crop mark length in points
    public var cropMarkLength: CGFloat = 12
    
    /// Crop mark offset from trim edge
    public var cropMarkOffset: CGFloat = 3
    
    /// Calculated bleed in points
    public var bleedPoints: CGFloat {
        bleedMM * 2.83465 // 1mm = 2.83465 points
    }
    
    /// Full page size including bleed
    public var fullPageSize: CGSize {
        if includeBleed {
            return CGSize(
                width: pageSize.width + bleedPoints * 2,
                height: pageSize.height + bleedPoints * 2
            )
        }
        return pageSize
    }
    
    /// Extra margin for print marks
    public var printMarksMargin: CGFloat {
        (includeCropMarks || includeRegistrationMarks || includeColorBars) ? 36 : 0
    }
    
    /// Total page size including bleed and print marks margin
    public var totalPageSize: CGSize {
        CGSize(
            width: fullPageSize.width + printMarksMargin * 2,
            height: fullPageSize.height + printMarksMargin * 2
        )
    }
    
    /// Scale factor for high DPI rendering
    public var scaleFactor: CGFloat {
        dpi / 72.0 // 72 is the base DPI for points
    }
    
    public static var defaultA4: PDFExportConfig {
        PDFExportConfig(pageSize: CGSize(width: 595, height: 842)) // A4 in points
    }
    
    public static var defaultA5: PDFExportConfig {
        PDFExportConfig(pageSize: CGSize(width: 420, height: 595)) // A5 in points
    }
}

// MARK: - Spread PDF Exporter

/// High-quality PDF exporter that renders EditorState spreads
@MainActor
public class SpreadPDFExporter {
    
    /// Export a single spread (left + right page) to PDF
    public static func exportSpread(
        leftPage: PageModel,
        rightPage: PageModel,
        config: PDFExportConfig = .defaultA4,
        to url: URL
    ) async throws {
        // Pre-load all filtered images synchronously to avoid placeholders
        let leftLayers = await preloadFilteredImages(for: leftPage)
        let rightLayers = await preloadFilteredImages(for: rightPage)
        
        // Create the exportable spread view
        let spreadView = ExportableSpreadView(
            leftPage: leftPage,
            rightPage: rightPage,
            leftFilteredImages: leftLayers,
            rightFilteredImages: rightLayers,
            config: config
        )
        
        // Calculate pixel dimensions for high DPI - config.fullPageSize已经是跨页尺寸
        let pixelWidth = config.fullPageSize.width * config.scaleFactor
        let pixelHeight = config.fullPageSize.height * config.scaleFactor
        
        // Use ImageRenderer for high-quality rendering
        let renderer = ImageRenderer(content: spreadView
            .frame(width: config.fullPageSize.width, height: config.fullPageSize.height))
        
        renderer.scale = config.scaleFactor
        
        // Render to CGImage
        guard let cgImage = renderer.cgImage else {
            throw ExportError.renderFailed
        }
        
        // Create PDF document
        let pdfDocument = PDFDocument()
        
        // Convert to NSImage for PDFPage
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: pixelWidth, height: pixelHeight))
        
        if let pdfPage = PDFPage(image: nsImage) {
            pdfDocument.insert(pdfPage, at: 0)
        }
        
        // Write to file
        pdfDocument.write(to: url)
        
        print("✅ PDF exported: \(url.path)")
        print("   Resolution: \(Int(pixelWidth))x\(Int(pixelHeight)) @ \(Int(config.dpi)) DPI")
    }
    
    /// Export multiple spreads to a single PDF
    public static func exportBook(
        spreads: [(left: PageModel, right: PageModel)],
        config: PDFExportConfig = .defaultA4,
        to url: URL,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws {
        let pdfDocument = PDFDocument()
        
        print("📊 PDF配置:")
        print("   pageSize: \(config.pageSize)")
        print("   fullPageSize: \(config.fullPageSize)")
        print("   includeBleed: \(config.includeBleed)")
        print("   总跨页数: \(spreads.count)")
        
        for (index, spread) in spreads.enumerated() {
            // Pre-load filtered images
            let leftLayers = await preloadFilteredImages(for: spread.left)
            let rightLayers = await preloadFilteredImages(for: spread.right)
            
            // Create exportable view
            let spreadView = ExportableSpreadView(
                leftPage: spread.left,
                rightPage: spread.right,
                leftFilteredImages: leftLayers,
                rightFilteredImages: rightLayers,
                config: config
            )
            
            // Wrap with print marks if needed
            let finalView: AnyView
            if config.includeCropMarks || config.includeRegistrationMarks || config.includeColorBars {
                finalView = AnyView(
                    PrintMarksWrapper(
                        content: spreadView,
                        config: config,
                        pageNumber: index + 1,
                        totalPages: spreads.count
                    )
                )
            } else {
                finalView = AnyView(spreadView)
            }
            
            // Calculate dimensions - config.fullPageSize已经是跨页尺寸，不要再乘以2
            let totalWidth = config.includeCropMarks ? config.totalPageSize.width : config.fullPageSize.width
            let totalHeight = config.includeCropMarks ? config.totalPageSize.height : config.fullPageSize.height
            
            print("📐 渲染尺寸: \(totalWidth) x \(totalHeight)")
            
            // Render at high DPI
            let renderer = ImageRenderer(content: finalView
                .frame(width: totalWidth, height: totalHeight))
            renderer.scale = config.scaleFactor
            
            if let cgImage = renderer.cgImage {
                let size = NSSize(
                    width: totalWidth * config.scaleFactor,
                    height: totalHeight * config.scaleFactor
                )
                let nsImage = NSImage(cgImage: cgImage, size: size)
                
                if let pdfPage = PDFPage(image: nsImage) {
                    pdfDocument.insert(pdfPage, at: index)
                }
            }
            
            // Report progress
            progressHandler?(Double(index + 1) / Double(spreads.count))
        }
        
        pdfDocument.write(to: url)
        
        // Add PDF metadata for print instructions
        addPDFMetadata(to: url, pageCount: spreads.count)
        
        print("✅ Book PDF exported: \(spreads.count) spreads to \(url.path)")
    }
    
    // MARK: - Filter Pre-loading
    
    /// Pre-load all filtered images for a page to avoid async placeholders during export
    public static func preloadFilteredImages(for page: PageModel) async -> [LayerID: NSImage] {
        var result: [LayerID: NSImage] = [:]
        
        for wrapper in page.layers {
            guard let photoLayer = wrapper.layer as? PhotoLayer else { continue }
            
            // Check if filtering is needed
            let needsFilter = photoLayer.filterType != .none ||
                              photoLayer.brightness != 0 ||
                              photoLayer.contrast != 1 ||
                              photoLayer.saturation != 1 ||
                              photoLayer.vignetteIntensity > 0 ||
                              photoLayer.sharpenIntensity > 0 ||
                              photoLayer.temperature != 6500
            
            if needsFilter {
                // Generate filtered image synchronously
                if let filtered = await generateFilteredImage(
                    from: photoLayer.photoUrl,
                    filter: photoLayer.filterType,
                    brightness: photoLayer.brightness,
                    contrast: photoLayer.contrast,
                    saturation: photoLayer.saturation,
                    vignette: photoLayer.vignetteIntensity,
                    sharpen: photoLayer.sharpenIntensity,
                    temperature: photoLayer.temperature
                ) {
                    result[photoLayer.id] = filtered
                }
            } else {
                // Load original image
                if let original = NSImage(contentsOf: photoLayer.photoUrl) {
                    result[photoLayer.id] = original
                }
            }
        }
        
        return result
    }
    
    // MARK: - PDF Metadata
    
    /// Add print-related metadata to the PDF file
    /// This helps print shops understand the printing requirements
    private static func addPDFMetadata(to url: URL, pageCount: Int) {
        guard let pdfDocument = PDFDocument(url: url) else { return }
        
        // Set document attributes
        // Note: PDFKit has limited metadata support, but we can set basic info
        // Create metadata dictionary
        // These are standard PDF metadata keys
        let attributes: [PDFDocumentAttribute: Any] = [
            .titleAttribute: "Photobook - 双面打印",
            .authorAttribute: "PhotobookPro",
            .subjectAttribute: "双面打印 (Duplex: Long-Edge Flip)",
            .creatorAttribute: "PhotobookPro Export",
            .keywordsAttribute: ["photobook", "双面打印", "duplex", "long-edge-flip", "spread"]
        ]
        
        // Set the attributes
        for (key, value) in attributes {
            pdfDocument.documentAttributes?[key] = value
        }
        
        // Write back with metadata
        pdfDocument.write(to: url)
        
        print("📋 PDF metadata added: 双面打印 (Duplex)")
    }
    
    enum ExportError: LocalizedError {
        case renderFailed
        
        var errorDescription: String? {
            switch self {
            case .renderFailed:
                return "Failed to render spread to image"
            }
        }
    }
}

// MARK: - Exportable Spread View

/// A SwiftUI view optimized for PDF export (no async loading)
struct ExportableSpreadView: View {
    let leftPage: PageModel
    let rightPage: PageModel
    let leftFilteredImages: [LayerID: NSImage]
    let rightFilteredImages: [LayerID: NSImage]
    let config: PDFExportConfig
    
    // 单页成品尺寸（points）
    private var trimWidth: CGFloat { config.pageSize.width / 2 }
    private var trimHeight: CGFloat { config.pageSize.height }
    private var bleed: CGFloat { config.includeBleed ? config.bleedPoints : 0 }
    
    // PDF总尺寸 = 成品尺寸 + 四周出血
    // fullPageSize.width = trimWidth*2 + bleed*2
    // fullPageSize.height = trimHeight + bleed*2
    
    var body: some View {
        let _ = print("🖨️ ExportableSpreadView:")
        let _ = print("   trimWidth=\(trimWidth), trimHeight=\(trimHeight), bleed=\(bleed)")
        let _ = print("   fullPageSize=\(config.fullPageSize)")
        let _ = print("   leftPage layers=\(leftPage.layers.count), rightPage layers=\(rightPage.layers.count)")
        
        return Canvas { context, size in
            let _ = print("   Canvas size=\(size)")
            
            // 1. 绘制左页背景
            // 左页背景：从x=0到x=bleed+trimWidth（左出血+左页成品）
            let leftBgRect = CGRect(x: 0, y: 0, width: bleed + trimWidth, height: size.height)
            context.fill(Path(leftBgRect), with: .color(Color(hex: leftPage.backgroundColorHex)))
            
            // 2. 绘制右页背景
            // 右页背景：从x=bleed+trimWidth到末尾（右页成品+右出血）
            let rightBgRect = CGRect(x: bleed + trimWidth, y: 0, width: trimWidth + bleed, height: size.height)
            context.fill(Path(rightBgRect), with: .color(Color(hex: rightPage.backgroundColorHex)))
            
            // 3. 绘制左页图层
            // 左页成品区域起点：(bleed, bleed)
            // UI坐标(0,0) -> PDF坐标(bleed, bleed)
            for wrapper in leftPage.layers {
                drawLayer(wrapper, filteredImages: leftFilteredImages, in: context, offsetX: bleed, offsetY: bleed)
            }
            
            // 4. 绘制右页图层
            // 右页成品区域起点：(bleed + trimWidth, bleed)
            // UI坐标(0,0) -> PDF坐标(bleed + trimWidth, bleed)
            for wrapper in rightPage.layers {
                drawLayer(wrapper, filteredImages: rightFilteredImages, in: context, offsetX: bleed + trimWidth, offsetY: bleed)
            }
        }
        .frame(width: config.fullPageSize.width, height: config.fullPageSize.height)
    }
    
    private func drawLayer(_ wrapper: AnyLayer, filteredImages: [LayerID: NSImage], in context: GraphicsContext, offsetX: CGFloat, offsetY: CGFloat) {
        if let photoLayer = wrapper.layer as? PhotoLayer {
            drawPhotoLayer(photoLayer, filteredImage: filteredImages[photoLayer.id], in: context, offsetX: offsetX, offsetY: offsetY)
        } else if let textLayer = wrapper.layer as? TextLayer {
            drawTextLayer(textLayer, in: context, offsetX: offsetX, offsetY: offsetY)
        } else if let stickerLayer = wrapper.layer as? StickerLayer {
            drawStickerLayer(stickerLayer, in: context, offsetX: offsetX, offsetY: offsetY)
        }
    }
    
    private func drawPhotoLayer(_ layer: PhotoLayer, filteredImage: NSImage?, in context: GraphicsContext, offsetX: CGFloat, offsetY: CGFloat) {
        guard let image = filteredImage ?? NSImage(contentsOf: layer.photoUrl) else { return }
        
        let frame = layer.frame
        // 计算实际绘制中心点 - 这个中心点是UI框的中心，不受旋转影响
        let centerX = offsetX + frame.midX
        let centerY = offsetY + frame.midY
        
        let _ = print("   📷 Photo: frame=\(frame), center=(\(centerX), \(centerY)), rotation=\(layer.rotation), cropScale=\(layer.cropScale), cropOffset=\(layer.cropOffset), cropRotation=\(layer.cropRotation)")
        
        var ctx = context
        
        // --- 第一步：定位图层框 (Layer Transform) ---
        ctx.translateBy(x: centerX, y: centerY)
        ctx.rotate(by: Angle(degrees: layer.rotation))
        
        // --- 第二步：裁剪 (Clipping) ---
        // 此时坐标原点在框的中心，旋转已应用
        let clipRect = CGRect(x: -frame.width/2, y: -frame.height/2, width: frame.width, height: frame.height)
        ctx.clip(to: Path(clipRect))
        
        // --- 第三步：内部图片变换 (Image/Crop Transform) ---
        // 关键修复：cropOffset 需要反向旋转 layer.rotation，
        // 因为在 SwiftUI 中 cropOffset 是在 layer.rotation 之前应用的（在图片内部坐标系中）
        // 但在 Canvas 中我们已经旋转了坐标系，所以需要将 cropOffset 转换到旋转后的坐标系
        let rotationRadians = -layer.rotation * .pi / 180  // 反向旋转
        let adjustedOffsetX = layer.cropOffset.width * Darwin.cos(rotationRadians) - layer.cropOffset.height * Darwin.sin(rotationRadians)
        let adjustedOffsetY = layer.cropOffset.width * Darwin.sin(rotationRadians) + layer.cropOffset.height * Darwin.cos(rotationRadians)
        
        ctx.translateBy(x: adjustedOffsetX, y: adjustedOffsetY)
        ctx.scaleBy(x: layer.cropScale, y: layer.cropScale)
        ctx.rotate(by: Angle(degrees: layer.cropRotation))
        
        // --- 第四步：计算图片原始绘制区域 ---
        // 使用 Aspect Fill 逻辑：图片填充整个 frame，可能会被裁剪
        let imageSize = image.size
        let horizontalScale = frame.width / imageSize.width
        let verticalScale = frame.height / imageSize.height
        let scale = max(horizontalScale, verticalScale)
        
        let drawWidth = imageSize.width * scale
        let drawHeight = imageSize.height * scale
        
        // 图片绘制的中心对准当前坐标系原点（即相框中心）
        let imageRect = CGRect(x: -drawWidth/2, y: -drawHeight/2, width: drawWidth, height: drawHeight)
        
        // 绘制图片
        ctx.draw(Image(nsImage: image), in: imageRect)
    }
    
    private func drawTextLayer(_ layer: TextLayer, in context: GraphicsContext, offsetX: CGFloat, offsetY: CGFloat) {
        let frame = layer.frame
        let centerX = offsetX + frame.midX
        let centerY = offsetY + frame.midY
        
        var ctx = context
        
        // 移动到中心点并旋转
        ctx.translateBy(x: centerX, y: centerY)
        ctx.rotate(by: Angle(degrees: layer.rotation))
        
        // 绘制背景（相对于中心点）
        if let bgHex = layer.backgroundColorHex {
            let bgRect = CGRect(x: -frame.width/2, y: -frame.height/2, width: frame.width, height: frame.height)
            ctx.fill(Path(bgRect), with: .color(Color(hex: bgHex)))
        }
        
        // 绘制文本
        let text = Text(layer.text)
            .font(.custom(layer.fontName, size: layer.fontSize))
            .foregroundColor(Color(hex: layer.colorHex))
        
        ctx.draw(text, at: .zero, anchor: .center)
    }
    
    private func drawStickerLayer(_ layer: StickerLayer, in context: GraphicsContext, offsetX: CGFloat, offsetY: CGFloat) {
        guard case .url(let url) = layer.content else { return }
        guard let image = NSImage(contentsOf: url) else { return }
        
        let frame = layer.frame
        let centerX = offsetX + frame.midX
        let centerY = offsetY + frame.midY
        
        var ctx = context
        
        // 移动到中心点并旋转
        ctx.translateBy(x: centerX, y: centerY)
        ctx.rotate(by: Angle(degrees: layer.rotation))
        
        // 绘制贴纸（相对于中心点）
        let drawRect = CGRect(x: -frame.width/2, y: -frame.height/2, width: frame.width, height: frame.height)
        ctx.draw(Image(nsImage: image), in: drawRect)
    }
}

// ExportablePage不再使用，改用ExportableSpreadView统一处理

// 保留ExportablePage给SaddleStitchExporter使用
struct ExportablePage: View {
    let page: PageModel
    let filteredImages: [LayerID: NSImage]
    let config: PDFExportConfig
    let isLeft: Bool
    
    private var trimWidth: CGFloat { config.pageSize.width / 2 }
    private var trimHeight: CGFloat { config.pageSize.height }
    private var bleed: CGFloat { config.includeBleed ? config.bleedPoints : 0 }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            Rectangle()
                .fill(Color(hex: page.backgroundColorHex))
            
            // Layers
            ZStack(alignment: .topLeading) {
                ForEach(Array(page.layers.enumerated()), id: \.offset) { _, wrapper in
                    ExportableLayerView(
                        wrapper: wrapper,
                        filteredImages: filteredImages
                    )
                }
            }
            .frame(width: trimWidth, height: trimHeight)
            .offset(x: bleed, y: bleed)
        }
        .frame(width: trimWidth + bleed * 2, height: trimHeight + bleed * 2)
    }
}

struct ExportableLayerView: View {
    let wrapper: AnyLayer
    let filteredImages: [LayerID: NSImage]
    
    var body: some View {
        if let photoLayer = wrapper.layer as? PhotoLayer {
            ExportablePhotoLayer(layer: photoLayer, preloadedImage: filteredImages[photoLayer.id])
        } else if let textLayer = wrapper.layer as? TextLayer {
            ExportableTextLayer(layer: textLayer)
        } else if let stickerLayer = wrapper.layer as? StickerLayer {
            ExportableStickerLayer(layer: stickerLayer)
        }
    }
}

// MARK: - Exportable Photo Layer

struct ExportablePhotoLayer: View {
    let layer: PhotoLayer
    let preloadedImage: NSImage?
    
    var body: some View {
        let _ = print("      📷 Photo: frame=\(layer.frame), rotation=\(layer.rotation)")
        
        return Group {
            if let image = preloadedImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .rotationEffect(.degrees(layer.cropRotation))
                    .scaleEffect(layer.cropScale)
                    .offset(layer.cropOffset)
            } else {
                // Fallback: try loading directly (should not happen if preload worked)
                if let nsImage = NSImage(contentsOf: layer.photoUrl) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .rotationEffect(.degrees(layer.cropRotation))
                        .scaleEffect(layer.cropScale)
                        .offset(layer.cropOffset)
                } else {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
            }
        }
        .frame(width: layer.frame.width, height: layer.frame.height)
        .clipped()
        // Apply feathering
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
                if layer.borderStyle == .double {
                    ZStack {
                        RoundedRectangle(cornerRadius: layer.borderCornerRadius)
                            .stroke(Color(hex: layer.borderColorHex), lineWidth: layer.borderWidth)
                        RoundedRectangle(cornerRadius: max(0, layer.borderCornerRadius - 4))
                            .stroke(Color(hex: layer.borderColorHex), lineWidth: max(1, layer.borderWidth / 3))
                            .padding(4)
                    }
                } else if layer.borderStyle == .stamp {
                    StampShape()
                        .stroke(Color(hex: layer.borderColorHex), lineWidth: layer.borderWidth)
                } else {
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
        )
        // Apply shadow
        .shadow(
            color: Color.black.opacity(layer.shadowOpacity),
            radius: layer.shadowRadius,
            x: 0,
            y: layer.shadowRadius / 3
        )
        .rotationEffect(.degrees(layer.rotation))
        .position(x: layer.frame.midX, y: layer.frame.midY)
    }
}

// MARK: - Exportable Text Layer

struct ExportableTextLayer: View {
    let layer: TextLayer
    
    private var swiftUIAlignment: SwiftUI.TextAlignment {
        switch layer.alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
    
    private var frameAlignment: Alignment {
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
            .frame(width: layer.frame.width, height: layer.frame.height, alignment: frameAlignment)
            .background(
                layer.backgroundColorHex != nil
                    ? Color(hex: layer.backgroundColorHex!)
                    : Color.clear
            )
            .rotationEffect(.degrees(layer.rotation))
            .position(x: layer.frame.midX, y: layer.frame.midY)
    }
}

// MARK: - Exportable Sticker Layer

struct ExportableStickerLayer: View {
    let layer: StickerLayer
    
    var body: some View {
        Group {
            switch layer.content {
            case .url(let url):
                if let nsImage = NSImage(contentsOf: url) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
                
            case .systemImage(let name):
                Image(systemName: name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(hex: layer.colorHex ?? "#000000"))
                
            case .emoji(let char):
                Text(char)
                    .font(.system(size: min(layer.frame.width, layer.frame.height) * 0.8))
            }
        }
        .frame(width: layer.frame.width, height: layer.frame.height)
        .shadow(
            color: Color.black.opacity(layer.shadowOpacity),
            radius: layer.shadowRadius,
            x: 0,
            y: layer.shadowRadius / 3
        )
        .rotationEffect(.degrees(layer.rotation))
        .position(x: layer.frame.midX, y: layer.frame.midY)
    }
}

// MARK: - Print Marks Wrapper

/// Wraps content with professional print marks (crop marks, registration, color bars)
struct PrintMarksWrapper<Content: View>: View {
    let content: Content
    let config: PDFExportConfig
    let pageNumber: Int
    let totalPages: Int
    
    private let markColor = Color.black
    private let registrationMarkSize: CGFloat = 10
    
    var body: some View {
        ZStack {
            // White background for marks area
            Color.white
            
            // Main content centered
            content
            
            // Crop Marks
            if config.includeCropMarks {
                cropMarksOverlay
            }
            
            // Registration Marks
            if config.includeRegistrationMarks {
                registrationMarksOverlay
            }
            
            // Color Bars
            if config.includeColorBars {
                colorBarsOverlay
            }
            
            // Page Info
            if config.includePageInfo {
                pageInfoOverlay
            }
        }
        .frame(
            width: config.totalPageSize.width,
            height: config.totalPageSize.height
        )
    }
    
    // MARK: - Crop Marks
    
    private var cropMarksOverlay: some View {
        let margin = config.printMarksMargin
        let markLength = config.cropMarkLength
        let offset = config.cropMarkOffset
        // 裁切线应该标记在成品尺寸（TrimBox）的边缘，不是BleedBox
        let bleed = config.includeBleed ? config.bleedPoints : 0
        let trimWidth = config.pageSize.width  // 成品尺寸
        let trimHeight = config.pageSize.height
        // 内容区域（含出血）的起始位置
        let contentStartX = margin
        let contentStartY = margin
        // 成品区域的起始位置（在出血区域内）
        let trimStartX = contentStartX + bleed
        let trimStartY = contentStartY + bleed
        
        return ZStack {
            // Top-Left corner (成品区域左上角)
            Path { path in
                // Horizontal
                path.move(to: CGPoint(x: trimStartX - offset - markLength, y: trimStartY))
                path.addLine(to: CGPoint(x: trimStartX - offset, y: trimStartY))
                // Vertical
                path.move(to: CGPoint(x: trimStartX, y: trimStartY - offset - markLength))
                path.addLine(to: CGPoint(x: trimStartX, y: trimStartY - offset))
            }
            .stroke(markColor, lineWidth: 0.5)
            
            // Top-Right corner (成品区域右上角)
            Path { path in
                let x = trimStartX + trimWidth
                // Horizontal
                path.move(to: CGPoint(x: x + offset, y: trimStartY))
                path.addLine(to: CGPoint(x: x + offset + markLength, y: trimStartY))
                // Vertical
                path.move(to: CGPoint(x: x, y: trimStartY - offset - markLength))
                path.addLine(to: CGPoint(x: x, y: trimStartY - offset))
            }
            .stroke(markColor, lineWidth: 0.5)
            
            // Bottom-Left corner (成品区域左下角)
            Path { path in
                let y = trimStartY + trimHeight
                // Horizontal
                path.move(to: CGPoint(x: trimStartX - offset - markLength, y: y))
                path.addLine(to: CGPoint(x: trimStartX - offset, y: y))
                // Vertical
                path.move(to: CGPoint(x: trimStartX, y: y + offset))
                path.addLine(to: CGPoint(x: trimStartX, y: y + offset + markLength))
            }
            .stroke(markColor, lineWidth: 0.5)
            
            // Bottom-Right corner (成品区域右下角)
            Path { path in
                let x = trimStartX + trimWidth
                let y = trimStartY + trimHeight
                // Horizontal
                path.move(to: CGPoint(x: x + offset, y: y))
                path.addLine(to: CGPoint(x: x + offset + markLength, y: y))
                // Vertical
                path.move(to: CGPoint(x: x, y: y + offset))
                path.addLine(to: CGPoint(x: x, y: y + offset + markLength))
            }
            .stroke(markColor, lineWidth: 0.5)
            
            // Center spine marks (书脊位置 - 跨页中间)
            Path { path in
                let centerX = trimStartX + trimWidth / 2
                // Top
                path.move(to: CGPoint(x: centerX, y: trimStartY - offset - markLength))
                path.addLine(to: CGPoint(x: centerX, y: trimStartY - offset))
                // Bottom
                path.move(to: CGPoint(x: centerX, y: trimStartY + trimHeight + offset))
                path.addLine(to: CGPoint(x: centerX, y: trimStartY + trimHeight + offset + markLength))
            }
            .stroke(markColor, lineWidth: 0.5)
        }
    }
    
    // MARK: - Registration Marks
    
    private var registrationMarksOverlay: some View {
        let margin = config.printMarksMargin
        let bleed = config.includeBleed ? config.bleedPoints : 0
        let trimWidth = config.pageSize.width
        let trimHeight = config.pageSize.height
        let trimStartX = margin + bleed
        let trimStartY = margin + bleed
        let size = registrationMarkSize
        
        return ZStack {
            // Top center (成品区域上方)
            RegistrationMark(size: size)
                .position(x: trimStartX + trimWidth / 2, y: margin / 2)
            
            // Bottom center (成品区域下方)
            RegistrationMark(size: size)
                .position(x: trimStartX + trimWidth / 2, y: config.totalPageSize.height - margin / 2)
            
            // Left center (成品区域左侧)
            RegistrationMark(size: size)
                .position(x: margin / 2, y: trimStartY + trimHeight / 2)
            
            // Right center (成品区域右侧)
            RegistrationMark(size: size)
                .position(x: config.totalPageSize.width - margin / 2, y: trimStartY + trimHeight / 2)
        }
    }
    
    // MARK: - Color Bars
    
    private var colorBarsOverlay: some View {
        let margin = config.printMarksMargin
        let bleed = config.includeBleed ? config.bleedPoints : 0
        let trimWidth = config.pageSize.width
        let trimStartX = margin + bleed
        let barWidth: CGFloat = 8
        let barHeight: CGFloat = 16
        
        // CMYK + RGB + 灰度条
        let colors: [Color] = [
            .cyan, Color(red: 1, green: 0, blue: 1), .yellow, .black,
            .red, .green, .blue,
            Color(white: 0), Color(white: 0.25), Color(white: 0.5), Color(white: 0.75), .white
        ]
        
        return ZStack {
            // Top color bar - 在margin区域，成品区域上方居中
            HStack(spacing: 1) {
                ForEach(0..<colors.count, id: \.self) { index in
                    Rectangle()
                        .fill(colors[index])
                        .frame(width: barWidth, height: barHeight)
                        .overlay(
                            Rectangle()
                                .stroke(Color.black, lineWidth: 0.25)
                        )
                }
            }
            .position(x: trimStartX + trimWidth / 2, y: margin / 2)
            
            // Bottom color bar - 在margin区域，成品区域下方居中
            HStack(spacing: 1) {
                ForEach(0..<colors.count, id: \.self) { index in
                    Rectangle()
                        .fill(colors[index])
                        .frame(width: barWidth, height: barHeight)
                        .overlay(
                            Rectangle()
                                .stroke(Color.black, lineWidth: 0.25)
                        )
                }
            }
            .position(x: trimStartX + trimWidth / 2, y: config.totalPageSize.height - margin / 2)
        }
        .frame(width: config.totalPageSize.width, height: config.totalPageSize.height)
    }
    
    // MARK: - Page Info
    
    private var pageInfoOverlay: some View {
        let margin = config.printMarksMargin
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = dateFormatter.string(from: Date())
        
        return VStack {
            Spacer()
            
            HStack {
                Text("Page \(pageNumber) of \(totalPages)")
                    .font(.system(size: 6))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("Exported: \(dateString) • \(Int(config.dpi)) DPI")
                    .font(.system(size: 6))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, margin + 10)
            .padding(.bottom, 4)
        }
        .frame(width: config.totalPageSize.width, height: config.totalPageSize.height)
    }
}

// MARK: - Registration Mark Shape

struct RegistrationMark: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(Color.black, lineWidth: 0.5)
                .frame(width: size, height: size)
            
            // Cross
            Path { path in
                // Horizontal
                path.move(to: CGPoint(x: -size/2, y: 0))
                path.addLine(to: CGPoint(x: size/2, y: 0))
                // Vertical
                path.move(to: CGPoint(x: 0, y: -size/2))
                path.addLine(to: CGPoint(x: 0, y: size/2))
            }
            .stroke(Color.black, lineWidth: 0.5)
            
            // Inner circle
            Circle()
                .stroke(Color.black, lineWidth: 0.5)
                .frame(width: size * 0.4, height: size * 0.4)
        }
        .frame(width: size, height: size)
    }
}
