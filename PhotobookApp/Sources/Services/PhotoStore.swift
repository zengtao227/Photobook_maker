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
    
    /// Refresh all photos: regenerate thumbnails and re-read dimensions
    /// Call this after loading from persistence to fix any stale data
    func refreshAllPhotos() async {
        var refreshedPhotos: [Photo] = []
        
        for photo in allPhotos {
            var updatedPhoto = photo
            
            // Regenerate thumbnail
            if let thumbnail = await generateThumbnail(from: photo.url) {
                updatedPhoto.thumbnailImage = thumbnail
            }
            
            // Re-read dimensions if missing or zero
            if updatedPhoto.width == nil || updatedPhoto.height == nil || 
               updatedPhoto.width == 0 || updatedPhoto.height == 0 {
                let (w, h) = readImageDimensions(from: photo.url)
                updatedPhoto.width = w
                updatedPhoto.height = h
            }
            
            refreshedPhotos.append(updatedPhoto)
        }
        
        allPhotos = refreshedPhotos
        recalculateMonthGroups()
    }
    
    /// Read image dimensions from file
    private func readImageDimensions(from url: URL) -> (Int?, Int?) {
        var width: Int?
        var height: Int?
        
        if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
           let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
            
            let rawW = (properties[kCGImagePropertyPixelWidth as String] as? NSNumber)?.intValue ?? 0
            let rawH = (properties[kCGImagePropertyPixelHeight as String] as? NSNumber)?.intValue ?? 0
            let orientation = (properties[kCGImagePropertyOrientation as String] as? NSNumber)?.intValue ?? 1
            
            if orientation >= 5 && orientation <= 8 {
                width = rawH
                height = rawW
            } else {
                width = rawW
                height = rawH
            }
        }
        
        // Fallback
        if width == nil || height == nil || width == 0 || height == 0 {
            if let image = NSImage(contentsOf: url), let rep = image.representations.first {
                width = rep.pixelsWide
                height = rep.pixelsHigh
            }
        }
        
        return (width, height)
    }

    /// Load a single photo with EXIF data
    private func loadPhoto(from url: URL) async -> Photo {
        let dateTaken = exifReader.getDateTaken(from: url)
        let thumbnail = await generateThumbnail(from: url)
        
        var width: Int?
        var height: Int?
        
        // Use ImageIO directly as it's the most reliable way to get metadata without loading the file
        if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
           let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
            
            // Safe extraction using NSNumber for broad type compatibility
            let rawW = (properties[kCGImagePropertyPixelWidth as String] as? NSNumber)?.intValue ?? 0
            let rawH = (properties[kCGImagePropertyPixelHeight as String] as? NSNumber)?.intValue ?? 0
            let orientation = (properties[kCGImagePropertyOrientation as String] as? NSNumber)?.intValue ?? 1
            
            // Orientations 5-8 mean image is rotated 90 or 270 degrees
            if orientation >= 5 && orientation <= 8 {
                width = rawH
                height = rawW
            } else {
                width = rawW
                height = rawH
            }
        }
        
        // Fallback if ImageIO failed or returned 0 dimensions
        if width == nil || height == nil || width == 0 || height == 0 {
             if let image = NSImage(contentsOf: url) {
                 // NSImage size is in points, but ratio is what matters. 
                 // If we want pixels, we'd need representations, but for ratio, size is fine.
                 if let rep = image.representations.first {
                     width = rep.pixelsWide
                     height = rep.pixelsHigh
                 } else {
                     width = Int(image.size.width)
                     height = Int(image.size.height)
                 }
            }
        }
        
        var photo = Photo(url: url, dateTaken: dateTaken, thumbnailImage: thumbnail)
        photo.width = width
        photo.height = height
        print("DEBUG: Loaded photo \(url.lastPathComponent), size: \(width ?? 0)x\(height ?? 0)") // Debug log
        return photo
    }

    /// Generate thumbnail for display with proper orientation
    private func generateThumbnail(from url: URL) async -> NSImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let options: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true, // Force resample
                    kCGImageSourceCreateThumbnailWithTransform: true, // Handle Orientation
                    kCGImageSourceThumbnailMaxPixelSize: 300
                ]
                
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let thumbnail = NSImage(cgImage: cgImage, size: .zero)
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
    
    /// Delete a photo from library
    func deletePhoto(_ photo: Photo) {
        print("DEBUG: deletePhoto called for \(photo.filename)")
        
        // 1. Remove from allPhotos
        if let idx = allPhotos.firstIndex(where: { $0.id == photo.id }) {
            allPhotos.remove(at: idx)
            print("DEBUG: Removed from allPhotos, new count: \(allPhotos.count)")
        } else {
            print("DEBUG: Photo not found in allPhotos!")
        }
        
        // 2. Remove from monthGroups
        var newGroups: [MonthGroup] = []
        for var group in monthGroups {
            group.photos.removeAll(where: { $0.id == photo.id })
            if !group.photos.isEmpty {
                newGroups.append(group)
            }
        }
        monthGroups = newGroups
        
        // 3. Remove from selection
        if let selIdx = selectedPhotos.firstIndex(of: photo) {
            selectedPhotos.remove(at: selIdx)
        }
        
        print("DEBUG: deletePhoto completed")
    }
}
