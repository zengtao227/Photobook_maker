import Foundation
import SwiftUI

/// Represents a slot where a photo can be placed in a template
struct LayoutSlot: Codable, Hashable {
    /// Normalized coordinates (0.0 to 1.0) relative to page size
    let rect: CGRect
}

/// Predefined layout templates for pages
enum LayoutTemplate: String, Codable, CaseIterable, Identifiable {
    case singleFull
    case singleCentered
    case twoVertical
    case twoHorizontal
    case threeGrid
    case threeArtistic
    case fourGrid
    case fiveHighlight
    
    var id: String { rawValue }
    
    var localizedName: String {
        switch self {
        case .singleFull: return "全屏单图"
        case .singleCentered: return "居中单图"
        case .twoVertical: return "上下双图"
        case .twoHorizontal: return "左右双图"
        case .threeGrid: return "三图网格"
        case .threeArtistic: return "三图艺术排版"
        case .fourGrid: return "四图网格"
        case .fiveHighlight: return "五图聚焦点"
        }
    }
    
    // V2: 适合的场景类型
    var suitableScenes: [SceneCategory] {
        switch self {
        case .singleFull:
            return [.landscape, .portrait, .architecture, .nature]
        case .singleCentered:
            return [.portrait, .food, .animal]
        case .twoVertical:
            return [.landscape, .travel, .nature]
        case .twoHorizontal:
            return [.portrait, .family, .event]
        case .threeGrid:
            return [.event, .travel, .family]
        case .threeArtistic:
            return [.portrait, .family, .event]
        case .fourGrid:
            return [.event, .travel, .food]
        case .fiveHighlight:
            return [.event, .travel, .family]
        }
    }
    
    // V2: 适合的照片数量范围
    var suitablePhotoCount: ClosedRange<Int> {
        switch self {
        case .singleFull, .singleCentered: return 1...1
        case .twoVertical, .twoHorizontal: return 2...2
        case .threeGrid, .threeArtistic: return 3...3
        case .fourGrid: return 4...4
        case .fiveHighlight: return 5...5
        }
    }
    
    // V2: 适合的照片方向
    var suitableOrientations: [PhotoOrientation] {
        switch self {
        case .singleFull:
            return [.landscape, .portrait, .square]
        case .singleCentered:
            return [.portrait, .square]
        case .twoVertical:
            return [.landscape, .square]
        case .twoHorizontal:
            return [.portrait, .square]
        case .threeGrid, .threeArtistic:
            return [.landscape, .portrait, .square]
        case .fourGrid:
            return [.square, .landscape, .portrait]
        case .fiveHighlight:
            return [.landscape, .square]
        }
    }
    
    // V2: 风格标签
    var styleTag: TemplateStyle {
        switch self {
        case .singleFull: return .minimal
        case .singleCentered: return .classic
        case .twoVertical: return .magazine
        case .twoHorizontal: return .family
        case .threeGrid: return .classic
        case .threeArtistic: return .artistic
        case .fourGrid: return .magazine
        case .fiveHighlight: return .travel
        }
    }
    
    var slots: [LayoutSlot] {
        switch self {
        case .singleFull:
            return [LayoutSlot(rect: CGRect(x: 0, y: 0, width: 1, height: 1))]
        case .singleCentered:
            return [LayoutSlot(rect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8))]
        case .twoVertical:
            return [
                LayoutSlot(rect: CGRect(x: 0.1, y: 0.05, width: 0.8, height: 0.425)),
                LayoutSlot(rect: CGRect(x: 0.1, y: 0.525, width: 0.8, height: 0.425))
            ]
        case .twoHorizontal:
            return [
                LayoutSlot(rect: CGRect(x: 0.05, y: 0.1, width: 0.425, height: 0.8)),
                LayoutSlot(rect: CGRect(x: 0.525, y: 0.1, width: 0.425, height: 0.8))
            ]
        case .threeGrid:
            return [
                LayoutSlot(rect: CGRect(x: 0.05, y: 0.05, width: 0.9, height: 0.43)),
                LayoutSlot(rect: CGRect(x: 0.05, y: 0.52, width: 0.43, height: 0.43)),
                LayoutSlot(rect: CGRect(x: 0.52, y: 0.52, width: 0.43, height: 0.43))
            ]
        case .threeArtistic:
            return [
                LayoutSlot(rect: CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.8)),
                LayoutSlot(rect: CGRect(x: 0.65, y: 0.1, width: 0.25, height: 0.35)),
                LayoutSlot(rect: CGRect(x: 0.65, y: 0.55, width: 0.25, height: 0.35))
            ]
        case .fourGrid:
            return [
                LayoutSlot(rect: CGRect(x: 0.05, y: 0.05, width: 0.43, height: 0.43)),
                LayoutSlot(rect: CGRect(x: 0.52, y: 0.05, width: 0.43, height: 0.43)),
                LayoutSlot(rect: CGRect(x: 0.05, y: 0.52, width: 0.43, height: 0.43)),
                LayoutSlot(rect: CGRect(x: 0.52, y: 0.52, width: 0.43, height: 0.43))
            ]
        case .fiveHighlight:
            return [
                LayoutSlot(rect: CGRect(x: 0.05, y: 0.05, width: 0.9, height: 0.4)),
                LayoutSlot(rect: CGRect(x: 0.05, y: 0.5, width: 0.2, height: 0.45)),
                LayoutSlot(rect: CGRect(x: 0.275, y: 0.5, width: 0.2, height: 0.45)),
                LayoutSlot(rect: CGRect(x: 0.5, y: 0.5, width: 0.2, height: 0.45)),
                LayoutSlot(rect: CGRect(x: 0.725, y: 0.5, width: 0.2, height: 0.45))
            ]
        }
    }
    
    static var allTemplates: [LayoutTemplate] {
        return [.singleFull, .singleCentered, .twoVertical, .twoHorizontal, 
                .threeGrid, .threeArtistic, .fourGrid, .fiveHighlight]
    }
    
    /// Get the best template for a given photo count
    static func bestTemplate(forPhotoCount count: Int) -> LayoutTemplate {
        switch count {
        case 0, 1: return .singleFull
        case 2: return .twoVertical
        case 3: return .threeGrid
        case 4: return .fourGrid
        case 5: return .fiveHighlight
        default: return .fourGrid  // For more than 5, use 4-grid and paginate
        }
    }
}
