import Foundation
import AppKit
import SwiftUI
import PDFKit

/// 顺序单页导出器（用于所有装订类型）
/// 按照页面顺序导出，每页PDF = 一个单页（不是跨页）
/// 打印公司会自己做拼版和装订
@MainActor
public class SequentialDoubleSidedExporter {
    
    /// 导出为顺序单页PDF（打印公司会自己拼版）
    /// - Parameters:
    ///   - bookStructure: 书籍结构
    ///   - config: PDF导出配置
    ///   - url: 输出文件URL
    ///   - progressHandler: 进度回调
    /// - Returns: 导出的总页数
    public static func exportDoubleSided(
        bookStructure: BookStructure,
        config: PDFExportConfig,
        to url: URL,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> Int {
        
        // 1. 收集所有单页（按顺序）
        var allPages: [PageModel] = []
        
        // 封面
        allPages.append(bookStructure.frontCover)
        
        // 内页
        for spread in bookStructure.innerSpreads {
            allPages.append(spread.left)
            allPages.append(spread.right)
        }
        
        // 封底
        allPages.append(bookStructure.backCover)
        
        // 2. 创建PDF文档
        let pdfDocument = PDFDocument()
        
        // 3. 按顺序导出每个单页
        for (index, page) in allPages.enumerated() {
            if let pageImage = await renderSinglePage(
                page: page,
                config: config,
                pageNumber: index + 1,
                totalPages: allPages.count
            ) {
                if let pdfPage = PDFPage(image: pageImage) {
                    pdfDocument.insert(pdfPage, at: index)
                }
            }
            
            progressHandler?(Double(index + 1) / Double(allPages.count))
        }
        
        // 4. 保存PDF
        pdfDocument.write(to: url)
        
        print("✅ 顺序单页PDF导出完成: \(allPages.count) 页 -> \(url.path)")
        print("   每页 = 单个页面（打印公司会自己拼版）")
        
        return allPages.count
    }
    
    /// 渲染单个页面
    private static func renderSinglePage(
        page: PageModel,
        config: PDFExportConfig,
        pageNumber: Int,
        totalPages: Int
    ) async -> NSImage? {
        
        // 预加载滤镜图片
        let filteredImages = await SpreadPDFExporter.preloadFilteredImages(for: page)
        
        // 创建单页视图
        let pageView = ExportablePageView(
            page: page,
            filteredImages: filteredImages,
            config: config
        )
        
        // 如果需要，包装印刷标记
        let finalView: AnyView
        if config.includeCropMarks || config.includeRegistrationMarks || config.includeColorBars {
            finalView = AnyView(
                SinglePagePrintMarksWrapper(
                    content: pageView,
                    config: config,
                    pageNumber: pageNumber,
                    totalPages: totalPages
                )
            )
        } else {
            finalView = AnyView(pageView)
        }
        
        // 计算尺寸（单页）
        let totalWidth = config.includeCropMarks ? config.totalPageSize.width : config.fullPageSize.width
        let totalHeight = config.includeCropMarks ? config.totalPageSize.height : config.fullPageSize.height
        
        // 渲染
        let renderer = ImageRenderer(content: finalView
            .frame(width: totalWidth, height: totalHeight))
        renderer.scale = config.scaleFactor
        
        guard let cgImage = renderer.cgImage else { return nil }
        
        let size = NSSize(
            width: totalWidth * config.scaleFactor,
            height: totalHeight * config.scaleFactor
        )
        
        return NSImage(cgImage: cgImage, size: size)
    }
}

// MARK: - Single Page Print Marks Wrapper

/// 单页印刷标记包装器（不是跨页）
struct SinglePagePrintMarksWrapper<Content: View>: View {
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
        let contentWidth = config.fullPageSize.width
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
        }
    }
    
    // MARK: - Registration Marks
    
    private var registrationMarksOverlay: some View {
        let margin = config.printMarksMargin
        let contentWidth = config.fullPageSize.width
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
        let contentWidth = config.fullPageSize.width
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
        .frame(width: config.totalPageSize.width, height: config.totalPageSize.height)
    }
}

// MARK: - Exportable Page View (单页)

struct ExportablePageView: View {
    let page: PageModel
    let filteredImages: [LayerID: NSImage]
    let config: PDFExportConfig
    
    var body: some View {
        ZStack {
            // 背景
            Rectangle()
                .fill(Color(hex: page.backgroundColorHex))
            
            // 背景类型（渐变/图案/纹理）
            if page.backgroundType == .gradient, let gradientColors = page.gradientColors, !gradientColors.isEmpty {
                LinearGradient(
                    colors: gradientColors.map { Color(hex: $0) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            
            // 图层 - 使用与SpreadPDFExporter相同的方式
            ForEach(Array(page.layers.enumerated()), id: \.offset) { _, wrapper in
                if let photoLayer = wrapper.layer as? PhotoLayer {
                    if let image = filteredImages[photoLayer.id] {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .rotationEffect(.degrees(photoLayer.cropRotation))
                            .scaleEffect(photoLayer.cropScale)
                            .offset(photoLayer.cropOffset)
                            .frame(width: photoLayer.frame.width, height: photoLayer.frame.height)
                            .clipped()
                            .rotationEffect(.degrees(photoLayer.rotation))
                            .position(x: photoLayer.frame.midX, y: photoLayer.frame.midY)
                    }
                } else if let textLayer = wrapper.layer as? TextLayer {
                    Text(textLayer.text)
                        .font(.system(size: textLayer.fontSize))
                        .foregroundColor(Color(hex: textLayer.colorHex))
                        .rotationEffect(.degrees(textLayer.rotation))
                        .position(x: textLayer.frame.midX, y: textLayer.frame.midY)
                } else if let stickerLayer = wrapper.layer as? StickerLayer {
                    Group {
                        switch stickerLayer.content {
                        case .url(let url):
                            if let nsImage = NSImage(contentsOf: url) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        case .systemImage(let name):
                            Image(systemName: name)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .emoji(let char):
                            Text(char)
                                .font(.system(size: min(stickerLayer.frame.width, stickerLayer.frame.height) * 0.8))
                        }
                    }
                    .frame(width: stickerLayer.frame.width, height: stickerLayer.frame.height)
                    .rotationEffect(.degrees(stickerLayer.rotation))
                    .position(x: stickerLayer.frame.midX, y: stickerLayer.frame.midY)
                }
            }
        }
        .frame(width: config.fullPageSize.width, height: config.fullPageSize.height)
    }
}
