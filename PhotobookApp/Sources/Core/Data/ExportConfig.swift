import Foundation
import SwiftUI

// MARK: - Export Mode

/// PDF export mode options
public enum ExportMode: String, Codable, CaseIterable {
    case singlePages = "singlePages"
    case productionWrap = "productionWrap"
    
    public func displayName(localization: LocalizationManager) -> String {
        switch self {
        case .singlePages:
            return localization.localized(.singlePages)
        case .productionWrap:
            return localization.localized(.productionWrap)
        }
    }
    
    public func description(localization: LocalizationManager) -> String {
        switch self {
        case .singlePages:
            return localization.currentLanguage == .chinese 
                ? "每页单独导出（不推荐，需要自己拼版）" 
                : "Export each page separately (not recommended)"
        case .productionWrap:
            return localization.currentLanguage == .chinese 
                ? "印刷级文件（包含出血、裁切线）" 
                : "Production-ready file with bleed and crop marks"
        }
    }
    
    public var icon: String {
        switch self {
        case .singlePages: return "doc.on.doc"
        case .productionWrap: return "printer"
        }
    }
}

// MARK: - DPI Preset

/// Common DPI presets for export
public enum DPIPreset: Int, CaseIterable, Identifiable {
    case screen = 72
    case standard = 150
    case print = 300
    case highQuality = 600
    
    public var id: Int { rawValue }
    
    public var displayName: String {
        switch self {
        case .screen: return "72 DPI (屏幕)"
        case .standard: return "150 DPI (标准)"
        case .print: return "300 DPI (印刷)"
        case .highQuality: return "600 DPI (高清)"
        }
    }
    
    public var description: String {
        switch self {
        case .screen: return "适合屏幕预览，文件较小"
        case .standard: return "适合家用打印机"
        case .print: return "专业印刷标准"
        case .highQuality: return "超高清，文件较大"
        }
    }
}

// MARK: - Color Profile

/// Color profile for export
public enum ColorProfile: String, Codable, CaseIterable {
    case sRGB = "sRGB"
    case adobeRGB = "Adobe RGB"
    case cmyk = "CMYK"
    
    public var displayName: String {
        switch self {
        case .sRGB: return "sRGB (网络/屏幕)"
        case .adobeRGB: return "Adobe RGB (摄影)"
        case .cmyk: return "CMYK (印刷)"
        }
    }
}

// MARK: - Export Configuration

/// Complete export configuration
public struct ExportConfiguration: Codable {
    
    // MARK: - Resolution
    
    /// Target DPI
    public var dpi: CGFloat = 300
    
    /// DPI preset (for UI convenience)
    public var dpiPreset: DPIPreset {
        get {
            DPIPreset(rawValue: Int(dpi)) ?? .print
        }
        set {
            dpi = CGFloat(newValue.rawValue)
        }
    }
    
    // MARK: - Bleed Settings
    
    /// Whether to include bleed area
    public var includeBleed: Bool = true
    
    /// Bleed margin in millimeters (3mm is industry standard)
    public var bleedMM: CGFloat = 3.0
    
    /// Bleed in points
    public var bleedPoints: CGFloat {
        bleedMM * 2.83465
    }
    
    // MARK: - Export Mode
    
    /// Export mode (single pages or production)
    public var exportMode: ExportMode = .productionWrap
    
    // MARK: - Print Marks
    
    /// Include crop marks (trim marks)
    public var includeCropMarks: Bool = false
    
    /// Include registration marks
    public var includeRegistrationMarks: Bool = false
    
    /// Include color bars
    public var includeColorBars: Bool = false
    
    /// Include page information (file name, date, page number)
    public var includePageInfo: Bool = false
    
    /// Crop mark length in points
    public var cropMarkLength: CGFloat = 12
    
    /// Crop mark offset from trim edge in points
    public var cropMarkOffset: CGFloat = 3
    
    // MARK: - Color
    
    /// Color profile
    public var colorProfile: ColorProfile = .sRGB
    
    // MARK: - Cover Options
    
    /// Export covers separately
    public var exportCoversSeparately: Bool = false
    
    /// Include spine in cover export (for hardcover)
    public var includeSpineInCover: Bool = true
    
    // MARK: - Computed Properties
    
    /// Scale factor for rendering
    public var scaleFactor: CGFloat {
        dpi / 72.0
    }
    
    /// Whether any print marks are enabled
    public var hasPrintMarks: Bool {
        includeCropMarks || includeRegistrationMarks || includeColorBars || includePageInfo
    }
    
    /// Extra margin needed for print marks (in points)
    public var printMarksMargin: CGFloat {
        hasPrintMarks ? 36 : 0 // 0.5 inch margin for marks
    }
    
    // MARK: - Presets
    
    /// Default configuration for screen preview
    public static var screenPreview: ExportConfiguration {
        var config = ExportConfiguration()
        config.dpi = 72
        config.includeBleed = false
        config.exportMode = .productionWrap
        config.includeCropMarks = false
        return config
    }
    
    /// Default configuration for home printing
    public static var homePrint: ExportConfiguration {
        var config = ExportConfiguration()
        config.dpi = 150
        config.includeBleed = false
        config.exportMode = .singlePages
        config.includeCropMarks = false
        return config
    }
    
    /// Default configuration for professional printing
    public static var professionalPrint: ExportConfiguration {
        var config = ExportConfiguration()
        config.dpi = 300
        config.includeBleed = true
        config.bleedMM = 3
        config.exportMode = .productionWrap
        config.includeCropMarks = true
        config.includeRegistrationMarks = true
        config.includeColorBars = true
        config.includePageInfo = true
        return config
    }
}

// MARK: - Export Progress

/// Tracks export progress
public struct ExportProgress {
    public var currentPage: Int = 0
    public var totalPages: Int = 0
    public var currentPhase: ExportPhase = .preparing
    public var message: String = ""
    
    public var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages)
    }
    
    public enum ExportPhase: String {
        case preparing = "准备中..."
        case renderingPages = "渲染页面..."
        case generatingPDF = "生成PDF..."
        case addingMarks = "添加印刷标记..."
        case saving = "保存文件..."
        case complete = "完成"
        case failed = "失败"
    }
}

// MARK: - Export Result

/// Result of export operation
public struct ExportResult {
    public let success: Bool
    public let outputURL: URL?
    public let fileSize: Int64?
    public let pageCount: Int
    public let duration: TimeInterval
    public let error: Error?
    public var sheetCount: Int = 0
    public var printPaperSize: String = ""
    
    public static func success(url: URL, fileSize: Int64, pageCount: Int, duration: TimeInterval, sheetCount: Int = 0, printPaperSize: String = "") -> ExportResult {
        ExportResult(success: true, outputURL: url, fileSize: fileSize, pageCount: pageCount, duration: duration, error: nil, sheetCount: sheetCount, printPaperSize: printPaperSize)
    }
    
    public static func failure(error: Error) -> ExportResult {
        ExportResult(success: false, outputURL: nil, fileSize: nil, pageCount: 0, duration: 0, error: error)
    }
}
