import Foundation
import SwiftUI
import AppKit
import Vision
import CoreLocation

/// Main data store for the app
@MainActor
class PhotoStore: ObservableObject {
    @Published var allPhotos: [Photo] = []
    @Published var monthGroups: [MonthGroup] = []
    @Published var selectedPhotos: [Photo] = []
    @Published var showFolderPicker = false
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0
    @Published var events: [PhotoEvent] = []
    
    // Multi-selection state
    private var lastSelectedPhoto: Photo?

    private let exifReader = EXIFReader()
    private let groupingService = SmartGroupingService()

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

    /// Load a single photo with full AI metadata
    private func loadPhoto(from url: URL) async -> Photo {
        let thumbnail = await generateThumbnail(from: url)
        
        // Extract basic metadata
        guard let metadata = exifReader.getAllMetadata(from: url) else {
            return Photo(url: url, thumbnailImage: thumbnail)
        }
        
        var photo = Photo(url: url, dateTaken: metadata.dateTaken, thumbnailImage: thumbnail)
        photo.width = metadata.width
        photo.height = metadata.height
        photo.cameraModel = metadata.cameraDescription
        
        // Geocoding
        if let coordinate = metadata.location {
            photo.latitude = coordinate.latitude
            photo.longitude = coordinate.longitude
            photo.locationName = await exifReader.reverseGeocode(location: coordinate)
        }
        
        // Vision Analysis
        photo.sceneLabel = await analyzeScene(from: url)
        
        print("DEBUG: Loaded photo \(url.lastPathComponent) with scene: \(photo.sceneLabel ?? "none")")
        return photo
    }
    
    /// Use Vision to classify the image scene
    private func analyzeScene(from url: URL) async -> String? {
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(url: url)
        
        do {
            try handler.perform([request])
            let results = request.results
            
            // Return the highest confidence result that meets threshold
            return results?.first(where: { $0.confidence > 0.8 })?.identifier
        } catch {
            print("❌ Vision analysis failed: \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
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
                
                // Create NSImage with proper size based on the CGImage dimensions
                let width = CGFloat(cgImage.width)
                let height = CGFloat(cgImage.height)
                let thumbnail = NSImage(cgImage: cgImage, size: NSSize(width: width, height: height))
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
        lastSelectedPhoto = photo
    }
    
    /// Handle photo selection with modifier keys
    /// - Parameters:
    ///   - photo: The photo being clicked
    ///   - modifiers: Event modifiers (Shift, Cmd, etc.)
    func handlePhotoSelection(_ photo: Photo, modifiers: EventModifiers) {
        if modifiers.contains(.command) {
            // Cmd+Click: Toggle selection (multi-select)
            if let index = selectedPhotos.firstIndex(of: photo) {
                selectedPhotos.remove(at: index)
            } else {
                selectedPhotos.append(photo)
            }
            lastSelectedPhoto = photo
            
        } else if modifiers.contains(.shift) {
            // Shift+Click: Range selection
            guard let lastPhoto = lastSelectedPhoto else {
                // No previous selection, just select this one
                selectedPhotos = [photo]
                lastSelectedPhoto = photo
                return
            }
            
            // Find range between last selected and current
            let range = getPhotoRange(from: lastPhoto, to: photo)
            
            // Clear current selection and select range
            selectedPhotos = range
            // Don't update lastSelectedPhoto for shift-click
            
        } else {
            // Normal click: Clear selection and select only this photo
            selectedPhotos = [photo]
            lastSelectedPhoto = photo
        }
    }
    
    /// Get all photos between two photos (inclusive)
    private func getPhotoRange(from startPhoto: Photo, to endPhoto: Photo) -> [Photo] {
        guard let startIndex = allPhotos.firstIndex(of: startPhoto),
              let endIndex = allPhotos.firstIndex(of: endPhoto) else {
            return [endPhoto]
        }
        
        let minIndex = min(startIndex, endIndex)
        let maxIndex = max(startIndex, endIndex)
        
        return Array(allPhotos[minIndex...maxIndex])
    }
    
    /// Select all photos
    func selectAll() {
        selectedPhotos = allPhotos
        lastSelectedPhoto = allPhotos.last
    }
    
    /// Check if a photo is used in the current book
    func isPhotoUsed(_ photo: Photo, in editorState: EditorState) -> Bool {
        let photoId = photo.id
        
        // Check all spreads
        for spread in editorState.bookStructure.innerSpreads {
            // Check left page
            for layer in spread.left.layers {
                if let photoLayer = layer.layer as? PhotoLayer, photoLayer.photoId == photoId {
                    return true
                }
            }
            // Check right page
            for layer in spread.right.layers {
                if let photoLayer = layer.layer as? PhotoLayer, photoLayer.photoId == photoId {
                    return true
                }
            }
        }
        
        // Check covers
        for layer in editorState.bookStructure.frontCover.layers {
            if let photoLayer = layer.layer as? PhotoLayer, photoLayer.photoId == photoId {
                return true
            }
        }
        for layer in editorState.bookStructure.backCover.layers {
            if let photoLayer = layer.layer as? PhotoLayer, photoLayer.photoId == photoId {
                return true
            }
        }
        
        return false
    }
    
    /// Find the first spread index where this photo is used
    /// Returns nil if photo is not used, or a special value for covers
    /// Returns -1 for front cover, -2 for back cover, or spread index (0-based) for inner pages
    func findPhotoUsage(_ photo: Photo, in editorState: EditorState) -> Int? {
        let photoId = photo.id
        
        // Check front cover
        for layer in editorState.bookStructure.frontCover.layers {
            if let photoLayer = layer.layer as? PhotoLayer, photoLayer.photoId == photoId {
                return -1 // Front cover
            }
        }
        
        // Check back cover
        for layer in editorState.bookStructure.backCover.layers {
            if let photoLayer = layer.layer as? PhotoLayer, photoLayer.photoId == photoId {
                return -2 // Back cover
            }
        }
        
        // Check all spreads
        for (index, spread) in editorState.bookStructure.innerSpreads.enumerated() {
            // Check left page
            for layer in spread.left.layers {
                if let photoLayer = layer.layer as? PhotoLayer, photoLayer.photoId == photoId {
                    return index
                }
            }
            // Check right page
            for layer in spread.right.layers {
                if let photoLayer = layer.layer as? PhotoLayer, photoLayer.photoId == photoId {
                    return index
                }
            }
        }
        
        return nil
    }
    
    /// Find the layer ID for a photo in the current book
    /// Returns the layer ID if found, nil otherwise
    func findPhotoLayerId(_ photo: Photo, in editorState: EditorState) -> LayerID? {
        let photoId = photo.id
        
        // Check front cover
        for layer in editorState.bookStructure.frontCover.layers {
            if let photoLayer = layer.layer as? PhotoLayer, photoLayer.photoId == photoId {
                return photoLayer.id
            }
        }
        
        // Check back cover
        for layer in editorState.bookStructure.backCover.layers {
            if let photoLayer = layer.layer as? PhotoLayer, photoLayer.photoId == photoId {
                return photoLayer.id
            }
        }
        
        // Check all spreads
        for spread in editorState.bookStructure.innerSpreads {
            // Check left page
            for layer in spread.left.layers {
                if let photoLayer = layer.layer as? PhotoLayer, photoLayer.photoId == photoId {
                    return photoLayer.id
                }
            }
            // Check right page
            for layer in spread.right.layers {
                if let photoLayer = layer.layer as? PhotoLayer, photoLayer.photoId == photoId {
                    return photoLayer.id
                }
            }
        }
        
        return nil
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
    /// Delete all selected photos
    func deleteSelected(undoManager: UndoManager? = nil) {
        let photosToDelete = selectedPhotos
        guard !photosToDelete.isEmpty else { return }
        
        let oldPhotos = allPhotos
        let oldMonthGroups = monthGroups
        
        // Register undo
        undoManager?.registerUndo(withTarget: self) { target in
            target.allPhotos = oldPhotos
            target.monthGroups = oldMonthGroups
            target.selectedPhotos = []
        }
        undoManager?.setActionName("Delete Photos")
        
        for photo in photosToDelete {
            deletePhoto(photo)
        }
        selectedPhotos.removeAll()
    }

}
