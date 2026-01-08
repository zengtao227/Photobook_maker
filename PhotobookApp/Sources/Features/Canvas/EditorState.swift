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
public class EditorState {
    // Current Spread State
    public var leftPage: PageModel
    public var rightPage: PageModel
    
    // MARK: - Layer Management
    
    // Selection & Cropping
    public var selectedLayerId: LayerID?
    public var croppingLayerId: LayerID? // New: Track which layer is being cropped
    
    // Change Tracking
    public var lastModified: Date = Date()
    public var updateCounter: Int = 0 // Force UI refresh
    
    // MARK: - Bleed Guide (Phase 3)
    
    /// Whether to show the bleed guide overlay on canvas
    public var showBleedGuide: Bool = false
    
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
    public func navigateToFrontCover() {
        navigateTo(.frontCover)
    }
    
    /// Navigate to back cover
    public func navigateToBackCover() {
        navigateTo(.backCover)
    }
    
    /// Navigate to full cover wrap (hardcover only)
    public func navigateToFullCoverWrap() {
        guard bookStructure.bindingType.supportsFullWrap else { return }
        navigateTo(.fullCoverWrap)
    }
    
    /// Save current left/right pages back to appropriate location
    public func saveCurrentState() {
        print("🔍 DEBUG: saveCurrentState() called, currentTarget: \(currentTarget)")
        print("🔍 DEBUG: leftPage layers: \(leftPage.layers.count), rightPage layers: \(rightPage.layers.count)")
        
        switch currentTarget {
        case .frontCover:
            // 只保存封面（左页），右页是空白不保存
            bookStructure.frontCover = leftPage
            print("🔍 DEBUG: Saved frontCover with \(leftPage.layers.count) layers")
        case .backCover:
            // 只保存封底（右页），左页是空白不保存
            bookStructure.backCover = rightPage
            print("🔍 DEBUG: Saved backCover with \(rightPage.layers.count) layers")
        case .innerSpread(let index):
            guard index < bookStructure.innerSpreads.count else { 
                print("❌ DEBUG: Invalid spread index \(index), total spreads: \(bookStructure.innerSpreads.count)")
                return 
            }
            bookStructure.innerSpreads[index] = (left: leftPage, right: rightPage)
            print("🔍 DEBUG: Saved innerSpread[\(index)] with left:\(leftPage.layers.count) right:\(rightPage.layers.count) layers")
        case .fullCoverWrap:
            bookStructure.fullCoverWrap = leftPage
            print("🔍 DEBUG: Saved fullCoverWrap with \(leftPage.layers.count) layers")
        }
    }
    
    /// Alias for legacy compatibility
    public func saveCurrentSpread() {
        saveCurrentState()
    }
    
    /// Load state based on current target
    private func loadCurrentState() {
        switch currentTarget {
        case .frontCover:
            // 封面：左页显示封面（外面），右页是空白内页（不可编辑）
            leftPage = bookStructure.frontCover
            rightPage = PageModel(pageNumber: -99) // 空白占位页
        case .backCover:
            // 封底：左页是空白内页（不可编辑），右页显示封底（外面）
            leftPage = PageModel(pageNumber: -98) // 空白占位页
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
    
    /// Load state without saving current state (used when opening project)
    public func loadStateWithoutSaving() {
        loadCurrentState()
        selectedLayerId = nil
        lastModified = Date()
        updateCounter += 1
        print("📖 DEBUG: Loaded state for \(currentTarget), leftPage:\(leftPage.layers.count) rightPage:\(rightPage.layers.count)")
    }
    
    /// Add a new inner spread to the book
    public func addNewSpread() {
        // Save current first
        saveCurrentState()
        
        // Add new spread via BookStructure
        bookStructure.addInnerSpread()
        
        // Navigate to new spread
        navigateToSpread(bookStructure.innerSpreads.count - 1)
    }
    
    /// Delete an inner spread from the book
    public func deleteSpread(at index: Int) {
        guard bookStructure.innerSpreads.count > 1, 
              index >= 0 && index < bookStructure.innerSpreads.count else { return }
        
        bookStructure.removeInnerSpread(at: index)
        
        // Adjust navigation if needed
        if case .innerSpread(let currentIndex) = currentTarget {
            if currentIndex >= bookStructure.innerSpreads.count {
                currentTarget = .innerSpread(index: bookStructure.innerSpreads.count - 1)
            }
        }
        
        loadCurrentState()
        lastModified = Date()
        updateCounter += 1
    }
    
    /// Move a spread from one position to another (for drag reordering)
    public func moveSpread(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex >= 0 && sourceIndex < bookStructure.innerSpreads.count,
              destinationIndex >= 0 && destinationIndex < bookStructure.innerSpreads.count,
              sourceIndex != destinationIndex else { return }
        
        // Save current state first
        saveCurrentState()
        
        // Remove from source and insert at destination
        let spread = bookStructure.innerSpreads.remove(at: sourceIndex)
        bookStructure.innerSpreads.insert(spread, at: destinationIndex)
        
        // Update current navigation target if needed
        if case .innerSpread(let currentIndex) = currentTarget {
            if currentIndex == sourceIndex {
                // We moved the current spread
                currentTarget = .innerSpread(index: destinationIndex)
            } else if sourceIndex < currentIndex && destinationIndex >= currentIndex {
                // Spread moved from before to after current
                currentTarget = .innerSpread(index: currentIndex - 1)
            } else if sourceIndex > currentIndex && destinationIndex <= currentIndex {
                // Spread moved from after to before current
                currentTarget = .innerSpread(index: currentIndex + 1)
            }
        }
        
        loadCurrentState()
        lastModified = Date()
        updateCounter += 1
    }
    
    public init() {
        // Initialize BookStructure first
        let structure = BookStructure()
        self.bookStructure = structure
        
        // Initialize with first inner spread
        self.leftPage = structure.innerSpreads[0].left
        self.rightPage = structure.innerSpreads[0].right
        self.currentTarget = .innerSpread(index: 0)
    }
    
    // MARK: - Crop Operations
    
    func startCropping(_ id: LayerID) {
        selectedLayerId = id // Auto select
        croppingLayerId = id
    }
    
    func endCropping() {
        croppingLayerId = nil
    }
    
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
    
    func startFiltering(_ id: LayerID) {
        filteringLayerId = id
    }
    
    func endFiltering() {
        filteringLayerId = nil
    }
    
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
    
    // MARK: - Layer Helpers
    
    private func findLayer(_ id: LayerID) -> (any LayerProtocol)? {
        if let layer = leftPage.layers.first(where: { $0.id == id }) { return layer.layer }
        if let layer = rightPage.layers.first(where: { $0.id == id }) { return layer.layer }
        return nil
    }
    
    private func updateLayer(_ layer: any LayerProtocol) {
        let id = layer.id
        // Update Left Page
        if let idx = leftPage.layers.firstIndex(where: { $0.id == id }) {
            leftPage.layers[idx] = AnyLayer(layer)
        }
        // Update Right Page
        else if let idx = rightPage.layers.firstIndex(where: { $0.id == id }) {
            rightPage.layers[idx] = AnyLayer(layer)
        }
        
        lastModified = Date()
        updateCounter += 1
        updateCounter += 1
    }
    
    private func addLayer(_ layer: any LayerProtocol, toLeftPage: Bool) {
        if toLeftPage {
            leftPage.layers.append(AnyLayer(layer))
        } else {
            rightPage.layers.append(AnyLayer(layer))
        }
        selectedLayerId = layer.id
        lastModified = Date()
        updateCounter += 1
    }
    
    // MARK: - Layer Operations
    
    func addStickerLayer(url: URL, isLeftPage: Bool, center: CGPoint? = nil) {
        let size = CGSize(width: 150, height: 150)
        
        let position: CGPoint
        if let center = center {
            position = CGPoint(x: center.x - size.width/2, y: center.y - size.height/2)
        } else {
            // Randomize slightly
            let offsetX = CGFloat.random(in: 50...150)
            let offsetY = CGFloat.random(in: 50...150)
            
        // Note: In a real app we would get page size from somewhere.
        // For now assuming A4ish.
        position = CGPoint(x: offsetX, y: offsetY)
    }
    
    let frame = CGRect(origin: position, size: size)
    let sticker = StickerLayer(url: url, frame: frame)
    addLayer(sticker, toLeftPage: isLeftPage)
}

func addSystemSticker(name: String, colorHex: String? = nil, isLeftPage: Bool, center: CGPoint? = nil) {
    let size = CGSize(width: 100, height: 100)
    
    let position: CGPoint
    if let center = center {
        position = CGPoint(x: center.x - size.width/2, y: center.y - size.height/2)
    } else {
        let offsetX = CGFloat.random(in: 50...150)
        let offsetY = CGFloat.random(in: 50...150)
        position = CGPoint(x: offsetX, y: offsetY)
    }
    
    let frame = CGRect(origin: position, size: size)
    let sticker = StickerLayer(systemImage: name, frame: frame, colorHex: colorHex)
    addLayer(sticker, toLeftPage: isLeftPage)
}

func addEmojiSticker(emoji: String, isLeftPage: Bool, center: CGPoint? = nil) {
    let size = CGSize(width: 100, height: 100)
    
    let position: CGPoint
    if let center = center {
        position = CGPoint(x: center.x - size.width/2, y: center.y - size.height/2)
    } else {
        let offsetX = CGFloat.random(in: 50...150)
        let offsetY = CGFloat.random(in: 50...150)
        position = CGPoint(x: offsetX, y: offsetY)
    }
    
    let frame = CGRect(origin: position, size: size)
    let sticker = StickerLayer(emoji: emoji, frame: frame)
    addLayer(sticker, toLeftPage: isLeftPage)
}
    
    func addPhotoLayer(photo: Photo, isLeftPage: Bool, center: CGPoint? = nil, scale: CGFloat = 1.0) {
        // Calculate initial size based on image aspect ratio
        var targetSize = CGSize(width: 300, height: 200) // Default fall back (逻辑尺寸)
        
        if let w = photo.width, let h = photo.height, w > 0 && h > 0 {
            let aspectRatio = CGFloat(w) / CGFloat(h)
            if aspectRatio > 1 {
                // Landscape
                targetSize = CGSize(width: 300, height: 300 / aspectRatio)
            } else {
                // Portrait or Square
                targetSize = CGSize(width: 250 * aspectRatio, height: 250)
            }
        }
        
        // Use provided center or a safe default (显示坐标)
        let displayCenter = center ?? CGPoint(x: 100, y: 100)
        
        // 转换为逻辑坐标
        let logicalCenter = CGPoint(
            x: displayCenter.x / scale,
            y: displayCenter.y / scale
        )
        
        // Frame origin = center - half size (逻辑坐标)
        let logicalFrame = CGRect(
            x: logicalCenter.x - targetSize.width / 2,
            y: logicalCenter.y - targetSize.height / 2,
            width: targetSize.width,
            height: targetSize.height
        )
        
        let newLayer = PhotoLayer(photoId: photo.id, photoUrl: photo.url, frame: logicalFrame)
        
        if isLeftPage {
            leftPage.layers.append(AnyLayer(newLayer))
        } else {
            rightPage.layers.append(AnyLayer(newLayer))
        }
        
        // Auto-select the new layer
        selectedLayerId = newLayer.id
        lastModified = Date() // Trigger Save
        
        print("DEBUG: Added photo at logical frame: \(logicalFrame), scale: \(scale)")
    }
    
    // MARK: - Text Layer Operations
    
    func addTextLayer(text: String = "双击编辑文字", isLeftPage: Bool, center: CGPoint? = nil) {
        let position = center ?? CGPoint(x: 200, y: 150)
        let frame = CGRect(x: position.x - 100, y: position.y - 20, width: 200, height: 40)
        
        let newLayer = TextLayer(text: text, frame: frame)
        
        if isLeftPage {
            leftPage.layers.append(AnyLayer(newLayer))
        } else {
            rightPage.layers.append(AnyLayer(newLayer))
        }
        
        selectedLayerId = newLayer.id
        lastModified = Date()
    }
    
    func updateTextContent(id: LayerID, text: String) {
        if var layer = findLayer(id) as? TextLayer {
            layer.text = text
            updateLayer(layer)
        }
    }
    
    func updateTextStyle(id: LayerID, fontSize: Double? = nil, fontName: String? = nil, colorHex: String? = nil, 
                         isBold: Bool? = nil, isItalic: Bool? = nil, alignment: TextLayer.TextAlignment? = nil,
                         backgroundColorHex: String? = nil) {
        if var layer = findLayer(id) as? TextLayer {
            if let fontSize = fontSize { layer.fontSize = fontSize }
            if let fontName = fontName { layer.fontName = fontName }
            if let colorHex = colorHex { layer.colorHex = colorHex }
            if let isBold = isBold { layer.isBold = isBold }
            if let isItalic = isItalic { layer.isItalic = isItalic }
            if let alignment = alignment { layer.alignment = alignment }
            if let backgroundColorHex = backgroundColorHex { layer.backgroundColorHex = backgroundColorHex }
            updateLayer(layer)
        }
    }
    
    // Text editing mode
    var editingTextLayerId: LayerID? = nil
    
    func startTextEditing(_ id: LayerID) {
        editingTextLayerId = id
    }
    
    func endTextEditing() {
        editingTextLayerId = nil
    }
    
    func selectLayer(_ id: LayerID) {
        selectedLayerId = id
    }
    
    func deselect() {
        selectedLayerId = nil
    }
    
    func deleteSelectedLayer() {
        guard let selectedId = selectedLayerId else { return }
        
        // Remove from left page
        if let idx = leftPage.layers.firstIndex(where: { $0.id == selectedId }) {
            leftPage.layers.remove(at: idx)
            selectedLayerId = nil
            lastModified = Date()
            updateCounter += 1
            print("DEBUG: Deleted layer from left page")
            return
        }
        
        // Remove from right page
        if let idx = rightPage.layers.firstIndex(where: { $0.id == selectedId }) {
            rightPage.layers.remove(at: idx)
            selectedLayerId = nil
            lastModified = Date()
            updateCounter += 1
            print("DEBUG: Deleted layer from right page")
            return
        }
    }
    
    // Helper to find which page a layer belongs to
    func updateLayerFrame(_ id: LayerID, newFrame: CGRect) {
        // Left page
        if let idx = leftPage.layers.firstIndex(where: { $0.id == id }) {
            if var photoLayer = leftPage.layers[idx].layer as? PhotoLayer {
                photoLayer.frame = newFrame
                leftPage.layers[idx] = AnyLayer(photoLayer)
            } else if var textLayer = leftPage.layers[idx].layer as? TextLayer {
                textLayer.frame = newFrame
                leftPage.layers[idx] = AnyLayer(textLayer)
            } else if var stickerLayer = leftPage.layers[idx].layer as? StickerLayer {
                stickerLayer.frame = newFrame
                leftPage.layers[idx] = AnyLayer(stickerLayer)
            }
        }
        // Right page
        else if let idx = rightPage.layers.firstIndex(where: { $0.id == id }) {
            if var photoLayer = rightPage.layers[idx].layer as? PhotoLayer {
                photoLayer.frame = newFrame
                rightPage.layers[idx] = AnyLayer(photoLayer)
            } else if var textLayer = rightPage.layers[idx].layer as? TextLayer {
                textLayer.frame = newFrame
                rightPage.layers[idx] = AnyLayer(textLayer)
            } else if var stickerLayer = rightPage.layers[idx].layer as? StickerLayer {
                stickerLayer.frame = newFrame
                rightPage.layers[idx] = AnyLayer(stickerLayer)
            }
        }
        lastModified = Date() // Trigger Save
        updateCounter += 1 // Force UI refresh
        print("DEBUG: Updated frame, counter now: \(updateCounter)")
    }
    
    // Rotation Update Helper
    func updateLayerRotation(_ id: LayerID, newRotation: Double) {
        // Left page
        if let idx = leftPage.layers.firstIndex(where: { $0.id == id }) {
            if var photoLayer = leftPage.layers[idx].layer as? PhotoLayer {
                photoLayer.rotation = newRotation
                leftPage.layers[idx] = AnyLayer(photoLayer)
            } else if var textLayer = leftPage.layers[idx].layer as? TextLayer {
                textLayer.rotation = newRotation
                leftPage.layers[idx] = AnyLayer(textLayer)
            } else if var stickerLayer = leftPage.layers[idx].layer as? StickerLayer {
                stickerLayer.rotation = newRotation
                leftPage.layers[idx] = AnyLayer(stickerLayer)
            }
        }
        // Right page
        else if let idx = rightPage.layers.firstIndex(where: { $0.id == id }) {
            if var photoLayer = rightPage.layers[idx].layer as? PhotoLayer {
                photoLayer.rotation = newRotation
                rightPage.layers[idx] = AnyLayer(photoLayer)
            } else if var textLayer = rightPage.layers[idx].layer as? TextLayer {
                textLayer.rotation = newRotation
                rightPage.layers[idx] = AnyLayer(textLayer)
            } else if var stickerLayer = rightPage.layers[idx].layer as? StickerLayer {
                stickerLayer.rotation = newRotation
                rightPage.layers[idx] = AnyLayer(stickerLayer)
            }
        }
        lastModified = Date()
        updateCounter += 1
    }
    
    // MARK: - Layer Order Management
    
    /// 移到最前（数组最后 = 视觉最上层）
    func moveLayerToFront(_ id: LayerID) {
        if let idx = leftPage.layers.firstIndex(where: { $0.id == id }) {
            let layer = leftPage.layers.remove(at: idx)
            leftPage.layers.append(layer)
            lastModified = Date()
            updateCounter += 1
        } else if let idx = rightPage.layers.firstIndex(where: { $0.id == id }) {
            let layer = rightPage.layers.remove(at: idx)
            rightPage.layers.append(layer)
            lastModified = Date()
            updateCounter += 1
        }
    }
    
    /// 移到最后（数组最前 = 视觉最下层）
    func moveLayerToBack(_ id: LayerID) {
        if let idx = leftPage.layers.firstIndex(where: { $0.id == id }) {
            let layer = leftPage.layers.remove(at: idx)
            leftPage.layers.insert(layer, at: 0)
            lastModified = Date()
            updateCounter += 1
        } else if let idx = rightPage.layers.firstIndex(where: { $0.id == id }) {
            let layer = rightPage.layers.remove(at: idx)
            rightPage.layers.insert(layer, at: 0)
            lastModified = Date()
            updateCounter += 1
        }
    }
    
    /// 前移一层
    func moveLayerForward(_ id: LayerID) {
        if let idx = leftPage.layers.firstIndex(where: { $0.id == id }), idx < leftPage.layers.count - 1 {
            leftPage.layers.swapAt(idx, idx + 1)
            lastModified = Date()
            updateCounter += 1
        } else if let idx = rightPage.layers.firstIndex(where: { $0.id == id }), idx < rightPage.layers.count - 1 {
            rightPage.layers.swapAt(idx, idx + 1)
            lastModified = Date()
            updateCounter += 1
        }
    }
    
    /// 后移一层
    func moveLayerBackward(_ id: LayerID) {
        if let idx = leftPage.layers.firstIndex(where: { $0.id == id }), idx > 0 {
            leftPage.layers.swapAt(idx, idx - 1)
            lastModified = Date()
            updateCounter += 1
        } else if let idx = rightPage.layers.firstIndex(where: { $0.id == id }), idx > 0 {
            rightPage.layers.swapAt(idx, idx - 1)
            lastModified = Date()
            updateCounter += 1
        }
    }
}
