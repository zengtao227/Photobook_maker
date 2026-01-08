import SwiftUI
import Observation

// MARK: - Supported Languages

public enum AppLanguage: String, CaseIterable {
    case chinese = "zh"
    case english = "en"
    
    public var displayName: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        }
    }
    
    public var flag: String {
        switch self {
        case .chinese: return "🇨🇳"
        case .english: return "🇬🇧"
        }
    }
}

// MARK: - Localization Manager

@Observable
public class LocalizationManager {
    public var currentLanguage: AppLanguage = .chinese
    
    public init() {
        // Load saved preference
        if let saved = UserDefaults.standard.string(forKey: "app_language"),
           let language = AppLanguage(rawValue: saved) {
            currentLanguage = language
        }
    }
    
    public func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "app_language")
    }
    
    public func toggleLanguage() {
        let newLanguage: AppLanguage = currentLanguage == .chinese ? .english : .chinese
        setLanguage(newLanguage)
    }
    
    // MARK: - Localized Strings
    
    public func localized(_ key: LocalizedKey) -> String {
        switch currentLanguage {
        case .chinese: return key.chinese
        case .english: return key.english
        }
    }
    
    // MARK: - Navigation Target Display Name
    
    public func displayName(for target: EditorNavigationTarget) -> String {
        switch target {
        case .frontCover:
            return localized(.frontCover)
        case .backCover:
            return localized(.backCover)
        case .innerSpread(let index):
            return localized(.innerSpreadLabel(index + 1))
        case .fullCoverWrap:
            return localized(.fullCoverWrap)
        }
    }
}

// MARK: - Localized Keys

public enum LocalizedKey {
    // General
    case appName
    case cancel
    case confirm
    case save
    case delete
    case close
    case add
    case edit
    
    // Navigation
    case project
    case backToProjects
    
    // Tools
    case tools
    case leftPageText
    case rightPageText
    case stickers
    case more
    case addTo
    case leftPage
    case rightPage
    
    // Book Settings
    case bookSettings
    case bindingType
    case sizePreset
    case size
    case totalPagesLabel
    case spineWidth
    case pages
    
    // Binding Types
    case softcover
    case hardcover
    case layflat
    case saddleStitch
    case softcoverDesc
    case hardcoverDesc
    case layflatDesc
    case saddleStitchDesc
    
    // Page Navigator
    case cover
    case frontCover
    case backCover
    case innerPages
    case newPage
    case newSpreads(Int)
    case spread
    case currentSpread
    case pageRange(Int, Int)
    case totalPages(Int)
    case needMorePages(Int)
    case innerSpreadLabel(Int)
    case fullCoverWrap
    
    // Validation
    case pagesValid
    case pagesNeedMore(Int)
    
    // Export
    case exportPDF
    case configureExport
    case quickPresets
    case screenPreview
    case homePrint
    case professionalPrint
    case resolution
    case bleedSettings
    case includeBleed
    case bleedMargin
    case bleedExplanation
    case exportMode
    case singlePages
    case spreads
    case productionWrap
    case printMarks
    case cropMarks
    case registrationMarks
    case colorBars
    case pageInfo
    case bookInfo
    case exporting
    case exportComplete
    case exportFailed
    case showInFinder
    case estimatedSize
    case customDPI
    case impositionPreview
    case sheet(Int)
    case frontSide
    case backSide
    case blank
    case sheets(Int)
    
    // Export Help Text
    case cropMarksHelp
    case registrationMarksHelp
    case colorBarsHelp
    case pageInfoHelp
    
    // Layer Settings
    case layerSettings
    case border
    case style
    case width
    case cornerRadius
    case color
    case feathering
    case featherAmount
    case shadow
    case blurRadius
    case opacity
    case filter
    case crop
    
    // Text Settings
    case textSettings
    case content
    case font
    case fontSize
    case alignment
    case editText
    case textAlignLeft
    case textAlignCenter
    case textAlignRight
    case doubleClickToEdit
    
    public var chinese: String {
        switch self {
        case .appName: return "照片书"
        case .cancel: return "取消"
        case .confirm: return "确定"
        case .save: return "保存"
        case .delete: return "删除"
        case .close: return "关闭"
        case .add: return "添加"
        case .edit: return "编辑"
        case .project: return "项目"
        case .backToProjects: return "返回项目列表"
        case .tools: return "工具"
        case .leftPageText: return "左页文字"
        case .rightPageText: return "右页文字"
        case .stickers: return "贴纸"
        case .more: return "更多"
        case .addTo: return "添加到:"
        case .leftPage: return "左页"
        case .rightPage: return "右页"
        case .bookSettings: return "画册设置"
        case .bindingType: return "装订方式"
        case .sizePreset: return "尺寸预设"
        case .size: return "尺寸"
        case .totalPagesLabel: return "总页数"
        case .spineWidth: return "书脊宽度"
        case .pages: return "页"
        case .softcover: return "软皮装"
        case .hardcover: return "精装"
        case .layflat: return "蝴蝶装"
        case .saddleStitch: return "骑马钉"
        case .softcoverDesc: return "胶装：页面按顺序粘贴，适合大多数照片书"
        case .hardcoverDesc: return "精装：硬壳封面，高档感，支持全包封面设计"
        case .layflatDesc: return "蝴蝶装：跨页可完全平摊180°，适合全景照片"
        case .saddleStitchDesc: return "骑马钉：中间装订，页数必须是4的倍数"
        case .cover: return "封面"
        case .frontCover: return "封面"
        case .backCover: return "封底"
        case .innerPages: return "内页"
        case .newPage: return "新建页面"
        case .newSpreads(let count): return "新建 \(count) 跨页"
        case .spread: return "跨页"
        case .currentSpread: return "当前跨页"
        case .pageRange(let start, let end): return "\(start)-\(end)"
        case .pagesValid: return "页数符合要求"
        case .pagesNeedMore(let count): return "还需 \(count) 页"
        case .totalPages(let count): return "共 \(count) 页"
        case .needMorePages(let count): return "需 \(count) 页"
        case .innerSpreadLabel(let index): return "跨页 \(index)"
        case .fullCoverWrap: return "全包封面"
        case .exportPDF: return "导出 PDF"
        case .configureExport: return "配置导出选项"
        case .quickPresets: return "快速预设"
        case .screenPreview: return "屏幕预览"
        case .homePrint: return "家用打印"
        case .professionalPrint: return "专业印刷"
        case .resolution: return "分辨率"
        case .bleedSettings: return "出血设置"
        case .includeBleed: return "添加出血边距"
        case .bleedMargin: return "出血边距"
        case .bleedExplanation: return "出血是指印刷时在裁切线外额外添加的图像区域，防止裁切误差导致白边。专业印刷通常需要3mm出血。"
        case .exportMode: return "导出模式"
        case .singlePages: return "单页导出"
        case .spreads: return "跨页导出"
        case .productionWrap: return "印刷全包"
        case .printMarks: return "印刷标记"
        case .cropMarks: return "裁切线"
        case .registrationMarks: return "套准标记"
        case .colorBars: return "色条"
        case .pageInfo: return "页面信息"
        case .bookInfo: return "相册信息"
        case .exporting: return "导出中..."
        case .exportComplete: return "导出完成"
        case .exportFailed: return "导出失败"
        case .showInFinder: return "在Finder中显示"
        case .estimatedSize: return "预估文件大小"
        case .customDPI: return "自定义:"
        case .impositionPreview: return "拼版预览"
        case .sheet(let num): return "纸 \(num)"
        case .frontSide: return "正面"
        case .backSide: return "背面"
        case .blank: return "空"
        case .sheets(let count): return "\(count) 张纸"
        
        case .cropMarksHelp: return "打印时用于指示裁剪位置的线条。启用此选项可在PDF中显示裁剪标记。"
        case .registrationMarksHelp: return "用于对齐多色印刷的参考标记。启用此选项可在PDF中显示套准标记。"
        case .colorBarsHelp: return "用于检查颜色准确性的参考条。启用此选项可在PDF中显示色调条。"
        case .pageInfoHelp: return "包含页码、日期等元数据的信息。启用此选项可在PDF中显示页面信息。"
        case .layerSettings: return "图层设置"
        case .border: return "边框"
        case .style: return "样式"
        case .width: return "宽度"
        case .cornerRadius: return "圆角"
        case .color: return "颜色"
        case .feathering: return "边缘羽化"
        case .featherAmount: return "羽化程度"
        case .shadow: return "阴影"
        case .blurRadius: return "模糊半径"
        case .opacity: return "透明度"
        case .filter: return "滤镜"
        case .crop: return "裁剪"
        case .textSettings: return "文字设置"
        case .content: return "内容"
        case .font: return "字体"
        case .fontSize: return "字号"
        case .alignment: return "对齐"
        case .editText: return "编辑文字"
        case .textAlignLeft: return "左对齐"
        case .textAlignCenter: return "居中"
        case .textAlignRight: return "右对齐"
        case .doubleClickToEdit: return "双击编辑文字"
        }
    }
    
    public var english: String {
        switch self {
        case .appName: return "Photobook"
        case .cancel: return "Cancel"
        case .confirm: return "OK"
        case .save: return "Save"
        case .delete: return "Delete"
        case .close: return "Close"
        case .add: return "Add"
        case .edit: return "Edit"
        case .project: return "Project"
        case .backToProjects: return "Back to Projects"
        case .tools: return "Tools"
        case .leftPageText: return "Left Text"
        case .rightPageText: return "Right Text"
        case .stickers: return "Stickers"
        case .more: return "More"
        case .addTo: return "Add to:"
        case .leftPage: return "Left"
        case .rightPage: return "Right"
        case .bookSettings: return "Book Settings"
        case .bindingType: return "Binding"
        case .sizePreset: return "Size Preset"
        case .size: return "Size"
        case .totalPagesLabel: return "Total Pages"
        case .spineWidth: return "Spine Width"
        case .pages: return "pages"
        case .softcover: return "Softcover"
        case .hardcover: return "Hardcover"
        case .layflat: return "Layflat"
        case .saddleStitch: return "Saddle Stitch"
        case .softcoverDesc: return "Perfect binding: Pages glued in order, suitable for most photobooks"
        case .hardcoverDesc: return "Hardcover: Rigid cover, premium feel, supports full wrap design"
        case .layflatDesc: return "Layflat: Spreads open completely flat 180°, ideal for panoramic photos"
        case .saddleStitchDesc: return "Saddle stitch: Stapled in middle, pages must be multiple of 4"
        case .cover: return "Cover"
        case .frontCover: return "Front"
        case .backCover: return "Back"
        case .innerPages: return "Inner"
        case .newPage: return "New Page"
        case .newSpreads(let count): return "Add \(count) Spreads"
        case .spread: return "Spread"
        case .currentSpread: return "Current Spread"
        case .pageRange(let start, let end): return "\(start)-\(end)"
        case .pagesValid: return "Page count valid"
        case .pagesNeedMore(let count): return "Need \(count) more"
        case .totalPages(let count): return "Total \(count) pages"
        case .needMorePages(let count): return "Need \(count) pages"
        case .innerSpreadLabel(let index): return "Spread \(index)"
        case .fullCoverWrap: return "Full Cover Wrap"
        case .exportPDF: return "Export PDF"
        case .configureExport: return "Configure export options"
        case .quickPresets: return "Quick Presets"
        case .screenPreview: return "Screen Preview"
        case .homePrint: return "Home Print"
        case .professionalPrint: return "Professional"
        case .resolution: return "Resolution"
        case .bleedSettings: return "Bleed Settings"
        case .includeBleed: return "Add Bleed Margin"
        case .bleedMargin: return "Bleed Margin"
        case .bleedExplanation: return "Bleed is the extra image area beyond the trim line to prevent white edges from cutting errors. Professional printing typically requires 3mm bleed."
        case .exportMode: return "Export Mode"
        case .singlePages: return "Single Pages"
        case .spreads: return "Spreads"
        case .productionWrap: return "Production"
        case .printMarks: return "Print Marks"
        case .cropMarks: return "Crop Marks"
        case .registrationMarks: return "Registration"
        case .colorBars: return "Color Bars"
        case .pageInfo: return "Page Info"
        case .bookInfo: return "Book Info"
        case .exporting: return "Exporting..."
        case .exportComplete: return "Export Complete"
        case .exportFailed: return "Export Failed"
        case .showInFinder: return "Show in Finder"
        case .estimatedSize: return "Estimated Size"
        case .customDPI: return "Custom:"
        case .impositionPreview: return "Imposition Preview"
        case .sheet(let num): return "Sheet \(num)"
        case .frontSide: return "Front"
        case .backSide: return "Back"
        case .blank: return "Blank"
        case .sheets(let count): return "\(count) sheets"
        
        case .cropMarksHelp: return "Lines that indicate where to crop when printing. Enable this to show crop marks in the PDF."
        case .registrationMarksHelp: return "Reference marks for aligning multi-color printing. Enable this to show registration marks in the PDF."
        case .colorBarsHelp: return "Reference bars for checking color accuracy. Enable this to show color bars in the PDF."
        case .pageInfoHelp: return "Metadata information including page numbers and dates. Enable this to show page information in the PDF."
        case .layerSettings: return "Layer Settings"
        case .border: return "Border"
        case .style: return "Style"
        case .width: return "Width"
        case .cornerRadius: return "Corner Radius"
        case .color: return "Color"
        case .feathering: return "Feathering"
        case .featherAmount: return "Feather Amount"
        case .shadow: return "Shadow"
        case .blurRadius: return "Blur Radius"
        case .opacity: return "Opacity"
        case .filter: return "Filter"
        case .crop: return "Crop"
        case .textSettings: return "Text Settings"
        case .content: return "Content"
        case .font: return "Font"
        case .fontSize: return "Font Size"
        case .alignment: return "Alignment"
        case .editText: return "Edit Text"
        case .textAlignLeft: return "Left"
        case .textAlignCenter: return "Center"
        case .textAlignRight: return "Right"
        case .doubleClickToEdit: return "Double-click to edit text"
        }
    }
}

// MARK: - Environment Key

private struct LocalizationManagerKey: EnvironmentKey {
    static let defaultValue = LocalizationManager()
}

extension EnvironmentValues {
    var localization: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}
