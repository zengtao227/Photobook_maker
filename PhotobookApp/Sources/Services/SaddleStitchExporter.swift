import Foundation
import AppKit
import SwiftUI
import PDFKit

// MARK: - Saddle Stitch Imposition

/// Handles saddle stitch (骑马钉) imposition for booklet printing
/// 
/// Saddle stitch binding requires special page ordering:
/// - Total pages must be multiple of 4
/// - Pages are printed on sheets that fold in half
/// - Outer sheet wraps inner sheets
///
/// Example for 12 pages:
/// Sheet 1 (outer): Front: [12, 1], Back: [2, 11]
/// Sheet 2:         Front: [10, 3], Back: [4, 9]
/// Sheet 3 (inner): Front: [8, 5],  Back: [6, 7]

public struct SaddleStitchImposition {
    
    /// Represents one printed sheet (front and back)
    public struct PrintSheet {
        let sheetNumber: Int
        let frontLeft: Int   // Page number on front left
        let frontRight: Int  // Page number on front right
        let backLeft: Int    // Page number on back left
        let backRight: Int   // Page number on back right
        
        var description: String {
            "Sheet \(sheetNumber): Front[\(frontLeft), \(frontRight)] Back[\(backLeft), \(backRight)]"
        }
    }
    
    /// Generate imposition layout for saddle stitch binding
    /// - Parameter totalPages: Total number of pages (must be multiple of 4)
    /// - Returns: Array of PrintSheet describing the imposition
    public static func generateImposition(totalPages: Int) -> [PrintSheet] {
        // Ensure multiple of 4
        let adjustedTotal = ((totalPages + 3) / 4) * 4
        let sheetCount = adjustedTotal / 4
        
        var sheets: [PrintSheet] = []
        
        for i in 0..<sheetCount {
            // For saddle stitch, outer sheets have extreme page numbers
            // Inner sheets have middle page numbers
            
            // Front side: [last-i*2, first+i*2+1]
            // Back side:  [first+i*2+2, last-i*2-1]
            
            let frontLeft = adjustedTotal - (i * 2)
            let frontRight = (i * 2) + 1
            let backLeft = (i * 2) + 2
            let backRight = adjustedTotal - (i * 2) - 1
            
            sheets.append(PrintSheet(
                sheetNumber: i + 1,
                frontLeft: frontLeft,
                frontRight: frontRight,
                backLeft: backLeft,
                backRight: backRight
            ))
        }
        
        return sheets
    }
    
    /// Generate a markdown table showing the imposition layout
    public static func generateImpositionTable(totalPages: Int) -> String {
        let sheets = generateImposition(totalPages: totalPages)
        let adjustedTotal = ((totalPages + 3) / 4) * 4
        
        var table = """
        ## 骑马钉拼版表 (Saddle Stitch Imposition)
        
        | 纸张 | 正面左 | 正面右 | 背面左 | 背面右 | 说明 |
        |------|--------|--------|--------|--------|------|
        """
        
        for sheet in sheets {
            let frontLeftStr = sheet.frontLeft > totalPages ? "空白" : "P\(sheet.frontLeft)"
            let frontRightStr = sheet.frontRight > totalPages ? "空白" : "P\(sheet.frontRight)"
            let backLeftStr = sheet.backLeft > totalPages ? "空白" : "P\(sheet.backLeft)"
            let backRightStr = sheet.backRight > totalPages ? "空白" : "P\(sheet.backRight)"
            
            let note = sheet.sheetNumber == 1 ? "最外层" : (sheet.sheetNumber == sheets.count ? "最内层" : "")
            
            table += "\n| \(sheet.sheetNumber) | \(frontLeftStr) | \(frontRightStr) | \(backLeftStr) | \(backRightStr) | \(note) |"
        }
        
        table += "\n\n总页数: \(totalPages) → 调整为: \(adjustedTotal) (4的倍数)\n"
        table += "打印纸张数: \(sheets.count)\n"
        
        return table
    }
}

// MARK: - Saddle Stitch PDF Exporter

@MainActor
public class SaddleStitchExporter {
    
    /// Export a photobook as saddle stitch imposed PDF
    /// - Parameters:
    ///   - bookStructure: The book structure containing all pages
    ///   - config: PDF export configuration
    ///   - url: Output file URL
    ///   - progressHandler: Progress callback
    public static func exportSaddleStitch(
        bookStructure: BookStructure,
        config: PDFExportConfig,
        to url: URL,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws {
        
        // 1. Collect all pages in order: [FrontCover, Inner1L, Inner1R, Inner2L, Inner2R, ..., BackCover]
        var allPages: [PageModel] = []
        
        // Front cover
        allPages.append(bookStructure.frontCover)
        
        // Inner pages
        for spread in bookStructure.innerSpreads {
            allPages.append(spread.left)
            allPages.append(spread.right)
        }
        
        // Back cover
        allPages.append(bookStructure.backCover)
        
        let totalPages = allPages.count
        
        // 2. Pad to multiple of 4 with blank pages
        let adjustedTotal = ((totalPages + 3) / 4) * 4
        let blankPagesNeeded = adjustedTotal - totalPages
        
        for _ in 0..<blankPagesNeeded {
            var blankPage = PageModel(pageNumber: -100)
            blankPage.backgroundColorHex = "#FFFFFF"
            allPages.append(blankPage)
        }
        
        // 3. Generate imposition
        let sheets = SaddleStitchImposition.generateImposition(totalPages: adjustedTotal)
        
        // 4. Create PDF document
        let pdfDocument = PDFDocument()
        
        for (index, sheet) in sheets.enumerated() {
            // Front side (two pages side by side)
            let frontLeftPage = allPages[sheet.frontLeft - 1]
            let frontRightPage = allPages[sheet.frontRight - 1]
            
            if let frontImage = await renderSheetSide(
                leftPage: frontLeftPage,
                rightPage: frontRightPage,
                config: config,
                sheetInfo: "Sheet \(sheet.sheetNumber) Front"
            ) {
                if let pdfPage = PDFPage(image: frontImage) {
                    pdfDocument.insert(pdfPage, at: index * 2)
                }
            }
            
            // Back side (two pages side by side)
            let backLeftPage = allPages[sheet.backLeft - 1]
            let backRightPage = allPages[sheet.backRight - 1]
            
            if let backImage = await renderSheetSide(
                leftPage: backLeftPage,
                rightPage: backRightPage,
                config: config,
                sheetInfo: "Sheet \(sheet.sheetNumber) Back"
            ) {
                if let pdfPage = PDFPage(image: backImage) {
                    pdfDocument.insert(pdfPage, at: index * 2 + 1)
                }
            }
            
            progressHandler?(Double(index + 1) / Double(sheets.count))
        }
        
        // 5. Save PDF
        pdfDocument.write(to: url)
        
        print("✅ Saddle stitch PDF exported: \(sheets.count) sheets to \(url.path)")
        print(SaddleStitchImposition.generateImpositionTable(totalPages: totalPages))
    }
    
    /// Render one side of a print sheet (two pages)
    private static func renderSheetSide(
        leftPage: PageModel,
        rightPage: PageModel,
        config: PDFExportConfig,
        sheetInfo: String
    ) async -> NSImage? {
        
        // Pre-load filtered images
        let leftImages = await preloadFilteredImages(for: leftPage)
        let rightImages = await preloadFilteredImages(for: rightPage)
        
        // Create base view
        let sheetView = SaddleStitchSheetView(
            leftPage: leftPage,
            rightPage: rightPage,
            leftFilteredImages: leftImages,
            rightFilteredImages: rightImages,
            config: config,
            sheetInfo: sheetInfo
        )
        
        // Wrap with print marks if needed
        let finalView: AnyView
        if config.includeCropMarks || config.includeRegistrationMarks || config.includeColorBars {
            finalView = AnyView(
                PrintMarksWrapper(
                    content: sheetView,
                    config: config,
                    pageNumber: 1,
                    totalPages: 1
                )
            )
        } else {
            finalView = AnyView(sheetView)
        }
        
        // Calculate dimensions
        let totalWidth = config.includeCropMarks ? config.totalPageSize.width * 2 : config.fullPageSize.width * 2
        let totalHeight = config.includeCropMarks ? config.totalPageSize.height : config.fullPageSize.height
        
        // Render
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
    
    /// Pre-load filtered images for a page
    private static func preloadFilteredImages(for page: PageModel) async -> [LayerID: NSImage] {
        var result: [LayerID: NSImage] = [:]
        
        for wrapper in page.layers {
            guard let photoLayer = wrapper.layer as? PhotoLayer else { continue }
            
            let needsFilter = photoLayer.filterType != .none ||
                              photoLayer.brightness != 0 ||
                              photoLayer.contrast != 1 ||
                              photoLayer.saturation != 1 ||
                              photoLayer.vignetteIntensity > 0 ||
                              photoLayer.sharpenIntensity > 0 ||
                              photoLayer.temperature != 6500
            
            if needsFilter {
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
                if let original = NSImage(contentsOf: photoLayer.photoUrl) {
                    result[photoLayer.id] = original
                }
            }
        }
        
        return result
    }
}

// MARK: - Saddle Stitch Sheet View

struct SaddleStitchSheetView: View {
    let leftPage: PageModel
    let rightPage: PageModel
    let leftFilteredImages: [LayerID: NSImage]
    let rightFilteredImages: [LayerID: NSImage]
    let config: PDFExportConfig
    let sheetInfo: String
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Page
            ExportablePage(
                page: leftPage,
                filteredImages: leftFilteredImages,
                config: config,
                isLeft: true
            )
            
            // Center fold line
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
            
            // Right Page
            ExportablePage(
                page: rightPage,
                filteredImages: rightFilteredImages,
                config: config,
                isLeft: false
            )
        }
        .background(Color.white)
        // Optional: Add fold mark at top/bottom center
        .overlay(
            VStack {
                // Top fold mark
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 1, height: 10)
                Spacer()
                // Bottom fold mark
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 1, height: 10)
            }
        )
    }
}
