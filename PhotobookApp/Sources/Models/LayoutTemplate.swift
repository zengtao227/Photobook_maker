import Foundation
import CoreGraphics

/// Page size presets
enum PageSize {
    case a4Landscape    // 297 x 210 mm
    case a4Portrait     // 210 x 297 mm
    case a5Landscape    // 210 x 148 mm
    case a5Portrait     // 148 x 210 mm
    case a6Landscape    // 148 x 105 mm
    case a6Portrait     // 105 x 148 mm
    case squareLarge    // 300 x 300 mm
    case squareMedium   // 210 x 210 mm
    case squareSmall    // 150 x 150 mm
    case custom(width: CGFloat, height: CGFloat)

    /// Size in millimeters
    var sizeInMM: CGSize {
        switch self {
        case .a4Landscape: return CGSize(width: 297, height: 210)
        case .a4Portrait: return CGSize(width: 210, height: 297)
        case .a5Landscape: return CGSize(width: 210, height: 148)
        case .a5Portrait: return CGSize(width: 148, height: 210)
        case .a6Landscape: return CGSize(width: 148, height: 105)
        case .a6Portrait: return CGSize(width: 105, height: 148)
        case .squareLarge: return CGSize(width: 300, height: 300)
        case .squareMedium: return CGSize(width: 210, height: 210)
        case .squareSmall: return CGSize(width: 150, height: 150)
        case .custom(let w, let h): return CGSize(width: w, height: h)
        }
    }

    /// Size in points at 300 DPI
    var sizeInPoints: CGSize {
        let mmToInch: CGFloat = 25.4
        let dpi: CGFloat = 300
        let mm = sizeInMM
        return CGSize(
            width: (mm.width / mmToInch) * dpi,
            height: (mm.height / mmToInch) * dpi
        )
    }

    /// Bleed in points (3mm)
    var bleedInPoints: CGFloat {
        let mmToInch: CGFloat = 25.4
        let dpi: CGFloat = 300
        return (3.0 / mmToInch) * dpi  // 3mm bleed
    }

    var displayName: String {
        switch self {
        case .a4Landscape: return "A4 Landscape"
        case .a4Portrait: return "A4 Portrait"
        case .a5Landscape: return "A5 Landscape"
        case .a5Portrait: return "A5 Portrait"
        case .a6Landscape: return "A6 Landscape"
        case .a6Portrait: return "A6 Portrait"
        case .squareLarge: return "Square Large (30cm)"
        case .squareMedium: return "Square Medium (21cm)"
        case .squareSmall: return "Square Small (15cm)"
        case .custom: return "Custom"
        }
    }
}

/// Layout template for a single page
struct LayoutTemplate: Identifiable {
    let id: String
    let name: String
    let photoCount: Int
    let slots: [PhotoSlot]

    struct PhotoSlot {
        let rect: CGRect  // Normalized rect (0-1)
    }
}

/// Predefined layout templates
extension LayoutTemplate {
    static let fullPage = LayoutTemplate(
        id: "full",
        name: "Full Page",
        photoCount: 1,
        slots: [
            PhotoSlot(rect: CGRect(x: 0, y: 0, width: 1, height: 1))
        ]
    )

    static let twoHorizontal = LayoutTemplate(
        id: "2h",
        name: "2 Horizontal",
        photoCount: 2,
        slots: [
            PhotoSlot(rect: CGRect(x: 0, y: 0, width: 1, height: 0.48)),
            PhotoSlot(rect: CGRect(x: 0, y: 0.52, width: 1, height: 0.48))
        ]
    )

    static let twoVertical = LayoutTemplate(
        id: "2v",
        name: "2 Vertical",
        photoCount: 2,
        slots: [
            PhotoSlot(rect: CGRect(x: 0, y: 0, width: 0.48, height: 1)),
            PhotoSlot(rect: CGRect(x: 0.52, y: 0, width: 0.48, height: 1))
        ]
    )

    static let threeTopOne = LayoutTemplate(
        id: "3t1",
        name: "1 Large + 2 Small",
        photoCount: 3,
        slots: [
            PhotoSlot(rect: CGRect(x: 0, y: 0, width: 1, height: 0.65)),
            PhotoSlot(rect: CGRect(x: 0, y: 0.68, width: 0.48, height: 0.32)),
            PhotoSlot(rect: CGRect(x: 0.52, y: 0.68, width: 0.48, height: 0.32))
        ]
    )

    static let fourGrid = LayoutTemplate(
        id: "4grid",
        name: "4 Grid",
        photoCount: 4,
        slots: [
            PhotoSlot(rect: CGRect(x: 0, y: 0, width: 0.48, height: 0.48)),
            PhotoSlot(rect: CGRect(x: 0.52, y: 0, width: 0.48, height: 0.48)),
            PhotoSlot(rect: CGRect(x: 0, y: 0.52, width: 0.48, height: 0.48)),
            PhotoSlot(rect: CGRect(x: 0.52, y: 0.52, width: 0.48, height: 0.48))
        ]
    )

    static let sixGrid = LayoutTemplate(
        id: "6grid",
        name: "6 Grid",
        photoCount: 6,
        slots: [
            PhotoSlot(rect: CGRect(x: 0, y: 0, width: 0.32, height: 0.48)),
            PhotoSlot(rect: CGRect(x: 0.34, y: 0, width: 0.32, height: 0.48)),
            PhotoSlot(rect: CGRect(x: 0.68, y: 0, width: 0.32, height: 0.48)),
            PhotoSlot(rect: CGRect(x: 0, y: 0.52, width: 0.32, height: 0.48)),
            PhotoSlot(rect: CGRect(x: 0.34, y: 0.52, width: 0.32, height: 0.48)),
            PhotoSlot(rect: CGRect(x: 0.68, y: 0.52, width: 0.32, height: 0.48))
        ]
    )

    static let allTemplates: [LayoutTemplate] = [
        fullPage, twoHorizontal, twoVertical, threeTopOne, fourGrid, sixGrid
    ]

    /// Find best template for given photo count
    static func bestTemplate(forPhotoCount count: Int) -> LayoutTemplate {
        // Find exact match or closest smaller
        let sorted = allTemplates.sorted { $0.photoCount < $1.photoCount }
        return sorted.last { $0.photoCount <= count } ?? fullPage
    }
}
