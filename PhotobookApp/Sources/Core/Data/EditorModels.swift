import Foundation
import SwiftUI

// MARK: - Layer Protocols

public enum LayerType: String, Codable {
    case photo
    case text
    case sticker
}

public struct LayerID: Identifiable, Hashable, Codable {
    public let id: UUID
    public init() { self.id = UUID() }
    
    public var description: String { id.uuidString }
}

/// Base properties for any layer on the canvas
public protocol LayerProtocol: Identifiable, Codable {
    var id: LayerID { get }
    var type: LayerType { get }
    var frame: CGRect { get set }
    var rotation: Double { get set }
    var zIndex: Int { get set }
    var isLocked: Bool { get set }
}

// MARK: - Concrete Layers

public struct PhotoLayer: LayerProtocol {
    public let id: LayerID
    public var type: LayerType = .photo
    public var frame: CGRect
    public var rotation: Double = 0
    public var zIndex: Int = 0
    public var isLocked: Bool = false
    
    // Photo specific
    public let photoId: UUID // Reference to the original photo
    public let photoUrl: URL // Cached URL for quick access
    public var maskType: MaskType = .rectangle
    
    // Crop properties (Added for Phase 2.1)
    public var cropScale: Double = 1.0
    public var cropOffset: CGSize = .zero
    public var normalizedCropRect: CGRect? // Stores relative crop area (0-1) for re-editing
    public var cropRotation: Double = 0.0 // Corrective rotation inside editor
    
    // Filter properties (Added for Phase 2.1)
    public var filterType: FilterType = .none
    public var brightness: Double = 0.0 // -1 to 1
    public var contrast: Double = 1.0 // 0.5 to 2
    public var saturation: Double = 1.0 // 0 to 2
    
    // Border & Shadow properties (Added for Phase 2.1)
    public var borderWidth: Double = 0.0 // 0 to 20
    public var borderColorHex: String = "#FFFFFF" // Hex color for serialization
    public var shadowRadius: Double = 0.0 // 0 to 30
    public var shadowOpacity: Double = 0.5 // 0 to 1
    
    public enum FilterType: String, Codable, CaseIterable, Sendable {
        case none = "原图"
        case blackAndWhite = "黑白"
        case sepia = "复古"
        case chrome = "铬黄"
        case fade = "褪色"
        case instant = "即时"
        case noir = "黑色电影"
        case process = "冲印"
        case tonal = "单色调"
        case transfer = "转印"
    }
    
    public enum MaskType: String, Codable {
        case rectangle
        case circle
        case heart
    }
    
    public init(photoId: UUID, photoUrl: URL, frame: CGRect) {
        self.id = LayerID()
        self.photoId = photoId
        self.photoUrl = photoUrl
        self.frame = frame
    }
}

public struct TextLayer: LayerProtocol {
    public let id: LayerID
    public var type: LayerType = .text
    public var frame: CGRect
    public var rotation: Double = 0
    public var zIndex: Int = 0
    public var isLocked: Bool = false
    
    // Text content
    public var text: String
    
    // Font properties
    public var fontSize: Double = 24
    public var fontName: String = "Helvetica Neue"
    public var isBold: Bool = false
    public var isItalic: Bool = false
    
    // Color
    public var colorHex: String = "#000000"
    public var backgroundColorHex: String? = nil // Optional background
    
    // Alignment
    public var alignment: TextAlignment = .center
    
    public enum TextAlignment: String, Codable, CaseIterable {
        case leading = "左对齐"
        case center = "居中"
        case trailing = "右对齐"
    }
    
    public init(text: String, frame: CGRect) {
        self.id = LayerID()
        self.text = text
        self.frame = frame
    }
}

// MARK: - Page Model

public struct PageModel: Identifiable, Codable {
    public let id: UUID
    public var pageNumber: Int
    public var layers: [AnyLayer] = [] // Type-erased wrapper
    public var backgroundColorHex: String = "#FFFFFF"
    
    public init(pageNumber: Int) {
        self.id = UUID()
        self.pageNumber = pageNumber
    }
}

/// Type-erased wrapper for Codable support
public struct AnyLayer: Identifiable, Codable {
    public var id: LayerID { layer.id }
    public var layer: any LayerProtocol
    
    public init(_ layer: any LayerProtocol) {
        self.layer = layer
    }
    
    enum CodingKeys: String, CodingKey {
        case type, data
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(LayerType.self, forKey: .type)
        
        switch type {
        case .photo:
            self.layer = try container.decode(PhotoLayer.self, forKey: .data)
        case .text:
            self.layer = try container.decode(TextLayer.self, forKey: .data)
        case .sticker:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Sticker not implemented")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(layer.type, forKey: .type)
        
        if let photoLayer = layer as? PhotoLayer {
            try container.encode(photoLayer, forKey: .data)
        } else if let textLayer = layer as? TextLayer {
            try container.encode(textLayer, forKey: .data)
        }
    }
}
