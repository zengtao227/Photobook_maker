import Foundation
import AppKit
import SwiftUI

// MARK: - NSColor Hex Extension

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

private extension TextLayer.TextAlignment {
    var nsTextAlignment: NSTextAlignment {
        switch self {
        case .leading:
            return .left
        case .center:
            return .center
        case .trailing:
            return .right
        }
    }
}

/// Professional PDF exporter using CGPDFContext with proper PDF boxes
/// 使用CGPDFContext和标准PDF Box规范（MediaBox, TrimBox, BleedBox）
@MainActor
public class CGPDFExporter {

    /// Export spreads to PDF with proper PDF boxes
    public static func exportBook(
        spreads: [(left: PageModel, right: PageModel)],
        config: PDFExportConfig,
        to url: URL,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws {

        // 计算PDF Boxes（基于跨页尺寸）
        var trimBox = CGRect(origin: .zero, size: config.pageSize)
        let bleedBox = config.includeBleed ? trimBox.insetBy(
            dx: -config.bleedPoints,
            dy: -config.bleedPoints
        ) : trimBox
        let mediaBox = (config.includeCropMarks || config.includeRegistrationMarks || config.includeColorBars)
            ? bleedBox.insetBy(dx: -config.printMarksMargin, dy: -config.printMarksMargin)
            : bleedBox

        print("📊 PDF Boxes:")
        print("   TrimBox (成品): \(trimBox)")
        print("   BleedBox (含出血): \(bleedBox)")
        print("   MediaBox (含标记): \(mediaBox)")

        // 创建PDF上下文
        var mediaBoxVar = mediaBox
        guard let pdfContext = CGContext(url as CFURL, mediaBox: &mediaBoxVar, nil) else {
            throw ExportError.contextCreationFailed
        }

        // 设置PDF元数据
        let pdfInfo: [String: Any] = [
            kCGPDFContextTitle as String: "Photobook",
            kCGPDFContextCreator as String: "PhotobookApp",
            kCGPDFContextAuthor as String: "User"
        ]

        // 导出每一页
        for (index, spread) in spreads.enumerated() {
            // 预加载滤镜图片
            let leftImages = await SpreadPDFExporter.preloadFilteredImages(for: spread.left)
            let rightImages = await SpreadPDFExporter.preloadFilteredImages(for: spread.right)

            // 开始新页面，设置PDF Boxes
            var pageInfo: [String: Any] = pdfInfo

            // 设置TrimBox和BleedBox
            if config.includeBleed {
                pageInfo[kCGPDFContextTrimBox as String] = NSData(bytes: &trimBox, length: MemoryLayout<CGRect>.size)
                var bleedBoxVar = bleedBox
                pageInfo[kCGPDFContextBleedBox as String] = NSData(bytes: &bleedBoxVar, length: MemoryLayout<CGRect>.size)
            }

            pdfContext.beginPDFPage(pageInfo as CFDictionary)

            // 保存图形状态
            pdfContext.saveGState()

            // Core Graphics默认是Y-up。这里统一翻转成Y-down，让后续坐标与SwiftUI/PageModel一致。
            pdfContext.translateBy(x: 0, y: mediaBox.height)
            pdfContext.scaleBy(x: 1.0, y: -1.0)

            // 计算偏移量（从MediaBox到TrimBox）
            let offsetX = (mediaBox.width - trimBox.width) / 2
            let offsetY = (mediaBox.height - trimBox.height) / 2

            // 绘制背景（延伸到BleedBox）
            if config.includeBleed {
                // 背景填充BleedBox
                pdfContext.saveGState()
                pdfContext.translateBy(x: offsetX - config.bleedPoints, y: offsetY - config.bleedPoints)

                // 左页背景
                let leftColor = NSColor(hex: spread.left.backgroundColorHex)
                pdfContext.setFillColor(leftColor.cgColor)
                pdfContext.fill(CGRect(
                    x: 0,
                    y: 0,
                    width: config.pageSize.width / 2 + config.bleedPoints * 2,
                    height: config.pageSize.height + config.bleedPoints * 2
                ))

                // 右页背景
                let rightColor = NSColor(hex: spread.right.backgroundColorHex)
                pdfContext.setFillColor(rightColor.cgColor)
                pdfContext.fill(CGRect(
                    x: config.pageSize.width / 2,
                    y: 0,
                    width: config.pageSize.width / 2 + config.bleedPoints * 2,
                    height: config.pageSize.height + config.bleedPoints * 2
                ))

                pdfContext.restoreGState()
            } else {
                // 背景只填充TrimBox
                pdfContext.saveGState()
                pdfContext.translateBy(x: offsetX, y: offsetY)

                // 左页背景
                let leftColor = NSColor(hex: spread.left.backgroundColorHex)
                pdfContext.setFillColor(leftColor.cgColor)
                pdfContext.fill(CGRect(
                    x: 0,
                    y: 0,
                    width: config.pageSize.width / 2,
                    height: config.pageSize.height
                ))

                // 右页背景
                let rightColor = NSColor(hex: spread.right.backgroundColorHex)
                pdfContext.setFillColor(rightColor.cgColor)
                pdfContext.fill(CGRect(
                    x: config.pageSize.width / 2,
                    y: 0,
                    width: config.pageSize.width / 2,
                    height: config.pageSize.height
                ))

                pdfContext.restoreGState()
            }

            // 绘制图层（基于TrimBox坐标系统）
            pdfContext.saveGState()
            pdfContext.translateBy(x: offsetX, y: offsetY)

            // 左页图层
            drawLayers(
                spread.left.layers,
                filteredImages: leftImages,
                in: pdfContext,
                pageWidth: config.pageSize.width / 2,
                pageHeight: config.pageSize.height
            )

            // 右页图层（偏移半个跨页宽度）
            pdfContext.saveGState()
            pdfContext.translateBy(x: config.pageSize.width / 2, y: 0)
            drawLayers(
                spread.right.layers,
                filteredImages: rightImages,
                in: pdfContext,
                pageWidth: config.pageSize.width / 2,
                pageHeight: config.pageSize.height
            )
            pdfContext.restoreGState()

            pdfContext.restoreGState()

            // 绘制裁切标记（如果需要）
            if config.includeCropMarks {
                drawCropMarks(
                    in: pdfContext,
                    trimBox: trimBox,
                    mediaBox: mediaBox,
                    config: config
                )
            }

            if config.includeRegistrationMarks {
                drawRegistrationMarks(
                    in: pdfContext,
                    trimBox: trimBox,
                    mediaBox: mediaBox
                )
            }

            if config.includeColorBars {
                drawColorBars(
                    in: pdfContext,
                    trimBox: trimBox,
                    mediaBox: mediaBox,
                    config: config
                )
            }

            if config.includePageInfo {
                drawPageInfo(
                    in: pdfContext,
                    mediaBox: mediaBox,
                    config: config,
                    pageNumber: index + 1,
                    totalPages: spreads.count
                )
            }

            // 恢复图形状态
            pdfContext.restoreGState()

            // 结束页面
            pdfContext.endPDFPage()

            // 报告进度
            progressHandler?(Double(index + 1) / Double(spreads.count))
        }

        // 关闭PDF
        pdfContext.closePDF()

        print("✅ CGPDF导出完成: \(spreads.count)页")
    }

    // MARK: - 绘制图层

    private static func drawLayers(
        _ layers: [AnyLayer],
        filteredImages: [LayerID: NSImage],
        in context: CGContext,
        pageWidth: CGFloat,
        pageHeight: CGFloat
    ) {
        for wrapper in layers {
            if let photoLayer = wrapper.layer as? PhotoLayer {
                drawPhotoLayer(photoLayer, filteredImage: filteredImages[photoLayer.id], in: context, pageHeight: pageHeight)
            } else if let textLayer = wrapper.layer as? TextLayer {
                drawTextLayer(textLayer, in: context, pageHeight: pageHeight)
            } else if let stickerLayer = wrapper.layer as? StickerLayer {
                drawStickerLayer(stickerLayer, in: context, pageHeight: pageHeight)
            }
        }
    }

    private static func drawPhotoLayer(_ layer: PhotoLayer, filteredImage: NSImage?, in context: CGContext, pageHeight: CGFloat) {
        guard let image = filteredImage ?? NSImage(contentsOf: layer.photoUrl) else { return }
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        context.saveGState()

        // exportBook 已经把PDF坐标系翻成Y-down，直接使用SwiftUI/PageModel坐标。
        let frame = layer.frame

        context.translateBy(x: frame.midX, y: frame.midY)
        context.rotate(by: layer.rotation * .pi / 180)

        let drawRect = CGRect(
            x: -frame.width / 2,
            y: -frame.height / 2,
            width: frame.width,
            height: frame.height
        )
        let effectiveCornerRadius = max(layer.borderCornerRadius, layer.feathering / 2)
        let roundedPath = CGPath(
            roundedRect: drawRect,
            cornerWidth: effectiveCornerRadius,
            cornerHeight: effectiveCornerRadius,
            transform: nil
        )

        // SwiftUI 的 shadow 在 mask/border 之后作用于整个相框。
        // CGContext 里先给相框形状画一次透明度很低的填充以生成同方向投影。
        if layer.shadowOpacity > 0 {
            context.saveGState()
            context.setShadow(
                offset: CGSize(width: 0, height: layer.shadowRadius / 3),
                blur: layer.shadowRadius,
                color: NSColor.black.withAlphaComponent(layer.shadowOpacity).cgColor
            )
            context.setFillColor(NSColor.white.cgColor)
            context.addPath(roundedPath)
            context.fillPath()
            context.restoreGState()
        }

        // 裁剪到图层边界；feathering 在 CGPDFExporter 中用增大圆角半径近似。
        context.addPath(roundedPath)
        context.clip()

        // 应用裁剪变换。坐标系已经是Y-down，所以cropOffset.height不再取反。
        context.saveGState()
        context.translateBy(x: layer.cropOffset.width, y: layer.cropOffset.height)
        context.scaleBy(x: layer.cropScale, y: layer.cropScale)
        context.rotate(by: layer.cropRotation * .pi / 180)

        let imageSize = image.size
        let imageAspect = imageSize.width / imageSize.height
        let frameAspect = frame.width / frame.height

        let imageDrawRect: CGRect
        if imageAspect > frameAspect {
            let scaledWidth = frame.height * imageAspect
            imageDrawRect = CGRect(
                x: -(scaledWidth / 2),
                y: -frame.height / 2,
                width: scaledWidth,
                height: frame.height
            )
        } else {
            let scaledHeight = frame.width / imageAspect
            imageDrawRect = CGRect(
                x: -frame.width / 2,
                y: -(scaledHeight / 2),
                width: frame.width,
                height: scaledHeight
            )
        }

        drawCGImageUpright(cgImage, in: imageDrawRect, context: context)
        context.restoreGState()

        // 绘制边框。边框本身不应继承照片投影。
        if layer.borderWidth > 0 {
            context.saveGState()
            context.setShadow(offset: .zero, blur: 0, color: nil)
            context.setStrokeColor(NSColor(hex: layer.borderColorHex).cgColor)
            context.setLineWidth(layer.borderWidth)

            switch layer.borderStyle {
            case .double:
                context.addPath(roundedPath)
                context.strokePath()

                let innerRect = drawRect.insetBy(dx: 4, dy: 4)
                let innerCornerRadius = max(0, effectiveCornerRadius - 4)
                let innerPath = CGPath(
                    roundedRect: innerRect,
                    cornerWidth: innerCornerRadius,
                    cornerHeight: innerCornerRadius,
                    transform: nil
                )
                context.addPath(innerPath)
                context.setLineWidth(max(1, layer.borderWidth / 3))
                context.strokePath()

            case .dashed:
                context.setLineDash(phase: 0, lengths: [6, 3])
                context.addPath(roundedPath)
                context.strokePath()

            default:
                // solid, dotted, and stamp use a solid fallback in this exporter for now.
                context.addPath(roundedPath)
                context.strokePath()
            }

            context.restoreGState()
        }

        context.restoreGState()
    }

    private static func drawTextLayer(_ layer: TextLayer, in context: CGContext, pageHeight: CGFloat) {
        let frame = layer.frame

        context.saveGState()

        // exportBook 已经把PDF坐标系翻成Y-down，直接使用SwiftUI/PageModel坐标。
        context.translateBy(x: frame.midX, y: frame.midY)
        context.rotate(by: layer.rotation * .pi / 180)

        // 绘制背景
        if let bgHex = layer.backgroundColorHex {
            let bgColor = NSColor(hex: bgHex)
            context.setFillColor(bgColor.cgColor)
            context.fill(CGRect(x: -frame.width / 2, y: -frame.height / 2, width: frame.width, height: frame.height))
        }

        // 绘制文本
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = layer.alignment.nsTextAlignment
        paragraphStyle.lineBreakMode = .byWordWrapping

        var traits: NSFontDescriptor.SymbolicTraits = []
        if layer.isBold {
            traits.insert(.bold)
        }
        if layer.isItalic {
            traits.insert(.italic)
        }

        let descriptor = NSFontDescriptor(name: layer.fontName, size: CGFloat(layer.fontSize))
        let fontDescriptor = traits.isEmpty ? descriptor : descriptor.withSymbolicTraits(traits)
        let font = NSFont(descriptor: fontDescriptor, size: CGFloat(layer.fontSize))
            ?? NSFont(name: layer.fontName, size: CGFloat(layer.fontSize))
            ?? NSFont.systemFont(ofSize: CGFloat(layer.fontSize))

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(hex: layer.colorHex),
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSAttributedString(string: layer.text, attributes: attributes)
        let textRect = CGRect(x: -frame.width / 2, y: -frame.height / 2, width: frame.width, height: frame.height)
        drawAttributedString(attributedString, in: textRect, context: context)

        context.restoreGState()
    }

    private static func drawStickerLayer(_ layer: StickerLayer, in context: CGContext, pageHeight: CGFloat) {
        let frame = layer.frame

        context.saveGState()
        context.translateBy(x: frame.midX, y: frame.midY)
        context.rotate(by: layer.rotation * .pi / 180)

        let drawRect = CGRect(x: -frame.width / 2, y: -frame.height / 2, width: frame.width, height: frame.height)

        if layer.shadowOpacity > 0 {
            context.setShadow(
                offset: CGSize(width: 0, height: layer.shadowRadius / 3),
                blur: layer.shadowRadius,
                color: NSColor.black.withAlphaComponent(layer.shadowOpacity).cgColor
            )
        }

        switch layer.content {
        case .url(let url):
            if let image = NSImage(contentsOf: url),
               let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                let fitRect = aspectFitRect(imageSize: image.size, in: drawRect)
                drawCGImageUpright(cgImage, in: fitRect, context: context)
            }

        case .systemImage(let name):
            if let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
                let configured = symbol.withSymbolConfiguration(
                    NSImage.SymbolConfiguration(pointSize: min(frame.width, frame.height), weight: .regular)
                ) ?? symbol
                if let cgImage = configured.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    let fitRect = aspectFitRect(imageSize: configured.size, in: drawRect)
                    drawCGImageUpright(cgImage, in: fitRect, context: context)
                }
            }

        case .emoji(let char):
            let fontSize = min(frame.width, frame.height) * 0.8
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attributedString = NSAttributedString(
                string: char,
                attributes: [
                    .font: NSFont.systemFont(ofSize: fontSize),
                    .foregroundColor: NSColor(hex: layer.colorHex ?? "#000000"),
                    .paragraphStyle: paragraphStyle
                ]
            )
            drawAttributedString(attributedString, in: drawRect, context: context)
        }

        context.restoreGState()
    }

    private static func aspectFitRect(imageSize: CGSize, in rect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return rect }

        let imageRatio = imageSize.width / imageSize.height
        let rectRatio = rect.width / rect.height

        if imageRatio > rectRatio {
            let height = rect.width / imageRatio
            return CGRect(
                x: rect.minX,
                y: rect.minY + (rect.height - height) / 2,
                width: rect.width,
                height: height
            )
        } else {
            let width = rect.height * imageRatio
            return CGRect(
                x: rect.minX + (rect.width - width) / 2,
                y: rect.minY,
                width: width,
                height: rect.height
            )
        }
    }

    private static func drawCGImageUpright(_ image: CGImage, in rect: CGRect, context: CGContext) {
        context.saveGState()
        context.translateBy(x: rect.minX, y: rect.maxY)
        context.scaleBy(x: 1, y: -1)
        context.draw(image, in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
        context.restoreGState()
    }

    private static func drawAttributedString(_ string: NSAttributedString, in rect: CGRect, context: CGContext) {
        context.saveGState()
        context.translateBy(x: 0, y: rect.midY * 2)
        context.scaleBy(x: 1.0, y: -1.0)

        let flippedRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height)
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        string.draw(in: flippedRect)
        NSGraphicsContext.restoreGraphicsState()

        context.restoreGState()
    }

    // MARK: - 绘制裁切标记

    private static func drawCropMarks(
        in context: CGContext,
        trimBox: CGRect,
        mediaBox: CGRect,
        config: PDFExportConfig
    ) {
        let offsetX = (mediaBox.width - trimBox.width) / 2
        let offsetY = (mediaBox.height - trimBox.height) / 2
        let markLength = config.cropMarkLength
        let markOffset = config.cropMarkOffset

        context.saveGState()
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(0.5)

        // 左上角
        context.move(to: CGPoint(x: offsetX - markOffset - markLength, y: offsetY))
        context.addLine(to: CGPoint(x: offsetX - markOffset, y: offsetY))
        context.strokePath()

        context.move(to: CGPoint(x: offsetX, y: offsetY - markOffset - markLength))
        context.addLine(to: CGPoint(x: offsetX, y: offsetY - markOffset))
        context.strokePath()

        // 右上角
        let rightX = offsetX + trimBox.width
        context.move(to: CGPoint(x: rightX + markOffset, y: offsetY))
        context.addLine(to: CGPoint(x: rightX + markOffset + markLength, y: offsetY))
        context.strokePath()

        context.move(to: CGPoint(x: rightX, y: offsetY - markOffset - markLength))
        context.addLine(to: CGPoint(x: rightX, y: offsetY - markOffset))
        context.strokePath()

        // 左下角
        let bottomY = offsetY + trimBox.height
        context.move(to: CGPoint(x: offsetX - markOffset - markLength, y: bottomY))
        context.addLine(to: CGPoint(x: offsetX - markOffset, y: bottomY))
        context.strokePath()

        context.move(to: CGPoint(x: offsetX, y: bottomY + markOffset))
        context.addLine(to: CGPoint(x: offsetX, y: bottomY + markOffset + markLength))
        context.strokePath()

        // 右下角
        context.move(to: CGPoint(x: rightX + markOffset, y: bottomY))
        context.addLine(to: CGPoint(x: rightX + markOffset + markLength, y: bottomY))
        context.strokePath()

        context.move(to: CGPoint(x: rightX, y: bottomY + markOffset))
        context.addLine(to: CGPoint(x: rightX, y: bottomY + markOffset + markLength))
        context.strokePath()

        // 中间书脊标记
        let centerX = offsetX + trimBox.width / 2
        context.move(to: CGPoint(x: centerX, y: offsetY - markOffset - markLength))
        context.addLine(to: CGPoint(x: centerX, y: offsetY - markOffset))
        context.strokePath()

        context.move(to: CGPoint(x: centerX, y: bottomY + markOffset))
        context.addLine(to: CGPoint(x: centerX, y: bottomY + markOffset + markLength))
        context.strokePath()

        context.restoreGState()
    }

    private static func drawRegistrationMarks(in context: CGContext, trimBox: CGRect, mediaBox: CGRect) {
        let offsetX = (mediaBox.width - trimBox.width) / 2
        let offsetY = (mediaBox.height - trimBox.height) / 2
        let size: CGFloat = 10

        let centers = [
            CGPoint(x: offsetX + trimBox.width / 2, y: offsetY / 2),
            CGPoint(x: offsetX + trimBox.width / 2, y: mediaBox.height - offsetY / 2),
            CGPoint(x: offsetX / 2, y: offsetY + trimBox.height / 2),
            CGPoint(x: mediaBox.width - offsetX / 2, y: offsetY + trimBox.height / 2)
        ]

        context.saveGState()
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(0.5)

        for center in centers {
            let outerRect = CGRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size)
            let innerRect = outerRect.insetBy(dx: size * 0.3, dy: size * 0.3)

            context.strokeEllipse(in: outerRect)
            context.strokeEllipse(in: innerRect)

            context.move(to: CGPoint(x: center.x - size / 2, y: center.y))
            context.addLine(to: CGPoint(x: center.x + size / 2, y: center.y))
            context.strokePath()

            context.move(to: CGPoint(x: center.x, y: center.y - size / 2))
            context.addLine(to: CGPoint(x: center.x, y: center.y + size / 2))
            context.strokePath()
        }

        context.restoreGState()
    }

    private static func drawColorBars(
        in context: CGContext,
        trimBox: CGRect,
        mediaBox: CGRect,
        config: PDFExportConfig
    ) {
        let offsetX = (mediaBox.width - trimBox.width) / 2
        let barWidth: CGFloat = 8
        let barHeight: CGFloat = 16
        let spacing: CGFloat = 1
        let colors: [NSColor] = [
            .cyan,
            .magenta,
            .yellow,
            .black,
            .red,
            .green,
            .blue,
            NSColor(white: 0, alpha: 1),
            NSColor(white: 0.25, alpha: 1),
            NSColor(white: 0.5, alpha: 1),
            NSColor(white: 0.75, alpha: 1),
            .white
        ]
        let totalWidth = CGFloat(colors.count) * barWidth + CGFloat(colors.count - 1) * spacing
        let startX = offsetX + trimBox.width / 2 - totalWidth / 2
        let topY = max(2, config.printMarksMargin / 2 - barHeight / 2)
        let bottomY = mediaBox.height - config.printMarksMargin / 2 - barHeight / 2

        func drawBar(y: CGFloat) {
            for (index, color) in colors.enumerated() {
                let x = startX + CGFloat(index) * (barWidth + spacing)
                let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                context.setFillColor(color.cgColor)
                context.fill(rect)
                context.setStrokeColor(NSColor.black.cgColor)
                context.setLineWidth(0.25)
                context.stroke(rect)
            }
        }

        context.saveGState()
        drawBar(y: topY)
        drawBar(y: bottomY)
        context.restoreGState()
    }

    private static func drawPageInfo(
        in context: CGContext,
        mediaBox: CGRect,
        config: PDFExportConfig,
        pageNumber: Int,
        totalPages: Int
    ) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = dateFormatter.string(from: Date())

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 6),
            .foregroundColor: NSColor.gray,
            .paragraphStyle: paragraphStyle
        ]

        let text = "Page \(pageNumber) of \(totalPages)    Exported: \(dateString) • \(Int(config.dpi)) DPI"
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let rect = CGRect(x: config.printMarksMargin + 10, y: mediaBox.height - 14, width: mediaBox.width - (config.printMarksMargin + 10) * 2, height: 10)
        drawAttributedString(attributedString, in: rect, context: context)
    }

    enum ExportError: LocalizedError {
        case contextCreationFailed

        var errorDescription: String? {
            switch self {
            case .contextCreationFailed:
                return "Failed to create PDF context"
            }
        }
    }
}
