import SwiftUI
import Observation

// MARK: - Navigation Target

/// Represents what the user is currently editing
public enum EditorNavigationTarget: Equatable {
    case frontCover
    case backCover
    case innerSpread(index: Int)
    case fullCoverWrap
    
    public var displayName: String {
        switch self {
        case .frontCover: return "封面"
        case .backCover: return "封底"
        case .innerSpread(let index): return "内页 \(index + 1)"
        case .fullCoverWrap: return "全包封面"
        }
    }
}

@Observable
@MainActor
public class EditorState {
    // Current Spread State
    public var leftPage: PageModel

    public var rightPage: PageModel
    
    // Track active page side for single page operations (e.g. Delete Page)
    public enum PageSide { case left, right }
    public var activePageSide: PageSide = .left // Default to left
    
    // MARK: - Layer Management
    private let archiveManager = PhotobookArchiveManager()
    private let autoLayoutEngine = AutoLayoutEngine(classifier: PhotoClassifier())
    
    // Selection & Cropping
    public var selectedLayerId: LayerID?
    public var croppingLayerId: LayerID? // New: Track which layer is being cropped
    
    // Change Tracking
    public var lastModified: Date = Date()
    public var updateCounter: Int = 0 // Force UI refresh
    
    // MARK: - Undo/Redo Support
    public var undoManager: UndoManager? // Bridged from SwiftUI/UIKit/AppKit
    private var undoStack: [BookStructure] = []
    private var redoStack: [BookStructure] = []
    private let maxUndoSteps = 50

    
    // MARK: - Clipboard Support
    
    private var clipboard: AnyLayer?
    
    public var hasClipboard: Bool {
        clipboard != nil
    }
    
    /// Cut selected layer to clipboard
    public func cutSelectedLayer() {
        guard let id = selectedLayerId else { return }
        
        saveUndoState()
        
        // Copy to clipboard
        if let layer = leftPage.layers.first(where: { $0.id == id }) {
            clipboard = layer
        } else if let layer = rightPage.layers.first(where: { $0.id == id }) {
            clipboard = layer
        }
        
        // Delete from page
        deleteSelectedLayer()
    }
    
    /// Copy selected layer to clipboard
    public func copySelectedLayer() {
        guard let id = selectedLayerId else { return }
        
        if let layer = leftPage.layers.first(where: { $0.id == id }) {
            clipboard = layer
        } else if let layer = rightPage.layers.first(where: { $0.id == id }) {
            clipboard = layer
        }
    }
    
    /// Paste layer from clipboard to specified page
    public func pasteLayer(toLeftPage: Bool) {
        guard let layer = clipboard else { return }
        
        saveUndoState()
        
        // Create a new layer with new ID and offset position
        var newLayer = layer
        newLayer.id = LayerID()
        
        // Offset the frame slightly so it's visible
        var newFrame = newLayer.frame
        newFrame.origin.x += 20
        newFrame.origin.y += 20
        newLayer.frame = newFrame
        
        // Add to page
        if toLeftPage {
            leftPage.layers.append(newLayer)
        } else {
            rightPage.layers.append(newLayer)
        }
        
        selectedLayerId = newLayer.id
        lastModified = Date()
        updateCounter += 1
    }
    
    /// Duplicate selected layer
    public func duplicateSelectedLayer() {
        guard let id = selectedLayerId else { return }
        
        saveUndoState()
        
        var layerToDuplicate: AnyLayer?
        var isLeft = false
        
        if let layer = leftPage.layers.first(where: { $0.id == id }) {
            layerToDuplicate = layer
            isLeft = true
        } else if let layer = rightPage.layers.first(where: { $0.id == id }) {
            layerToDuplicate = layer
            isLeft = false
        }
        
        guard var newLayer = layerToDuplicate else { return }
        
        // Create new layer with offset
        newLayer.id = LayerID()
        var newFrame = newLayer.frame
        newFrame.origin.x += 20
        newFrame.origin.y += 20
        newLayer.frame = newFrame
        
        // Add to same page
        if isLeft {
            leftPage.layers.append(newLayer)
        } else {
            rightPage.layers.append(newLayer)
        }
        
        selectedLayerId = newLayer.id
        lastModified = Date()
        updateCounter += 1
    }
    
    /// Save current state to undo stack before making changes
    public func saveUndoState() {
        // 1. Save to internal stack
        undoStack.append(bookStructure)
        if undoStack.count > maxUndoSteps { undoStack.removeFirst() }
        redoStack.removeAll()
        
        // 2. Register with system UndoManager
        undoManager?.registerUndo(withTarget: self) { target in
            target.undo()
        }
        undoManager?.setActionName("Edit Action")
    }

    
    /// Undo last action
    public func undo() {
        guard !undoStack.isEmpty else { return }
        
        // Save current state to redo stack
        redoStack.append(bookStructure)
        
        // Restore previous state
        bookStructure = undoStack.removeLast()
        
        // Reload current view
        loadStateWithoutSaving()
    }
    
    /// Redo last undone action
    public func redo() {
        guard !redoStack.isEmpty else { return }
        
        // Save current state to undo stack
        undoStack.append(bookStructure)
        
        // Restore next state
        bookStructure = redoStack.removeLast()
        
        // Reload current view
        loadStateWithoutSaving()
    }
    
    /// Check if undo is available
    public var canUndo: Bool {
        !undoStack.isEmpty
    }
    
    /// Check if redo is available
    public var canRedo: Bool {
        !redoStack.isEmpty
    }
    
    // MARK: - Bleed Guide (Phase 3)
    
    /// Whether to show the bleed guide overlay on canvas
    public var showBleedGuide: Bool = true
    
    /// Bleed margin in millimeters (3mm is print industry standard)
    public var bleedMM: CGFloat = 3.0
    
    /// Bleed in points (for rendering)
    public var bleedPoints: CGFloat {
        bleedMM * 2.83465 // 1mm ≈ 2.83465 points
    }
    
    // MARK: - Book Structure (Phase 4)
    
    /// Complete book structure with covers and inner pages
    public var bookStructure: BookStructure = BookStructure()
    
    /// Current navigation target
    public var currentTarget: EditorNavigationTarget = .innerSpread(index: 0)
    
    /// Whether currently editing covers
    public var isEditingCover: Bool {
        switch currentTarget {
        case .frontCover, .backCover, .fullCoverWrap: return true
        case .innerSpread: return false
        }
    }
    
    // MARK: - Multi-Spread Management (Phase 3 - Legacy Compatibility)
    
    /// All spreads in the book (each spread = left + right page)
    /// Now backed by bookStructure.innerSpreads
    public var allSpreads: [(left: PageModel, right: PageModel)] {
        get { bookStructure.innerSpreads }
        set { bookStructure.innerSpreads = newValue }
    }
    
    /// Current spread index (0-based, for inner spreads only)
    public var currentSpreadIndex: Int {
        get {
            if case .innerSpread(let index) = currentTarget {
                return index
            }
            return 0
        }
        set {
            currentTarget = .innerSpread(index: newValue)
        }
    }
    
    /// Total number of inner spreads
    public var spreadCount: Int {
        bookStructure.innerSpreads.count
    }
    
    // MARK: - Navigation
    
    /// Navigate to a specific target (cover or inner spread)
    public func navigateTo(_ target: EditorNavigationTarget) {
        // Save current state before switching
        saveCurrentState()
        
        currentTarget = target
        loadCurrentState()
        
        // Clear selection when switching pages
        selectedLayerId = nil
        lastModified = Date()
        updateCounter += 1
    }
    
    /// Navigate to a specific inner spread (legacy compatibility)
    public func navigateToSpread(_ index: Int) {
        guard index >= 0 && index < bookStructure.innerSpreads.count else { return }
        navigateTo(.innerSpread(index: index))
    }
    
    /// Navigate to front cover
    public func navigateToFrontCover() { navigateTo(.frontCover) }
    
    /// Navigate to back cover
    public func navigateToBackCover() { navigateTo(.backCover) }
    
    /// Navigate to full cover wrap (hardcover only)
    public func navigateToFullCoverWrap() {
        guard bookStructure.bindingType.supportsFullWrap else { return }
        navigateTo(.fullCoverWrap)
    }
    
    /// Save current left/right pages back to appropriate location
    public func saveCurrentState() {
        switch currentTarget {
        case .frontCover:
            bookStructure.frontCover = leftPage
        case .backCover:
            bookStructure.backCover = rightPage
        case .innerSpread(let index):
            guard index < bookStructure.innerSpreads.count else { return }
            bookStructure.innerSpreads[index] = (left: leftPage, right: rightPage)
        case .fullCoverWrap:
            bookStructure.fullCoverWrap = leftPage
        }
    }
    
    /// Alias for legacy compatibility
    public func saveCurrentSpread() { saveCurrentState() }
    
    /// Load state based on current target
    private func loadCurrentState() {
        switch currentTarget {
        case .frontCover:
            leftPage = bookStructure.frontCover
            rightPage = PageModel(pageNumber: -99)
        case .backCover:
            leftPage = PageModel(pageNumber: -98)
            rightPage = bookStructure.backCover
        case .innerSpread(let index):
            guard index < bookStructure.innerSpreads.count else { return }
            let spread = bookStructure.innerSpreads[index]
            leftPage = spread.left
            rightPage = spread.right
        case .fullCoverWrap:
            leftPage = bookStructure.fullCoverWrap ?? PageModel(pageNumber: -2)
            rightPage = PageModel(pageNumber: -99)
        }
    }
    
    public func loadStateWithoutSaving() {
        loadCurrentState()
        selectedLayerId = nil
        lastModified = Date()
        updateCounter += 1
    }
    
    public func addNewSpread() {
        saveCurrentState()
        bookStructure.addInnerSpread()
        navigateToSpread(bookStructure.innerSpreads.count - 1)
    }
    
    public func swapLeftRightPages() {
        guard case .innerSpread(let index) = currentTarget,
              index < bookStructure.innerSpreads.count else { return }
        let temp = leftPage
        leftPage = rightPage
        rightPage = temp
        bookStructure.innerSpreads[index] = (left: leftPage, right: rightPage)
        lastModified = Date()
        updateCounter += 1
    }
    
    public func deleteSpread(at index: Int) {
        guard bookStructure.innerSpreads.count > 1, 
              index >= 0 && index < bookStructure.innerSpreads.count else { return }
        bookStructure.removeInnerSpread(at: index)
        if case .innerSpread(let currentIndex) = currentTarget {
            if currentIndex >= bookStructure.innerSpreads.count {
                currentTarget = .innerSpread(index: bookStructure.innerSpreads.count - 1)
            }
        }
        loadCurrentState()
        lastModified = Date()
        updateCounter += 1
    }
    
    public func moveSpread(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex >= 0 && sourceIndex < bookStructure.innerSpreads.count,
              destinationIndex >= 0 && destinationIndex < bookStructure.innerSpreads.count,
              sourceIndex != destinationIndex else { return }
        saveCurrentState()
        let spread = bookStructure.innerSpreads.remove(at: sourceIndex)
        bookStructure.innerSpreads.insert(spread, at: destinationIndex)
        if case .innerSpread(let currentIndex) = currentTarget {
            if currentIndex == sourceIndex {
                currentTarget = .innerSpread(index: destinationIndex)
            } else if sourceIndex < currentIndex && destinationIndex >= currentIndex {
                currentTarget = .innerSpread(index: currentIndex - 1)
            } else if sourceIndex > currentIndex && destinationIndex <= currentIndex {
                currentTarget = .innerSpread(index: currentIndex + 1)
            }
        }
        loadCurrentState()
        lastModified = Date()
        updateCounter += 1
    }
    
    public init() {
        let structure = BookStructure()
        self.bookStructure = structure
        self.leftPage = structure.innerSpreads[0].left
        self.rightPage = structure.innerSpreads[0].right
        self.currentTarget = .innerSpread(index: 0)
    }
    
    // MARK: - Crop Operations
    func startCropping(_ id: LayerID) {
        selectedLayerId = id
        croppingLayerId = id
    }
    func endCropping() { croppingLayerId = nil }
    func updateLayerCrop(id: LayerID, scale: Double, offset: CGSize, normalizedRect: CGRect?, cropRotation: Double) {
        if var layer = findLayer(id) as? PhotoLayer {
            layer.cropScale = scale
            layer.cropOffset = offset
            layer.normalizedCropRect = normalizedRect
            layer.cropRotation = cropRotation
            updateLayer(layer)
        }
    }
    
    // MARK: - Filter Editing
    var filteringLayerId: LayerID? = nil
    func startFiltering(_ id: LayerID) { filteringLayerId = id }
    func endFiltering() { filteringLayerId = nil }
    func updateLayerFilter(id: LayerID, filterType: PhotoLayer.FilterType, brightness: Double, contrast: Double, saturation: Double,
                          vignette: Double = 0, sharpen: Double = 0, temperature: Double = 6500) {
        if var layer = findLayer(id) as? PhotoLayer {
            layer.filterType = filterType
            layer.brightness = brightness
            layer.contrast = contrast
            layer.saturation = saturation
            layer.vignetteIntensity = vignette
            layer.sharpenIntensity = sharpen
            layer.temperature = temperature
            updateLayer(layer)
        }
    }
    
    // MARK: - Border & Shadow
    func updateLayerBorder(id: LayerID, borderWidth: Double? = nil, borderColorHex: String? = nil, 
                           borderStyle: PhotoLayer.BorderStyle? = nil, borderCornerRadius: Double? = nil) {
        if var layer = findLayer(id) as? PhotoLayer {
            if let width = borderWidth { layer.borderWidth = width }
            if let colorHex = borderColorHex { layer.borderColorHex = colorHex }
            if let style = borderStyle { layer.borderStyle = style }
            if let radius = borderCornerRadius { layer.borderCornerRadius = radius }
            updateLayer(layer)
        }
    }
    func updateLayerFeathering(id: LayerID, feathering: Double) {
        if var layer = findLayer(id) as? PhotoLayer {
            layer.feathering = feathering
            updateLayer(layer)
        }
    }
    func updateLayerShadow(id: LayerID, shadowRadius: Double, shadowOpacity: Double) {
        if var layer = findLayer(id) as? PhotoLayer {
            layer.shadowRadius = shadowRadius
            layer.shadowOpacity = shadowOpacity
            updateLayer(layer)
        }
    }
    func updateLayerOpacity(id: LayerID, opacity: Double) {
        if var layer = findLayer(id) as? PhotoLayer {
            layer.opacity = opacity
            updateLayer(layer)
        }
    }
    
    // MARK: - Layer Helpers
    private func findLayer(_ id: LayerID) -> (any LayerProtocol)? {
        if let layer = leftPage.layers.first(where: { $0.id == id }) { return layer.layer }
        if let layer = rightPage.layers.first(where: { $0.id == id }) { return layer.layer }
        return nil
    }
    private func updateLayer(_ layer: any LayerProtocol) {
        let id = layer.id
        if let idx = leftPage.layers.firstIndex(where: { $0.id == id }) {
            leftPage.layers[idx] = AnyLayer(layer)
        } else if let idx = rightPage.layers.firstIndex(where: { $0.id == id }) {
            rightPage.layers[idx] = AnyLayer(layer)
        }
        lastModified = Date()
        updateCounter += 1
    }
    private func addLayer(_ layer: any LayerProtocol, toLeftPage: Bool) {
        if toLeftPage { leftPage.layers.append(AnyLayer(layer)) }
        else { rightPage.layers.append(AnyLayer(layer)) }
        selectedLayerId = layer.id
        lastModified = Date()
        updateCounter += 1
    }
    
    // MARK: - Layer Operations
    func addStickerLayer(url: URL, isLeftPage: Bool, center: CGPoint? = nil) {
        let size = CGSize(width: 150, height: 150)
        let position = center.map { CGPoint(x: $0.x - 75, y: $0.y - 75) } ?? CGPoint(x: 100, y: 100)
        let frame = CGRect(origin: position, size: size)
        let sticker = StickerLayer(url: url, frame: frame)
        addLayer(sticker, toLeftPage: isLeftPage)
    }
    func addPhotoLayer(photo: Photo, isLeftPage: Bool, center: CGPoint? = nil, scale: CGFloat = 1.0) {
        // 计算目标尺寸，保持照片原始比例
        var targetSize = CGSize(width: 300, height: 200) // 默认尺寸
        
        if let w = photo.width, let h = photo.height, w > 0 && h > 0 {
            let aspectRatio = CGFloat(w) / CGFloat(h)
            if aspectRatio > 1 {
                // 横向照片
                targetSize = CGSize(width: 300, height: 300 / aspectRatio)
            } else {
                // 竖向照片
                targetSize = CGSize(width: 300 * aspectRatio, height: 300)
            }
            print("📐 添加照片: \(photo.filename), 原始尺寸: \(w)x\(h), 比例: \(aspectRatio), 目标尺寸: \(targetSize)")
        } else {
            // 如果没有尺寸信息，尝试立即读取
            print("⚠️ 照片缺少尺寸信息: \(photo.filename), 尝试读取...")
            if let imageSource = CGImageSourceCreateWithURL(photo.url as CFURL, nil),
               let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
               let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
               let height = properties[kCGImagePropertyPixelHeight as String] as? Int {
                let aspectRatio = CGFloat(width) / CGFloat(height)
                if aspectRatio > 1 {
                    targetSize = CGSize(width: 300, height: 300 / aspectRatio)
                } else {
                    targetSize = CGSize(width: 300 * aspectRatio, height: 300)
                }
                print("✅ 成功读取尺寸: \(width)x\(height), 目标尺寸: \(targetSize)")
            } else {
                print("❌ 无法读取照片尺寸，使用默认尺寸")
            }
        }
        
        let logicalCenter = center.map { CGPoint(x: $0.x / scale, y: $0.y / scale) } ?? CGPoint(x: 100, y: 100)
        let logicalFrame = CGRect(
            x: logicalCenter.x - targetSize.width / 2,
            y: logicalCenter.y - targetSize.height / 2,
            width: targetSize.width,
            height: targetSize.height
        )
        let newLayer = PhotoLayer(photoId: photo.id, photoUrl: photo.url, frame: logicalFrame)
        if isLeftPage { leftPage.layers.append(AnyLayer(newLayer)) }
        else { rightPage.layers.append(AnyLayer(newLayer)) }
        selectedLayerId = newLayer.id
        lastModified = Date()
        updateCounter += 1
    }
    func addTextLayer(text: String = "文字", isLeftPage: Bool, center: CGPoint? = nil) {
        let position = center ?? CGPoint(x: 100, y: 100)
        let frame = CGRect(x: position.x - 100, y: position.y - 20, width: 200, height: 40)
        let newLayer = TextLayer(text: text, frame: frame)
        if isLeftPage { leftPage.layers.append(AnyLayer(newLayer)) }
        else { rightPage.layers.append(AnyLayer(newLayer)) }
        selectedLayerId = newLayer.id
        lastModified = Date()
        updateCounter += 1
    }
    func updateTextContent(id: LayerID, text: String) {
        if var layer = findLayer(id) as? TextLayer {
            layer.text = text
            updateLayer(layer)
        }
    }
    func updateLayerFrame(_ id: LayerID, newFrame: CGRect) {
        if let idx = leftPage.layers.firstIndex(where: { $0.id == id }) {
            var layer = leftPage.layers[idx]
            layer.frame = newFrame
            leftPage.layers[idx] = layer
        } else if let idx = rightPage.layers.firstIndex(where: { $0.id == id }) {
            var layer = rightPage.layers[idx]
            layer.frame = newFrame
            rightPage.layers[idx] = layer
        }
        lastModified = Date()
        updateCounter += 1
    }
    func updateLayerRotation(_ id: LayerID, newRotation: Double) {
        if let idx = leftPage.layers.firstIndex(where: { $0.id == id }) {
            var layer = leftPage.layers[idx]
            layer.rotation = newRotation
            leftPage.layers[idx] = layer
        } else if let idx = rightPage.layers.firstIndex(where: { $0.id == id }) {
            var layer = rightPage.layers[idx]
            layer.rotation = newRotation
            rightPage.layers[idx] = layer
        }
        lastModified = Date()
        updateCounter += 1
    }
    func deleteSelectedLayer() {
        guard let id = selectedLayerId else { return }
        saveUndoState() // Save state before deleting
        leftPage.layers.removeAll { $0.id == id }
        rightPage.layers.removeAll { $0.id == id }
        selectedLayerId = nil
        lastModified = Date()
        updateCounter += 1
    }
    
    /// Smart delete: deletes selected layer, or single blank page if applicable, or safe delete of spread
    func smartDelete() {
        if selectedLayerId != nil {
            deleteSelectedLayer()
            return
        }
        
        // Try to delete single page based on LAST ACTIVE SIDE
        // User intent: "I clicked this page, now delete it"
        if case .innerSpread(let index) = currentTarget, bookStructure.innerSpreads.count > 0 {
            // If active side is clear, delete that side.
            // But wait, what if I just want to delete the whole spread?
            // Usually, "Delete Page" means delete ONE page. 
            // If both sides are active... well, one side is always "more" active.
            
            // Logic: Always delete the active single page.
            if activePageSide == .left {
                deleteSinglePage(at: index, isLeft: true)
            } else {
                deleteSinglePage(at: index, isLeft: false)
            }
        }
    }
    
    /// Delete a single page and reflow content
    public func deleteSinglePage(at spreadIndex: Int, isLeft: Bool) {
        saveUndoState()
        
        // Step 1: Flatten content
        var allContents: [(layers: [AnyLayer], bgColor: String, bgType: PageModel.BackgroundType, gradientColors: [String]?, patternType: String?, textureType: String?)] = []
        
        for spread in bookStructure.innerSpreads {
            let pages = [spread.left, spread.right]
            for page in pages {
                allContents.append((
                    layers: page.layers,
                    bgColor: page.backgroundColorHex,
                    bgType: page.backgroundType,
                    gradientColors: page.gradientColors,
                    patternType: page.patternType,
                    textureType: page.textureType
                ))
            }
        }
        
        // Step 2: Remove target
        let indexToDelete = spreadIndex * 2 + (isLeft ? 0 : 1)
        guard indexToDelete < allContents.count else { return }
        
        // PROTECTION: Never remove Page 1 (Cover Back) or Last Page (Inside Back Cover)
        // Shifting these would cause photos to disappear into the placeholder-only slots.
        if indexToDelete == 0 {
            allContents[0].layers = []
        } else if indexToDelete == allContents.count - 1 {
            allContents[indexToDelete].layers = []
        } else {
            allContents.remove(at: indexToDelete)
        }
        
        // Step 3: Rebuild spreads
        
        // 1. Trim trailing empty pages (except the first spread)
        while allContents.count > 2 && allContents.last?.layers.isEmpty == true {
            allContents.removeLast()
        }
        
        // 2. If the last page now has content, add one more empty page 
        // to ensure there's always a placeholder-ready spot at the very end.
        if let last = allContents.last, !last.layers.isEmpty {
             allContents.append((layers: [], bgColor: "#FFFFFF", bgType: .solid, gradientColors: nil, patternType: nil, textureType: nil))
        }
        
        let N = allContents.count
        var newSpreads: [(left: PageModel, right: PageModel)] = []
        
        // Fill spreads, padding last if odd
        let spreadCount = Int(ceil(Double(N) / 2.0))
        
        for i in 0..<spreadCount {
            let leftIdx = i * 2
            let rightIdx = i * 2 + 1
            
            var left = PageModel(pageNumber: i * 2 + 1)
            if leftIdx < N {
                let content = allContents[leftIdx]
                left.layers = content.layers
                left.backgroundColorHex = content.bgColor
                left.backgroundType = content.bgType
                left.gradientColors = content.gradientColors
                left.patternType = content.patternType
                left.textureType = content.textureType
            }
            
            var right = PageModel(pageNumber: i * 2 + 2)
            if rightIdx < N {
                let content = allContents[rightIdx]
                right.layers = content.layers
                right.backgroundColorHex = content.bgColor
                right.backgroundType = content.bgType
                right.gradientColors = content.gradientColors
                right.patternType = content.patternType
                right.textureType = content.textureType
            }
            
            newSpreads.append((left, right))
        }
        
        // Update structure
        bookStructure.innerSpreads = newSpreads
        
        // Ensure navigation is valid
        if case .innerSpread(let currentIndex) = currentTarget {
            if currentIndex >= newSpreads.count {
                currentTarget = .innerSpread(index: max(0, newSpreads.count - 1))
            }
        }
        
        loadCurrentState()
        lastModified = Date()
        updateCounter += 1
    }



    
    /// Automatically arrange photos on the target page using AI templates
    func applySmartLayout(photos: [Photo], isLeftPage: Bool, pageSize: PageSize = .a5Landscape) {
        // Block Page 1 (Cover Back) and Last Page (Inside Back Cover)
        if case .innerSpread(let index) = currentTarget {
            let totalSpreads = bookStructure.innerSpreads.count
            if index == 0 && isLeftPage {
                print("⚠️ Cannot apply smart layout to reserved Cover Back page.")
                return
            }
            if index == totalSpreads - 1 && !isLeftPage {
                print("⚠️ Cannot apply smart layout to reserved Back Cover Back page.")
                return
            }
        }
        
        let result = autoLayoutEngine.layoutPhotos(photos, onPageSize: pageSize)
        
        // Target page
        if isLeftPage {
            leftPage.layers = []
            for (photo, frame) in result.photoPlacements {
                let layer = PhotoLayer(photoId: photo.id, photoUrl: photo.url, frame: frame)
                leftPage.layers.append(AnyLayer(layer))
            }
        } else {
            rightPage.layers = []
            for (photo, frame) in result.photoPlacements {
                let layer = PhotoLayer(photoId: photo.id, photoUrl: photo.url, frame: frame)
                rightPage.layers.append(AnyLayer(layer))
            }
        }
        
        lastModified = Date()
        updateCounter += 1
    }
    
    // MARK: - Layer Selection & Z-Order
    
    /// Select a layer by ID
    func selectLayer(_ id: LayerID) {
        selectedLayerId = id
        updateCounter += 1
    }
    
    /// Deselect the currently selected layer
    func deselect() {
        selectedLayerId = nil
        updateCounter += 1
    }
    
    /// Move layer to front (highest z-index)
    func moveLayerToFront(_ id: LayerID) {
        if let idx = leftPage.layers.firstIndex(where: { $0.id == id }) {
            let layer = leftPage.layers.remove(at: idx)
            leftPage.layers.append(layer)
            reindexLayers(isLeft: true)
        } else if let idx = rightPage.layers.firstIndex(where: { $0.id == id }) {
            let layer = rightPage.layers.remove(at: idx)
            rightPage.layers.append(layer)
            reindexLayers(isLeft: false)
        }
        lastModified = Date()
        updateCounter += 1
    }
    
    /// Move layer to back (lowest z-index)
    func moveLayerToBack(_ id: LayerID) {
        if let idx = leftPage.layers.firstIndex(where: { $0.id == id }) {
            let layer = leftPage.layers.remove(at: idx)
            leftPage.layers.insert(layer, at: 0)
            reindexLayers(isLeft: true)
        } else if let idx = rightPage.layers.firstIndex(where: { $0.id == id }) {
            let layer = rightPage.layers.remove(at: idx)
            rightPage.layers.insert(layer, at: 0)
            reindexLayers(isLeft: false)
        }
        lastModified = Date()
        updateCounter += 1
    }
    
    /// Move layer forward by one position
    func moveLayerForward(_ id: LayerID) {
        if let idx = leftPage.layers.firstIndex(where: { $0.id == id }), idx < leftPage.layers.count - 1 {
            leftPage.layers.swapAt(idx, idx + 1)
            reindexLayers(isLeft: true)
        } else if let idx = rightPage.layers.firstIndex(where: { $0.id == id }), idx < rightPage.layers.count - 1 {
            rightPage.layers.swapAt(idx, idx + 1)
            reindexLayers(isLeft: false)
        }
        lastModified = Date()
        updateCounter += 1
    }
    
    /// Move layer backward by one position
    func moveLayerBackward(_ id: LayerID) {
        if let idx = leftPage.layers.firstIndex(where: { $0.id == id }), idx > 0 {
            leftPage.layers.swapAt(idx, idx - 1)
            reindexLayers(isLeft: true)
        } else if let idx = rightPage.layers.firstIndex(where: { $0.id == id }), idx > 0 {
            rightPage.layers.swapAt(idx, idx - 1)
            reindexLayers(isLeft: false)
        }
        lastModified = Date()
        updateCounter += 1
    }
    
    /// Update zIndex property for all layers based on their array order
    private func reindexLayers(isLeft: Bool) {
        var layers = isLeft ? leftPage.layers : rightPage.layers
        for (index, _) in layers.enumerated() {
            var anyLayer = layers[index]
            // We need to mutate the underlying protocol existential
            // This is tricky with AnyLayer. We must check type.
            if var photoLayer = anyLayer.layer as? PhotoLayer {
                photoLayer.zIndex = index
                anyLayer = AnyLayer(photoLayer)
            } else if var textLayer = anyLayer.layer as? TextLayer {
                textLayer.zIndex = index
                anyLayer = AnyLayer(textLayer)
            } else if var stickerLayer = anyLayer.layer as? StickerLayer {
                stickerLayer.zIndex = index
                anyLayer = AnyLayer(stickerLayer)
            }
            layers[index] = anyLayer
        }
        if isLeft { leftPage.layers = layers }
        else { rightPage.layers = layers }
    }

    
    // MARK: - System Sticker & Emoji Support
    
    /// Add a system image sticker
    func addSystemSticker(name: String, colorHex: String?, isLeftPage: Bool, center: CGPoint? = nil) {
        let size = CGSize(width: 100, height: 100)
        let position = center.map { CGPoint(x: $0.x - 50, y: $0.y - 50) } ?? CGPoint(x: 100, y: 100)
        let frame = CGRect(origin: position, size: size)
        let sticker = StickerLayer(systemImage: name, frame: frame, colorHex: colorHex)
        addLayer(sticker, toLeftPage: isLeftPage)
    }
    
    /// Add an emoji sticker
    func addEmojiSticker(emoji: String, isLeftPage: Bool, center: CGPoint? = nil) {
        let size = CGSize(width: 80, height: 80)
        let position = center.map { CGPoint(x: $0.x - 40, y: $0.y - 40) } ?? CGPoint(x: 100, y: 100)
        let frame = CGRect(origin: position, size: size)
        let sticker = StickerLayer(emoji: emoji, frame: frame)
        addLayer(sticker, toLeftPage: isLeftPage)
    }
    
    // MARK: - Text Editing
    
    var textEditingLayerId: LayerID? = nil
    
    /// Alias for textEditingLayerId for compatibility
    var editingTextLayerId: LayerID? {
        get { textEditingLayerId }
        set { textEditingLayerId = newValue }
    }
    
    func startTextEditing(_ id: LayerID) {
        textEditingLayerId = id
        selectedLayerId = id
        updateCounter += 1
    }
    
    func endTextEditing() {
        textEditingLayerId = nil
        updateCounter += 1
    }
    
    func updateTextStyle(id: LayerID, fontSize: Double? = nil, colorHex: String? = nil, 
                         isBold: Bool? = nil, isItalic: Bool? = nil, 
                         alignment: TextLayer.TextAlignment? = nil, fontName: String? = nil) {
        if var layer = findLayer(id) as? TextLayer {
            if let fontSize = fontSize { layer.fontSize = fontSize }
            if let colorHex = colorHex { layer.colorHex = colorHex }
            if let isBold = isBold { layer.isBold = isBold }
            if let isItalic = isItalic { layer.isItalic = isItalic }
            if let alignment = alignment { layer.alignment = alignment }
            if let fontName = fontName { layer.fontName = fontName }
            updateLayer(layer)
        }
    }
}
