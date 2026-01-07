import Foundation
import SwiftUI
import AppKit

/// Main data store for the app
@MainActor
class PhotoStore: ObservableObject {
    @Published var allPhotos: [Photo] = []
    @Published var monthGroups: [MonthGroup] = []
    @Published var selectedPhotos: [Photo] = []
    @Published var showFolderPicker = false
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0

    private let exifReader = EXIFReader()

    /// Import photos from folders or files
    func importFiles(_ urls: [URL]) async {
        isLoading = true
        loadingProgress = 0
        
        var imageURLs: [URL] = []
        let fileManager = FileManager.default
        let supportedExtensions = ["jpg", "jpeg", "png", "heic", "tiff", "tif"]
        
        for url in urls {
            // Get security access
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    // It's a folder, enumerate it
                    if let enumerator = fileManager.enumerator(
                        at: url,
                        includingPropertiesForKeys: [.isRegularFileKey],
                        options: [.skipsHiddenFiles]
                    ) {
                        while let fileURL = enumerator.nextObject() as? URL {
                            let ext = fileURL.pathExtension.lowercased()
                            if supportedExtensions.contains(ext) {
                                imageURLs.append(fileURL)
                            }
                        }
                    }
                } else {
                    // It's a file
                    let ext = url.pathExtension.lowercased()
                    if supportedExtensions.contains(ext) {
                        imageURLs.append(url)
                    }
                }
            }
        }
        
        let totalCount = imageURLs.count
        if totalCount == 0 {
            isLoading = false
            return
        }

        var loadedPhotos: [Photo] = []

        for (index, imageURL) in imageURLs.enumerated() {
            let photo = await loadPhoto(from: imageURL)
            // Deduplicate: Don't add if already exists
            if !allPhotos.contains(where: { $0.url == photo.url }) {
                loadedPhotos.append(photo)
            }

            // Update progress
            loadingProgress = Double(index + 1) / Double(totalCount)
        }

        // Merge with existing
        loadedPhotos.append(contentsOf: allPhotos)
        
        // Sort by date
        loadedPhotos.sort { ($0.dateTaken ?? .distantPast) < ($1.dateTaken ?? .distantPast) }

        // Group by month
        let grouped = Dictionary(grouping: loadedPhotos) { $0.monthKey }
        let sortedKeys = grouped.keys.sorted()

        var groups: [MonthGroup] = []
        for key in sortedKeys {
            if let photos = grouped[key], let firstPhoto = photos.first {
                groups.append(MonthGroup(
                    month: firstPhoto.displayMonth,
                    monthKey: key,
                    photos: photos
                ))
            }
        }

        allPhotos = loadedPhotos
        monthGroups = groups
        isLoading = false
    }
    
    /// Helper to regenerate month groups from existing allPhotos (used after loading from persistence)
    func recalculateMonthGroups() {
        let grouped = Dictionary(grouping: allPhotos) { $0.monthKey }
        let sortedKeys = grouped.keys.sorted()
        
        var groups: [MonthGroup] = []
        for key in sortedKeys {
            if let photos = grouped[key], let firstPhoto = photos.first {
                groups.append(MonthGroup(
                    month: firstPhoto.displayMonth,
                    monthKey: key,
                    photos: photos
                ))
            }
        }
        self.monthGroups = groups
    }

    /// Load a single photo with EXIF data
    private func loadPhoto(from url: URL) async -> Photo {
        let dateTaken = exifReader.getDateTaken(from: url)
        let thumbnail = await generateThumbnail(from: url)
        return Photo(url: url, dateTaken: dateTaken, thumbnailImage: thumbnail)
    }

    /// Generate thumbnail for display
    private func generateThumbnail(from url: URL) async -> NSImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let image = NSImage(contentsOf: url) else {
                    continuation.resume(returning: nil)
                    return
                }

                let maxSize: CGFloat = 200
                let ratio = min(maxSize / image.size.width, maxSize / image.size.height)
                let newSize = CGSize(
                    width: image.size.width * ratio,
                    height: image.size.height * ratio
                )

                let thumbnail = NSImage(size: newSize)
                thumbnail.lockFocus()
                image.draw(
                    in: NSRect(origin: .zero, size: newSize),
                    from: NSRect(origin: .zero, size: image.size),
                    operation: .copy,
                    fraction: 1.0
                )
                thumbnail.unlockFocus()

                continuation.resume(returning: thumbnail)
            }
        }
    }

    /// Toggle photo selection
    func toggleSelection(_ photo: Photo) {
        if let index = selectedPhotos.firstIndex(of: photo) {
            selectedPhotos.remove(at: index)
        } else {
            selectedPhotos.append(photo)
        }
    }

    /// Select all photos in a month
    func selectAllInMonth(_ month: String) {
        guard let group = monthGroups.first(where: { $0.month == month }) else { return }
        for photo in group.photos {
            if !selectedPhotos.contains(photo) {
                selectedPhotos.append(photo)
            }
        }
    }

    /// Clear selection
    func clearSelection() {
        selectedPhotos.removeAll()
    }
}
