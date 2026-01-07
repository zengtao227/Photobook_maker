import SwiftUI
import Observation

@Observable
public class EditorState {
    // Current Spread State
    public var leftPage: PageModel
    public var rightPage: PageModel
    
    // Selection State
    public var selectedLayerId: LayerID?
    
    // Change Tracking
    public var lastModified: Date = Date()
    public var updateCounter: Int = 0 // Force UI refresh
    
    public init() {
        // Initialize with blank pages
        self.leftPage = PageModel(pageNumber: 2)
        self.rightPage = PageModel(pageNumber: 3)
    }
    
    // MARK: - Layer Management
    
    func addPhotoLayer(photo: Photo, isLeftPage: Bool, center: CGPoint? = nil) {
        let defaultSize = CGSize(width: 200, height: 150)
        // Use provided center or default
        let position = center ?? CGPoint(x: 100, y: 100)
        
        // Frame origin = center - half size
        let newFrame = CGRect(
            x: position.x - defaultSize.width / 2,
            y: position.y - defaultSize.height / 2,
            width: defaultSize.width,
            height: defaultSize.height
        )
        
        let newLayer = PhotoLayer(photoId: photo.id, photoUrl: photo.url, frame: newFrame)
        
        if isLeftPage {
            leftPage.layers.append(AnyLayer(newLayer))
        } else {
            rightPage.layers.append(AnyLayer(newLayer))
        }
        
        // Auto-select the new layer
        selectedLayerId = newLayer.id
        lastModified = Date() // Trigger Save
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
