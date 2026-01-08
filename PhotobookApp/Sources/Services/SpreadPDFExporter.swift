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
        
        // Calculate pixel dimensions for high DPI
        let pixelWidth = config.fullPageSize.width * 2 * config.scaleFactor
        let pixelHeight = config.fullPageSize.height * config.scaleFactor
        
        // Use ImageRenderer for high-quality rendering
        let renderer = ImageRenderer(content: spreadView
            .frame(width: config.fullPageSize.width * 2, height: config.fullPageSize.height))
        
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
            
            // Calculate dimensions
            let totalWidth = config.includeCropMarks ? config.totalPageSize.width * 2 : config.fullPageSize.width * 2
            let totalHeight = config.includeCropMarks ? config.totalPageSize.height : config.fullPageSize.height
            
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
        print("✅ Book PDF exported: \(spreads.count) spreads to \(url.path)")
    }
    
    // MARK: - Filter Pre-loading
    
    /// Pre-load all filtered images for a page to avoid async placeholders during export
    private static func preloadFilteredImages(for page: PageModel) async -> [LayerID: NSImage] {
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
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Page
            ExportablePage(
                page: leftPage,
                filteredImages: leftFilteredImages,
                config: config,
                isLeft: true
            )
            
            // Right Page
            ExportablePage(
                page: rightPage,
                filteredImages: rightFilteredImages,
                config: config,
                isLeft: false
            )
        }
        .background(Color.white)
    }
}

struct ExportablePage: View {
    let page: PageModel
    let filteredImages: [LayerID: NSImage]
    let config: PDFExportConfig
    let isLeft: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            Rectangle()
                .fill(Color(hex: page.backgroundColorHex))
            
            // Bleed indicator area (will be trimmed in print)
            if config.includeBleed {
                // Content is offset by bleed amount
                ZStack(alignment: .topLeading) {
                    ForEach(page.layers) { wrapper in
                        ExportableLayerView(
                            wrapper: wrapper,
                            filteredImages: filteredImages
                        )
                    }
                }
                .padding(config.bleedPoints) // Content area inset from bleed
            } else {
                // No bleed, layers at origin
                ForEach(page.layers) { wrapper in
                    ExportableLayerView(
                        wrapper: wrapper,
                        filteredImages: filteredImages
                    )
                }
            }
        }
        .frame(width: config.fullPageSize.width, height: config.fullPageSize.height)
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
        Group {
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
            width: config.totalPageSize.width * 2,
            height: config.totalPageSize.height
        )
    }
    
    // MARK: - Crop Marks
    
    private var cropMarksOverlay: some View {
        let margin = config.printMarksMargin
        let markLength = config.cropMarkLength
        let offset = config.cropMarkOffset
        let contentWidth = config.fullPageSize.width * 2
        let contentHeight = config.fullPageSize.height
        
        return ZStack {
            // Top-Left corner
            Path { path in
                // Horizontal
                path.move(to: CGPoint(x: margin - offset - markLength, y: margin))
                path.addLine(to: CGPoint(x: margin - offset, y: margin))
                // Vertical
                path.move(to: CGPoint(x: margin, y: margin - offset - markLength))
                path.addLine(to: CGPoint(x: margin, y: margin - offset))
            }
            .stroke(markColor, lineWidth: 0.5)
            
            // Top-Right corner
            Path { path in
                let x = margin + contentWidth
                // Horizontal
                path.move(to: CGPoint(x: x + offset, y: margin))
                path.addLine(to: CGPoint(x: x + offset + markLength, y: margin))
                // Vertical
                path.move(to: CGPoint(x: x, y: margin - offset - markLength))
                path.addLine(to: CGPoint(x: x, y: margin - offset))
            }
            .stroke(markColor, lineWidth: 0.5)
            
            // Bottom-Left corner
            Path { path in
                let y = margin + contentHeight
                // Horizontal
                path.move(to: CGPoint(x: margin - offset - markLength, y: y))
                path.addLine(to: CGPoint(x: margin - offset, y: y))
                // Vertical
                path.move(to: CGPoint(x: margin, y: y + offset))
                path.addLine(to: CGPoint(x: margin, y: y + offset + markLength))
            }
            .stroke(markColor, lineWidth: 0.5)
            
            // Bottom-Right corner
            Path { path in
                let x = margin + contentWidth
                let y = margin + contentHeight
                // Horizontal
                path.move(to: CGPoint(x: x + offset, y: y))
                path.addLine(to: CGPoint(x: x + offset + markLength, y: y))
                // Vertical
                path.move(to: CGPoint(x: x, y: y + offset))
                path.addLine(to: CGPoint(x: x, y: y + offset + markLength))
            }
            .stroke(markColor, lineWidth: 0.5)
            
            // Center spine marks (for spreads)
            Path { path in
                let centerX = margin + contentWidth / 2
                // Top
                path.move(to: CGPoint(x: centerX, y: margin - offset - markLength))
                path.addLine(to: CGPoint(x: centerX, y: margin - offset))
                // Bottom
                path.move(to: CGPoint(x: centerX, y: margin + contentHeight + offset))
                path.addLine(to: CGPoint(x: centerX, y: margin + contentHeight + offset + markLength))
            }
            .stroke(markColor, lineWidth: 0.5)
        }
    }
    
    // MARK: - Registration Marks
    
    private var registrationMarksOverlay: some View {
        let margin = config.printMarksMargin
        let contentWidth = config.fullPageSize.width * 2
        let contentHeight = config.fullPageSize.height
        let size = registrationMarkSize
        
        return ZStack {
            // Top center
            RegistrationMark(size: size)
                .position(x: margin + contentWidth / 2, y: margin / 2)
            
            // Bottom center
            RegistrationMark(size: size)
                .position(x: margin + contentWidth / 2, y: margin + contentHeight + margin / 2)
            
            // Left center
            RegistrationMark(size: size)
                .position(x: margin / 2, y: margin + contentHeight / 2)
            
            // Right center
            RegistrationMark(size: size)
                .position(x: margin + contentWidth + margin / 2, y: margin + contentHeight / 2)
        }
    }
    
    // MARK: - Color Bars
    
    private var colorBarsOverlay: some View {
        let margin = config.printMarksMargin
        let contentWidth = config.fullPageSize.width * 2
        _ = config.fullPageSize.height // contentHeight reserved for future use
        let barWidth: CGFloat = 8
        let barHeight: CGFloat = 20
        
        let colors: [Color] = [
            .cyan, Color(red: 1, green: 0, blue: 1), .yellow, .black,
            .red, .green, .blue,
            Color(white: 0.25), Color(white: 0.5), Color(white: 0.75), .white
        ]
        
        return VStack {
            // Top color bar
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
            .position(x: margin + contentWidth / 2, y: margin / 2 - 5)
            
            Spacer()
            
            // Bottom color bar
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
            .position(x: margin + contentWidth / 2, y: margin / 2 + 5)
        }
        .frame(height: config.totalPageSize.height)
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
        .frame(width: config.totalPageSize.width * 2, height: config.totalPageSize.height)
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
