import Foundation

public enum BookPageSize: String, CaseIterable, Identifiable, Codable {
    case a4Landscape = "A4 Landscape"
    case a5Landscape = "A5 Landscape"
    case a6Landscape = "A6 Landscape"
    case squareLarge = "Square (30x30)"
    case squareMedium = "Square (21x21)"
    case custom = "Custom Size"
    
    public var id: String { rawValue }
    
    /// 页面尺寸（毫米）
    public var dimensions: CGSize {
        switch self {
        case .a4Landscape: return CGSize(width: 297, height: 210)
        case .a5Landscape: return CGSize(width: 210, height: 148)
        case .a6Landscape: return CGSize(width: 148, height: 105)
        case .squareLarge: return CGSize(width: 300, height: 300)
        case .squareMedium: return CGSize(width: 210, height: 210)
        case .custom: return CGSize(width: 210, height: 297) // Default fallback
        }
    }
    
    /// 页面尺寸（points）- 用于逻辑坐标系统
    /// 1mm ≈ 2.83465 points (72 DPI标准)
    public var dimensionsInPoints: CGSize {
        let mm = dimensions
        return CGSize(
            width: mm.width * 2.83465,
            height: mm.height * 2.83465
        )
    }
}

import SwiftUI
import Observation

@Observable
public class BookContext {
    public var pageSize: BookPageSize = .a5Landscape
    public var customWidth: Double = 210
    public var customHeight: Double = 148
    
    // Current active metrics (logic to switch between preset and custom)
    public var currentSize: CGSize {
        if pageSize == .custom {
            return CGSize(width: customWidth, height: customHeight)
        } else {
            return pageSize.dimensions
        }
    }
    
    /// 逻辑页面尺寸（points）- 用于坐标系统
    /// 这个尺寸是固定的，不随窗口大小变化
    public var logicalPageSizeInPoints: CGSize {
        if pageSize == .custom {
            return CGSize(
                width: customWidth * 2.83465,
                height: customHeight * 2.83465
            )
        } else {
            return pageSize.dimensionsInPoints
        }
    }
    
    // Display string for the UI
    public var dimensionString: String {
        return "\(Int(currentSize.width)) x \(Int(currentSize.height)) mm"
    }
    
    public init() {}
}
