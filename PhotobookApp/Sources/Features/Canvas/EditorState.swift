import SwiftUI
import Observation

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
    
    public init() {
        // Initialize with blank pages
        self.leftPage = PageModel(pageNumber: 2)
        self.rightPage = PageModel(pageNumber: 3)
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
    
    func updateLayerBorder(id: LayerID, borderWidth: Double, borderColorHex: String) {
        if var layer = findLayer(id) as? PhotoLayer {
            layer.borderWidth = borderWidth
            layer.borderColorHex = borderColorHex
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
    
    func addPhotoLayer(photo: Photo, isLeftPage: Bool, center: CGPoint? = nil) {
        // Calculate initial size based on image aspect ratio
        var targetSize = CGSize(width: 300, height: 200) // Default fall back
        
        if let w = photo.width, let h = photo.height, w > 0 && h > 0 {
            let aspectRatio = CGFloat(w) / CGFloat(h)
            if aspectRatio > 1 {
                // Landscape
                targetSize = CGSize(width: 300, height: 300 / aspectRatio)
            } else {
                // Portrait or Square
                targetSize = CGSize(width: 250 * aspectRatio, height: 250)
            }
        } else {
            // Try loading image metadata if width/height is missing? 
            // For now, use a safer default or logic.
        }
        
        // Use provided center or a safe default
        let position = center ?? CGPoint(x: 100, y: 100)
        
        // Frame origin = center - half size
        let newFrame = CGRect(
            x: position.x - targetSize.width / 2,
            y: position.y - targetSize.height / 2,
            width: targetSize.width,
            height: targetSize.height
        )
        
        let newLayer = PhotoLayer(photoId: photo.id, photoUrl: photo.url, frame: newFrame)
        
        if isLeftPage {
            leftPage.layers.append(AnyLayer(newLayer))
        } else {
            rightPage.layers.append(AnyLayer(newLayer))
        }
        
        // Auto-select the new layer
        // Auto-select the new layer
        selectedLayerId = newLayer.id
        lastModified = Date() // Trigger Save
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
