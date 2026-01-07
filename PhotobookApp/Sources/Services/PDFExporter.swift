import Foundation
import AppKit
import PDFKit

/// Exports photos to print-ready PDF
class PDFExporter {

    /// Export photos to PDF
    static func export(
        photos: [Photo],
        to url: URL,
        pageSize: PageSize,
        margin: CGFloat = 10  // Points
    ) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let pdfDocument = PDFDocument()
                let size = pageSize.sizeInPoints

                // Distribute photos across pages using layout templates
                let pages = distributePhotos(photos, pageSize: pageSize)

                for (pageIndex, pagePhotos) in pages.enumerated() {
                    let template = LayoutTemplate.bestTemplate(forPhotoCount: pagePhotos.count)

                    if let pdfPage = createPage(
                        photos: pagePhotos,
                        template: template,
                        size: size,
                        margin: margin
                    ) {
                        pdfDocument.insert(pdfPage, at: pageIndex)
                    }
                }

                // Save PDF
                pdfDocument.write(to: url)
                print("PDF exported to: \(url.path)")

                continuation.resume()
            }
        }
    }

    /// Distribute photos across pages
    private static func distributePhotos(_ photos: [Photo], pageSize: PageSize) -> [[Photo]] {
        var pages: [[Photo]] = []
        var remaining = photos
        let maxPhotosPerPage = 6

        while !remaining.isEmpty {
            let count = min(remaining.count, maxPhotosPerPage)
            // Vary layout: 1, 2, 3, 4, or 6 photos per page
            let photosForPage: Int
            if remaining.count == 1 {
                photosForPage = 1
            } else if remaining.count <= 3 {
                photosForPage = remaining.count
            } else {
                // Vary between 2-4 photos per page for visual interest
                photosForPage = min(count, [2, 3, 4, 3, 2, 4].randomElement() ?? 3)
            }

            let pagePhotos = Array(remaining.prefix(photosForPage))
            pages.append(pagePhotos)
            remaining.removeFirst(photosForPage)
        }

        return pages
    }

    /// Create a single PDF page
    private static func createPage(
        photos: [Photo],
        template: LayoutTemplate,
        size: CGSize,
        margin: CGFloat
    ) -> PDFPage? {
        // Create image context
        _ = NSGraphicsContext.current

        // Create a blank image for the page
        let image = NSImage(size: size)
        image.lockFocus()

        // Fill background with white
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()

        // Calculate content area (excluding margins)
        let contentRect = NSRect(
            x: margin,
            y: margin,
            width: size.width - margin * 2,
            height: size.height - margin * 2
        )

        // Draw photos in template slots
        for (index, slot) in template.slots.enumerated() {
            guard index < photos.count else { break }

            let photo = photos[index]
            guard let photoImage = NSImage(contentsOf: photo.url) else { continue }

            // Convert normalized rect to actual rect
            let destRect = NSRect(
                x: contentRect.minX + slot.rect.minX * contentRect.width,
                y: contentRect.minY + (1 - slot.rect.maxY) * contentRect.height,
                width: slot.rect.width * contentRect.width,
                height: slot.rect.height * contentRect.height
            )

            // Calculate aspect-fit rect
            let fitRect = aspectFitRect(
                imageSize: photoImage.size,
                in: destRect
            )

            // Draw the photo
            photoImage.draw(
                in: fitRect,
                from: NSRect(origin: .zero, size: photoImage.size),
                operation: .copy,
                fraction: 1.0
            )
        }

        image.unlockFocus()

        // Convert NSImage to PDFPage
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        guard let pdfImage = NSImage(data: pngData) else { return nil }

        return PDFPage(image: pdfImage)
    }

    /// Calculate aspect-fit rect
    private static func aspectFitRect(imageSize: CGSize, in rect: NSRect) -> NSRect {
        let imageRatio = imageSize.width / imageSize.height
        let rectRatio = rect.width / rect.height

        var fitRect: NSRect

        if imageRatio > rectRatio {
            // Image is wider - fit to width
            let height = rect.width / imageRatio
            fitRect = NSRect(
                x: rect.minX,
                y: rect.minY + (rect.height - height) / 2,
                width: rect.width,
                height: height
            )
        } else {
            // Image is taller - fit to height
            let width = rect.height * imageRatio
            fitRect = NSRect(
                x: rect.minX + (rect.width - width) / 2,
                y: rect.minY,
                width: width,
                height: rect.height
            )
        }

        return fitRect
    }

    /// Export with custom pages per month allocation
    static func exportWithMonthAllocation(
        monthGroups: [MonthGroup],
        to url: URL,
        pageSize: PageSize
    ) async {
        var allPagePhotos: [[Photo]] = []

        for group in monthGroups {
            let photosPerPage = max(1, group.photos.count / group.pagesAllocated)
            var remaining = group.photos

            for _ in 0..<group.pagesAllocated {
                guard !remaining.isEmpty else { break }
                let count = min(remaining.count, photosPerPage)
                allPagePhotos.append(Array(remaining.prefix(count)))
                remaining.removeFirst(count)
            }

            // Add remaining photos to last page
            if !remaining.isEmpty, var lastPage = allPagePhotos.last {
                allPagePhotos.removeLast()
                lastPage.append(contentsOf: remaining)
                allPagePhotos.append(lastPage)
            }
        }

        // Flatten and export
        let allPhotos = allPagePhotos.flatMap { $0 }
        await export(photos: allPhotos, to: url, pageSize: pageSize)
    }
}
