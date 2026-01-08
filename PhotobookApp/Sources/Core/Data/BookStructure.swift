import Foundation
import SwiftUI

// MARK: - Page Role

/// Defines the role of a page in the photobook
public enum PageRole: String, Codable, CaseIterable {
    case frontCover = "封面"
    case backCover = "封底"
    case innerPage = "内页"
    case fullCoverWrap = "全包封面"  // Hardcover wrap: Back + Spine + Front as single canvas
}

// MARK: - Book Binding Type

/// Type of book binding affects cover layout and spine calculation
public enum BookBindingType: String, Codable, CaseIterable {
    case softcover = "softcover"
    case hardcover = "hardcover"
    case layflat = "layflat"
    case saddleStitch = "saddleStitch"
    
    /// Localized display name
    public func displayName(localization: LocalizationManager) -> String {
        switch self {
        case .softcover:
            return localization.localized(.softcover)
        case .hardcover:
            return localization.localized(.hardcover)
        case .layflat:
            return localization.localized(.layflat)
        case .saddleStitch:
            return localization.localized(.saddleStitch)
        }
    }
    
    /// Whether this binding type supports full cover wrap design
    var supportsFullWrap: Bool {
        self == .hardcover
    }
    
    /// Default paper thickness in mm for this binding type
    var defaultPaperThicknessMM: Double {
        switch self {
        case .softcover: return 0.10
        case .hardcover: return 0.15
        case .layflat: return 0.20
        case .saddleStitch: return 0.08
        }
    }
}

// MARK: - Book Structure

/// Complete book structure with cover and inner pages
public struct BookStructure: Codable {
    
    // MARK: - Cover Pages
    
    /// Front cover (required)
    public var frontCover: PageModel
    
    /// Back cover (required)
    public var backCover: PageModel
    
    /// Full cover wrap for hardcover books (optional)
    /// When set, this is used instead of separate front/back covers for export
    public var fullCoverWrap: PageModel?
    
    // MARK: - Inner Pages
    
    /// Inner spreads (left + right page pairs)
    public var innerSpreads: [(left: PageModel, right: PageModel)]
    
    // MARK: - Book Properties
    
    /// Binding type
    public var bindingType: BookBindingType = .softcover
    
    /// Paper thickness in millimeters (per sheet, not per page)
    public var paperThicknessMM: Double = 0.15
    
    /// Cover board thickness for hardcover (mm)
    public var coverBoardThicknessMM: Double = 2.0
    
    // MARK: - Computed Properties
    
    /// Total number of inner pages (not including covers)
    public var totalInnerPages: Int {
        innerSpreads.count * 2
    }
    
    /// Calculated spine width in millimeters
    public var spineWidthMM: Double {
        // Spine = (inner pages / 2) * paper thickness
        // Because paper thickness is per sheet (2 pages)
        let sheets = Double(totalInnerPages) / 2.0
        return sheets * paperThicknessMM
    }
    
    /// Spine width in points (for rendering)
    public var spineWidthPoints: CGFloat {
        CGFloat(spineWidthMM) * 2.83465 // 1mm ≈ 2.83465 points
    }
    
    /// Total spread count (for navigation)
    public var totalSpreadCount: Int {
        // Cover spread (front+back) + inner spreads
        1 + innerSpreads.count
    }
    
    // MARK: - Initialization
    
    public init(bindingType: BookBindingType = .softcover) {
        self.bindingType = bindingType
        self.paperThicknessMM = bindingType.defaultPaperThicknessMM
        
        // Initialize covers
        self.frontCover = PageModel(pageNumber: 0)
        self.frontCover.backgroundColorHex = "#FFFFFF"
        
        self.backCover = PageModel(pageNumber: -1) // -1 indicates back cover
        self.backCover.backgroundColorHex = "#FFFFFF"
        
        // Initialize with one inner spread
        let leftPage = PageModel(pageNumber: 1)
        let rightPage = PageModel(pageNumber: 2)
        self.innerSpreads = [(left: leftPage, right: rightPage)]
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case frontCover, backCover, fullCoverWrap
        case innerSpreads, bindingType
        case paperThicknessMM, coverBoardThicknessMM
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        frontCover = try container.decode(PageModel.self, forKey: .frontCover)
        backCover = try container.decode(PageModel.self, forKey: .backCover)
        fullCoverWrap = try container.decodeIfPresent(PageModel.self, forKey: .fullCoverWrap)
        bindingType = try container.decode(BookBindingType.self, forKey: .bindingType)
        paperThicknessMM = try container.decode(Double.self, forKey: .paperThicknessMM)
        coverBoardThicknessMM = try container.decode(Double.self, forKey: .coverBoardThicknessMM)
        
        // Decode inner spreads
        let spreadsData = try container.decode([[PageModel]].self, forKey: .innerSpreads)
        innerSpreads = spreadsData.map { pages in
            (left: pages[0], right: pages[1])
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(frontCover, forKey: .frontCover)
        try container.encode(backCover, forKey: .backCover)
        try container.encodeIfPresent(fullCoverWrap, forKey: .fullCoverWrap)
        try container.encode(bindingType, forKey: .bindingType)
        try container.encode(paperThicknessMM, forKey: .paperThicknessMM)
        try container.encode(coverBoardThicknessMM, forKey: .coverBoardThicknessMM)
        
        // Encode inner spreads as array of arrays
        let spreadsData = innerSpreads.map { [$0.left, $0.right] }
        try container.encode(spreadsData, forKey: .innerSpreads)
    }
}

// MARK: - Book Structure Extensions

extension BookStructure {
    
    /// Add a new inner spread
    public mutating func addInnerSpread() {
        let newPageNumber = (innerSpreads.count + 1) * 2
        let leftPage = PageModel(pageNumber: newPageNumber - 1)
        let rightPage = PageModel(pageNumber: newPageNumber)
        innerSpreads.append((left: leftPage, right: rightPage))
    }
    
    /// Remove an inner spread at index
    public mutating func removeInnerSpread(at index: Int) {
        guard index >= 0 && index < innerSpreads.count && innerSpreads.count > 1 else { return }
        innerSpreads.remove(at: index)
        renumberPages()
    }
    
    /// Renumber all pages after structural changes
    private mutating func renumberPages() {
        frontCover.pageNumber = 0
        backCover.pageNumber = -1
        
        for (index, _) in innerSpreads.enumerated() {
            innerSpreads[index].left.pageNumber = index * 2 + 1
            innerSpreads[index].right.pageNumber = index * 2 + 2
        }
    }
    
    /// Create full cover wrap page for hardcover
    public mutating func createFullCoverWrap(pageSize: CGSize) {
        guard bindingType.supportsFullWrap else { return }
        
        // Full wrap = Back Cover + Spine + Front Cover
        // Width = 2 * pageWidth + spineWidth
        var wrapPage = PageModel(pageNumber: -2) // -2 indicates full wrap
        wrapPage.backgroundColorHex = "#FFFFFF"
        fullCoverWrap = wrapPage
    }
    
    /// Calculate full cover wrap dimensions
    public func fullCoverWrapSize(pageSize: CGSize) -> CGSize {
        CGSize(
            width: pageSize.width * 2 + spineWidthPoints,
            height: pageSize.height
        )
    }
}
