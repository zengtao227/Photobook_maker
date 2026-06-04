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

            // Core Graphics使用左下角为原点，需要翻转Y轴
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

        // 转换坐标：SwiftUI使用左上角原点，Core Graphics使用左下角原点
        let frame = layer.frame
        let yFlipped = pageHeight - frame.maxY

        // 移动到图层位置
        context.translateBy(x: frame.midX, y: yFlipped + frame.height / 2)

        // 应用旋转
        context.rotate(by: layer.rotation * .pi / 180)

        // 绘制图片（居中）
        let drawRect = CGRect(
            x: -frame.width / 2,
            y: -frame.height / 2,
            width: frame.width,
            height: frame.height
        )

        // 裁剪到图层边界
        context.clip(to: drawRect)

        // 应用裁剪变换
        context.saveGState()
        context.translateBy(x: layer.cropOffset.width, y: -layer.cropOffset.height)
        context.scaleBy(x: layer.cropScale, y: layer.cropScale)
        context.rotate(by: layer.cropRotation * .pi / 180)

        // 计算图片绘制尺寸（保持宽高比，填充frame）
        let imageSize = image.size
        let imageAspect = imageSize.width / imageSize.height
        let frameAspect = frame.width / frame.height

        var imageDrawRect = drawRect
        if imageAspect > frameAspect {
            // 图片更宽，按高度缩放
            let scaledWidth = frame.height * imageAspect
            imageDrawRect = CGRect(
                x: -(scaledWidth / 2),
                y: -frame.height / 2,
                width: scaledWidth,
                height: frame.height
            )
        } else {
            // 图片更高，按宽度缩放
            let scaledHeight = frame.width / imageAspect
            imageDrawRect = CGRect(
                x: -frame.width / 2,
                y: -(scaledHeight / 2),
                width: frame.width,
                height: scaledHeight
            )
        }

        context.draw(cgImage, in: imageDrawRect)
        context.restoreGState()

        context.restoreGState()
    }

    private static func drawTextLayer(_ layer: TextLayer, in context: CGContext, pageHeight: CGFloat) {
        let frame = layer.frame
        let yFlipped = pageHeight - frame.maxY

        context.saveGState()

        // 移动到图层位置
        context.translateBy(x: frame.midX, y: yFlipped + frame.height / 2)
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

        // Core Graphics文本需要再次翻转
        context.saveGState()
        context.translateBy(x: 0, y: frame.height / 2)
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0, y: -frame.height / 2)

        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        attributedString.draw(in: textRect)
        NSGraphicsContext.restoreGraphicsState()

        context.restoreGState()
        context.restoreGState()
    }

    private static func drawStickerLayer(_ layer: StickerLayer, in context: CGContext, pageHeight: CGFloat) {
        // 简化实现：只处理URL类型的贴纸
        guard case .url(let url) = layer.content else { return }
        guard let image = NSImage(contentsOf: url) else { return }
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        let frame = layer.frame
        let yFlipped = pageHeight - frame.maxY

        context.saveGState()
        context.translateBy(x: frame.midX, y: yFlipped + frame.height / 2)
        context.rotate(by: layer.rotation * .pi / 180)

        let drawRect = CGRect(x: -frame.width / 2, y: -frame.height / 2, width: frame.width, height: frame.height)
        context.draw(cgImage, in: drawRect)

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
