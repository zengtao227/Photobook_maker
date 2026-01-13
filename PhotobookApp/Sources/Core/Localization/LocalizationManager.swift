import SwiftUI
import Observation

// MARK: - Supported Languages

public enum AppLanguage: String, CaseIterable {
    case chinese = "zh"
    case english = "en"
    case german = "de"
    case french = "fr"
    
    public var displayName: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        case .german: return "Deutsch"
        case .french: return "Français"
        }
    }
    
    public var flag: String {
        switch self {
        case .chinese: return "🇨🇳"
        case .english: return "🇬🇧"
        case .german: return "🇩🇪"
        case .french: return "🇫🇷"
        }
    }
    
    public var displayNameWithFlag: String {
        return "\(flag) \(displayName)"
    }
    
    public var shortName: String {
        switch self {
        case .chinese: return "中"
        case .english: return "EN"
        case .german: return "DE"
        case .french: return "FR"
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
        case .german: return key.german
        case .french: return key.french
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
    case cut
    case copy
    case paste
    case duplicate
    case bringToFront
    case sendToBack
    case bringForward
    case sendBackward
    
    // Navigation
    case project
    case backToProjects
    case myProjects
    case projectCount(Int)
    case newProject
    case projectFolder
    case projectFolderHelp
    case selectLanguage
    case open
    case rename
    case showInFinder
    case create
    case projectName
    case defaultProjectName
    
    // Tools
    case tools
    case leftPageText
    case rightPageText
    case stickers
    case more
    case addTo
    case leftPage
    case rightPage
    
    case used
    
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
    
    // Page Management
    case pageManagement
    case goToSpread
    case movePage
    case movePageTitle
    case movePageDescription
    case fromPage
    case toPageBefore
    case enterPageNumber
    case pageNumberHint(Int, Int)
    case move
    case undo
    case redo
    
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
    
    // Sticker Picker
    case stickerLibrary
    case stickerFavorites
    case stickerCustom
    case stickerFamily
    case stickerWeather
    case stickerHoliday
    case stickerSeasons
    case stickerFruits
    case openStickersFolder
    case importCustomSticker
    case done
    case swapLeftRight
    
    // Photo Navigation
    case navigateToFrontCover
    case navigateToBackCover
    case navigateToSpread(Int)
    case goToPhotoUsage
    
    case smartImport

    case smartImportWizard
    case selectPhotoSource
    case folder
    case selectPhotos
    case photoLibrary
    case icloud
    case analyzingPhotos
    case analyzingFeatures
    case smartGroupingSuggestions
    case finishEditing
    case deleteSelectedCount(Int)
    case statistics
    case analyzedPhotosCount(Int)
    case detectedFacesCount(Int)
    case locationGroupsCount(Int)
    case chooseDesignStyle
    case prioritySmartTemplate
    case generatingLayout
    case previousStep
    case nextStepLayout
    case startGenerating
    case library
    case selectedCount(Int)
    case clearSelection
    case searchPhotos
    case noPhotos
    case clickImportHelp
    
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
        case .cut: return "剪切"
        case .copy: return "复制"
        case .paste: return "粘贴"
        case .duplicate: return "复制图层"
        case .bringToFront: return "置于顶层"
        case .sendToBack: return "置于底层"
        case .bringForward: return "上移一层"
        case .sendBackward: return "下移一层"
        case .project: return "项目"
        case .backToProjects: return "返回项目列表"
        case .myProjects: return "我的项目"
        case .projectCount(let count): return "\(count) 个项目"
        case .newProject: return "新建项目"
        case .projectFolder: return "项目文件夹"
        case .projectFolderHelp: return "打开项目文件夹，可以备份或转移项目文件"
        case .selectLanguage: return "选择语言"
        case .open: return "打开"
        case .rename: return "重命名"
        case .showInFinder: return "在Finder中显示"
        case .create: return "创建"
        case .projectName: return "项目名称"
        case .defaultProjectName: return "新项目"
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
        
        // Page Management
        case .pageManagement: return "页面管理"
        case .goToSpread: return "跳转到页面"
        case .movePage: return "移动页面"
        case .movePageTitle: return "移动页面"
        case .movePageDescription: return "将第 m 页移动到第 n 页之前"
        case .fromPage: return "从第几页"
        case .toPageBefore: return "移动到第几页之前"
        case .enterPageNumber: return "输入页码"
        case .pageNumberHint(let total, let spreads): return "提示：页码从 1 开始，当前共有 \(total) 页（\(spreads) 个跨页）"
        case .move: return "移动"
        case .undo: return "撤销"
        case .redo: return "重做"
        
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
        case .used: return "已使用"
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
        
        // Sticker Picker
        case .stickerLibrary: return "贴纸库"
        case .stickerFavorites: return "精选/收藏"
        case .stickerCustom: return "自定义"
        case .stickerFamily: return "家庭活动"
        case .stickerWeather: return "天气"
        case .stickerHoliday: return "节日/生日"
        case .stickerSeasons: return "四季"
        case .stickerFruits: return "水果/食物"
        case .openStickersFolder: return "打开贴纸文件夹"
        case .importCustomSticker: return "导入自定义贴纸..."
        case .done: return "完成"
        case .swapLeftRight: return "交换左右页"
        
        // Photo Navigation
        case .navigateToFrontCover: return "前往封面"
        case .navigateToBackCover: return "前往封底"
        case .navigateToSpread(let index): return "前往第 \(index) 跨页"
        case .goToPhotoUsage: return "前往使用此照片的页面"
        
        // Smart Import
        case .smartImport: return "智能导入"
        case .smartImportWizard: return "智能导入向导"
        case .selectPhotoSource: return "选择照片来源"
        case .folder: return "文件夹"
        case .selectPhotos: return "选择照片"
        case .photoLibrary: return "照片库"
        case .icloud: return "iCloud"
        case .analyzingPhotos: return "正在分析照片..."
        case .analyzingFeatures: return "正在本地分析照片特征...\n(场景识别 / 人脸检测 / 质量评估)"
        case .smartGroupingSuggestions: return "智能分组建议"
        case .finishEditing: return "完成编辑"
        case .deleteSelectedCount(let count): return "删除选中 (\(count))"
        case .statistics: return "统计信息"
        case .analyzedPhotosCount(let count): return "已分析照片: \(count) 张"
        case .detectedFacesCount(let count): return "识别人脸: \(count) 组"
        case .locationGroupsCount(let count): return "地点分组: \(count) 个"
        case .chooseDesignStyle: return "选择整书设计风格"
        case .prioritySmartTemplate: return "优先使用智能推荐模板"
        case .generatingLayout: return "正在生成相册排版..."
        case .previousStep: return "上一步"
        case .nextStepLayout: return "下一步: 布局风格"
        case .startGenerating: return "开始生成"
        case .library: return "媒体库"
        case .selectedCount(let count): return "(已选 \(count))"
        case .clearSelection: return "清除"
        case .searchPhotos: return "搜索照片..."
        case .noPhotos: return "暂无照片"
        case .clickImportHelp: return "点击 + 导入文件夹或使用智能导入"
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
        case .cut: return "Cut"
        case .copy: return "Copy"
        case .paste: return "Paste"
        case .duplicate: return "Duplicate"
        case .bringToFront: return "Bring to Front"
        case .sendToBack: return "Send to Back"
        case .bringForward: return "Bring Forward"
        case .sendBackward: return "Send Backward"
        case .project: return "Project"
        case .backToProjects: return "Back to Projects"
        case .myProjects: return "My Projects"
        case .projectCount(let count): return "\(count) projects"
        case .newProject: return "New Project"
        case .projectFolder: return "Project Folder"
        case .projectFolderHelp: return "Open project folder to backup or transfer project files"
        case .selectLanguage: return "Select Language"
        case .open: return "Open"
        case .rename: return "Rename"
        case .showInFinder: return "Show in Finder"
        case .create: return "Create"
        case .projectName: return "Project Name"
        case .defaultProjectName: return "New Project"
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
        
        // Page Management
        case .pageManagement: return "Page Management"
        case .goToSpread: return "Go to Page"
        case .movePage: return "Move Page"
        case .movePageTitle: return "Move Page"
        case .movePageDescription: return "Move page m to before page n"
        case .fromPage: return "From page"
        case .toPageBefore: return "To before page"
        case .enterPageNumber: return "Enter page number"
        case .pageNumberHint(let total, let spreads): return "Hint: Page numbers start from 1, currently \(total) pages (\(spreads) spreads)"
        case .move: return "Move"
        case .undo: return "Undo"
        case .redo: return "Redo"
        
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
        case .used: return "Used"
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
        
        // Sticker Picker
        case .stickerLibrary: return "Sticker Library"
        case .stickerFavorites: return "Favorites"
        case .stickerCustom: return "Custom"
        case .stickerFamily: return "Family"
        case .stickerWeather: return "Weather"
        case .stickerHoliday: return "Holiday"
        case .stickerSeasons: return "Seasons"
        case .stickerFruits: return "Food"
        case .openStickersFolder: return "Open Stickers Folder"
        case .importCustomSticker: return "Import Custom Sticker..."
        case .done: return "Done"
        case .swapLeftRight: return "Swap Left/Right"
        
        // Photo Navigation
        case .navigateToFrontCover: return "Go to Front Cover"
        case .navigateToBackCover: return "Go to Back Cover"
        case .navigateToSpread(let index): return "Go to Spread \(index)"
        case .goToPhotoUsage: return "Go to Photo Usage"
        
        // Smart Import
        case .smartImport: return "Smart Import"
        case .smartImportWizard: return "Smart Import Wizard"
        case .selectPhotoSource: return "Select Photo Source"
        case .folder: return "Folder"
        case .selectPhotos: return "Select Photos"
        case .photoLibrary: return "Photo Library"
        case .icloud: return "iCloud"
        case .analyzingPhotos: return "Analyzing photos..."
        case .analyzingFeatures: return "Analyzing photo features locally...\n(Scene / Face / Quality)"
        case .smartGroupingSuggestions: return "Smart Grouping Suggestions"
        case .finishEditing: return "Finish Editing"
        case .deleteSelectedCount(let count): return "Delete Selected (\(count))"
        case .statistics: return "Statistics"
        case .analyzedPhotosCount(let count): return "Analyzed Photos: \(count)"
        case .detectedFacesCount(let count): return "Detected Faces: \(count) groups"
        case .locationGroupsCount(let count): return "Location Groups: \(count)"
        case .chooseDesignStyle: return "Choose Design Style"
        case .prioritySmartTemplate: return "Prioritize smart recommendations"
        case .generatingLayout: return "Generating layout..."
        case .previousStep: return "Previous"
        case .nextStepLayout: return "Next: Layout Style"
        case .startGenerating: return "Start Generating"
        case .library: return "Library"
        case .selectedCount(let count): return "(\(count) selected)"
        case .clearSelection: return "Clear"
        case .searchPhotos: return "Search photos..."
        case .noPhotos: return "No Photos"
        case .clickImportHelp: return "Click + to import or use Smart Import"
        }
    }
    
    public var german: String {
        switch self {
        case .appName: return "Fotobuch"
        case .cancel: return "Abbrechen"
        case .confirm: return "OK"
        case .save: return "Speichern"
        case .delete: return "Löschen"
        case .close: return "Schließen"
        case .add: return "Hinzufügen"
        case .edit: return "Bearbeiten"
        case .cut: return "Ausschneiden"
        case .copy: return "Kopieren"
        case .paste: return "Einfügen"
        case .duplicate: return "Duplizieren"
        case .bringToFront: return "Ganz nach vorne"
        case .sendToBack: return "Ganz nach hinten"
        case .bringForward: return "Ebene nach vorne"
        case .sendBackward: return "Ebene nach hinten"
        case .project: return "Projekt"
        case .backToProjects: return "Zurück zu Projekten"
        case .myProjects: return "Meine Projekte"
        case .projectCount(let count): return "\(count) Projekte"
        case .newProject: return "Neues Projekt"
        case .projectFolder: return "Projektordner"
        case .projectFolderHelp: return "Projektordner öffnen, um Projektdateien zu sichern oder zu übertragen"
        case .selectLanguage: return "Sprache wählen"
        case .open: return "Öffnen"
        case .rename: return "Umbenennen"
        case .showInFinder: return "Im Finder anzeigen"
        case .create: return "Erstellen"
        case .projectName: return "Projektname"
        case .defaultProjectName: return "Neues Projekt"
        case .tools: return "Werkzeuge"
        case .leftPageText: return "Linker Text"
        case .rightPageText: return "Rechter Text"
        case .stickers: return "Aufkleber"
        case .more: return "Mehr"
        case .addTo: return "Hinzufügen zu:"
        case .leftPage: return "Links"
        case .rightPage: return "Rechts"
        case .bookSettings: return "Bucheinstellungen"
        case .bindingType: return "Bindung"
        case .sizePreset: return "Größenvorlage"
        case .size: return "Größe"
        case .totalPagesLabel: return "Gesamtseitenzahl"
        case .spineWidth: return "Rückenbreite"
        case .pages: return "Seiten"
        case .softcover: return "Softcover"
        case .hardcover: return "Hardcover"
        case .layflat: return "Layflat"
        case .saddleStitch: return "Rückendrahtheftung"
        case .softcoverDesc: return "Klebebindung: Seiten in Reihenfolge geklebt, geeignet für die meisten Fotobücher"
        case .hardcoverDesc: return "Hardcover: Fester Einband, Premium-Gefühl, unterstützt Vollumschlag-Design"
        case .layflatDesc: return "Layflat: Doppelseiten öffnen sich vollständig flach 180°, ideal für Panoramafotos"
        case .saddleStitchDesc: return "Rückendrahtheftung: In der Mitte geheftet, Seitenzahl muss ein Vielfaches von 4 sein"
        case .cover: return "Umschlag"
        case .frontCover: return "Vorderseite"
        case .backCover: return "Rückseite"
        case .innerPages: return "Innenseiten"
        case .newPage: return "Neue Seite"
        case .newSpreads(let count): return "\(count) Doppelseiten hinzufügen"
        case .spread: return "Doppelseite"
        case .currentSpread: return "Aktuelle Doppelseite"
        case .pageRange(let start, let end): return "\(start)-\(end)"
        case .pagesValid: return "Seitenzahl gültig"
        case .pagesNeedMore(let count): return "\(count) weitere benötigt"
        case .totalPages(let count): return "Gesamt \(count) Seiten"
        case .needMorePages(let count): return "\(count) Seiten benötigt"
        case .innerSpreadLabel(let index): return "Doppelseite \(index)"
        case .fullCoverWrap: return "Vollumschlag"
        case .exportPDF: return "PDF exportieren"
        case .configureExport: return "Exportoptionen konfigurieren"
        case .quickPresets: return "Schnellvorlagen"
        case .screenPreview: return "Bildschirmvorschau"
        case .homePrint: return "Heimdruck"
        case .professionalPrint: return "Professionell"
        case .resolution: return "Auflösung"
        case .bleedSettings: return "Beschnitt-Einstellungen"
        case .includeBleed: return "Beschnittzugabe hinzufügen"
        case .bleedMargin: return "Beschnittzugabe"
        case .bleedExplanation: return "Beschnitt ist der zusätzliche Bildbereich über die Schnittlinie hinaus, um weiße Ränder durch Schneidefehler zu vermeiden. Professioneller Druck erfordert typischerweise 3mm Beschnitt."
        case .exportMode: return "Exportmodus"
        case .singlePages: return "Einzelseiten"
        case .spreads: return "Doppelseiten"
        case .productionWrap: return "Produktion"
        case .printMarks: return "Druckmarken"
        case .cropMarks: return "Schnittmarken"
        case .registrationMarks: return "Passermarken"
        case .colorBars: return "Farbbalken"
        case .pageInfo: return "Seiteninformation"
        case .bookInfo: return "Buchinformation"
        case .exporting: return "Exportiere..."
        case .exportComplete: return "Export abgeschlossen"
        case .exportFailed: return "Export fehlgeschlagen"
        case .estimatedSize: return "Geschätzte Größe"
        case .customDPI: return "Benutzerdefiniert:"
        case .impositionPreview: return "Ausschießvorschau"
        case .sheet(let num): return "Bogen \(num)"
        case .frontSide: return "Vorderseite"
        case .backSide: return "Rückseite"
        case .blank: return "Leer"
        case .sheets(let count): return "\(count) Bogen"
        
        case .cropMarksHelp: return "Linien, die beim Drucken anzeigen, wo geschnitten werden soll. Aktivieren Sie dies, um Schnittmarken im PDF anzuzeigen."
        case .registrationMarksHelp: return "Referenzmarken zum Ausrichten des Mehrfarbendrucks. Aktivieren Sie dies, um Passermarken im PDF anzuzeigen."
        case .colorBarsHelp: return "Referenzbalken zur Überprüfung der Farbgenauigkeit. Aktivieren Sie dies, um Farbbalken im PDF anzuzeigen."
        case .pageInfoHelp: return "Metadaten-Informationen einschließlich Seitenzahlen und Daten. Aktivieren Sie dies, um Seiteninformationen im PDF anzuzeigen."
        case .layerSettings: return "Ebeneneinstellungen"
        case .border: return "Rahmen"
        case .style: return "Stil"
        case .width: return "Breite"
        case .cornerRadius: return "Eckenradius"
        case .color: return "Farbe"
        case .feathering: return "Weiche Kante"
        case .featherAmount: return "Weichzeichnungsstärke"
        case .shadow: return "Schatten"
        case .blurRadius: return "Unschärferadius"
        case .opacity: return "Deckkraft"
        case .used: return "Verwendet"
        case .filter: return "Filter"
        case .crop: return "Zuschneiden"
        case .textSettings: return "Texteinstellungen"
        case .content: return "Inhalt"
        case .font: return "Schriftart"
        case .fontSize: return "Schriftgröße"
        case .alignment: return "Ausrichtung"
        case .editText: return "Text bearbeiten"
        case .textAlignLeft: return "Links"
        case .textAlignCenter: return "Zentriert"
        case .textAlignRight: return "Rechts"
        case .doubleClickToEdit: return "Doppelklick zum Bearbeiten"
        
        // Sticker Picker
        case .stickerLibrary: return "Sticker-Bibliothek"
        case .stickerFavorites: return "Favoriten"
        case .stickerCustom: return "Benutzerdefiniert"
        case .stickerFamily: return "Familie"
        case .stickerWeather: return "Wetter"
        case .stickerHoliday: return "Feiertage"
        case .stickerSeasons: return "Jahreszeiten"
        case .stickerFruits: return "Essen"
        case .openStickersFolder: return "Sticker-Ordner öffnen"
        case .importCustomSticker: return "Benutzerdefinierten Sticker importieren..."
        case .done: return "Fertig"
        case .swapLeftRight: return "Links/Rechts tauschen"
        case .pageManagement: return "Seitenverwaltung"
        case .goToSpread: return "Gehe zu Spread"
        case .movePage: return "Seite verschieben"
        case .movePageTitle: return "Seite verschieben"
        case .movePageDescription: return "Seite m vor Seite n verschieben"
        case .fromPage: return "Von Seite"
        case .toPageBefore: return "Bis vor Seite"
        case .enterPageNumber: return "Seitenzahl eingeben"
        case .pageNumberHint(let total, let spreads): return "Hinweis: Seitenzahlen beginnen bei 1, derzeit \(total) Seiten (\(spreads) Doppelseiten)"
        case .move: return "Verschieben"
        case .undo: return "Rückgängig"
        case .redo: return "Wiederholen"
        
        // Photo Navigation
        case .navigateToFrontCover: return "Zum Vorderdeckel"
        case .navigateToBackCover: return "Zum Rückdeckel"
        case .navigateToSpread(let index): return "Zu Doppelseite \(index)"
        case .goToPhotoUsage: return "Zur Fotoverwendung"
        
        // Smart Import
        case .smartImport: return "Intelligenter Import"
        case .smartImportWizard: return "Intelligenter Import-Assistent"
        case .selectPhotoSource: return "Fotoquelle auswählen"
        case .folder: return "Ordner"
        case .selectPhotos: return "Fotos auswählen"
        case .photoLibrary: return "Fotomediathek"
        case .icloud: return "iCloud"
        case .analyzingPhotos: return "Fotos werden analysiert..."
        case .analyzingFeatures: return "Foto-Features werden lokal analysiert...\n(Szene / Gesicht / Qualität)"
        case .smartGroupingSuggestions: return "Intelligente Gruppierungsvorschläge"
        case .finishEditing: return "Bearbeitung abschließen"
        case .deleteSelectedCount(let count): return "Ausgewählte löschen (\(count))"
        case .statistics: return "Statistik"
        case .analyzedPhotosCount(let count): return "Analysierte Fotos: \(count)"
        case .detectedFacesCount(let count): return "Erkannte Gesichter: \(count) Gruppen"
        case .locationGroupsCount(let count): return "Standortgruppen: \(count)"
        case .chooseDesignStyle: return "Designstil wählen"
        case .prioritySmartTemplate: return "Intelligente Empfehlungen bevorzugen"
        case .generatingLayout: return "Layout wird generiert..."
        case .previousStep: return "Zurück"
        case .nextStepLayout: return "Weiter: Layoutstil"
        case .startGenerating: return "Generierung starten"
        case .library: return "Mediathek"
        case .selectedCount(let count): return "(\(count) ausgewählt)"
        case .clearSelection: return "Leeren"
        case .searchPhotos: return "Fotos suchen..."
        case .noPhotos: return "Keine Fotos"
        case .clickImportHelp: return "Klicken Sie auf +, um zu importieren oder Smart Import zu nutzen"
        }
    }
    
    public var french: String {
        switch self {
        case .appName: return "Album Photo"
        case .cancel: return "Annuler"
        case .confirm: return "OK"
        case .save: return "Enregistrer"
        case .delete: return "Supprimer"
        case .close: return "Fermer"
        case .add: return "Ajouter"
        case .edit: return "Modifier"
        case .cut: return "Couper"
        case .copy: return "Copier"
        case .paste: return "Coller"
        case .duplicate: return "Dupliquer"
        case .bringToFront: return "Mettre au premier plan"
        case .sendToBack: return "Mettre à l'arrière-plan"
        case .bringForward: return "Avancer d'un plan"
        case .sendBackward: return "Reculer d'un plan"
        case .project: return "Projet"
        case .backToProjects: return "Retour aux projets"
        case .myProjects: return "Mes Projets"
        case .projectCount(let count): return "\(count) projets"
        case .newProject: return "Nouveau Projet"
        case .projectFolder: return "Dossier de projet"
        case .projectFolderHelp: return "Ouvrir le dossier de projet pour sauvegarder ou transférer les fichiers"
        case .selectLanguage: return "Choisir la langue"
        case .open: return "Ouvrir"
        case .rename: return "Renommer"
        case .showInFinder: return "Afficher dans Finder"
        case .create: return "Créer"
        case .projectName: return "Nom du projet"
        case .defaultProjectName: return "Nouveau Projet"
        case .tools: return "Outils"
        case .leftPageText: return "Texte gauche"
        case .rightPageText: return "Texte droit"
        case .stickers: return "Autocollants"
        case .more: return "Plus"
        case .addTo: return "Ajouter à:"
        case .leftPage: return "Gauche"
        case .rightPage: return "Droite"
        case .bookSettings: return "Paramètres du livre"
        case .bindingType: return "Reliure"
        case .sizePreset: return "Taille prédéfinie"
        case .size: return "Taille"
        case .totalPagesLabel: return "Pages totales"
        case .spineWidth: return "Largeur du dos"
        case .pages: return "pages"
        case .softcover: return "Couverture souple"
        case .hardcover: return "Couverture rigide"
        case .layflat: return "À plat"
        case .saddleStitch: return "Piqûre à cheval"
        case .softcoverDesc: return "Reliure parfaite: Pages collées dans l'ordre, convient à la plupart des albums photo"
        case .hardcoverDesc: return "Couverture rigide: Couverture rigide, sensation premium, prend en charge la conception d'enveloppe complète"
        case .layflatDesc: return "À plat: Les doubles pages s'ouvrent complètement à plat à 180°, idéal pour les photos panoramiques"
        case .saddleStitchDesc: return "Piqûre à cheval: Agrafé au milieu, le nombre de pages doit être un multiple de 4"
        case .cover: return "Couverture"
        case .frontCover: return "Avant"
        case .backCover: return "Arrière"
        case .innerPages: return "Intérieur"
        case .newPage: return "Nouvelle page"
        case .newSpreads(let count): return "Ajouter \(count) doubles pages"
        case .spread: return "Double page"
        case .currentSpread: return "Double page actuelle"
        case .pageRange(let start, let end): return "\(start)-\(end)"
        case .pagesValid: return "Nombre de pages valide"
        case .pagesNeedMore(let count): return "\(count) de plus nécessaires"
        case .totalPages(let count): return "Total \(count) pages"
        case .needMorePages(let count): return "\(count) pages nécessaires"
        case .innerSpreadLabel(let index): return "Double page \(index)"
        case .fullCoverWrap: return "Couverture complète"
        case .pageManagement: return "Gestion des pages"
        case .goToSpread: return "Aller à la double page"
        case .movePage: return "Déplacer la page"
        case .movePageTitle: return "Déplacer la page"
        case .movePageDescription: return "Déplacer la page m avant la page n"
        case .fromPage: return "De la page"
        case .toPageBefore: return "Avant la page"
        case .enterPageNumber: return "Entrer le numéro de page"
        case .pageNumberHint(let total, let spreads): return "Note : Les numéros de page commencent à 1, actuellement \(total) pages (\(spreads) doubles pages)"
        case .move: return "Déplacer"
        case .undo: return "Annuler"
        case .redo: return "Rétablir"
        case .exportPDF: return "Exporter PDF"
        case .configureExport: return "Configurer les options d'export"
        case .quickPresets: return "Préréglages rapides"
        case .screenPreview: return "Aperçu écran"
        case .homePrint: return "Impression maison"
        case .professionalPrint: return "Professionnel"
        case .resolution: return "Résolution"
        case .bleedSettings: return "Paramètres de fond perdu"
        case .includeBleed: return "Ajouter marge de fond perdu"
        case .bleedMargin: return "Marge de fond perdu"
        case .bleedExplanation: return "Le fond perdu est la zone d'image supplémentaire au-delà de la ligne de coupe pour éviter les bords blancs dus aux erreurs de coupe. L'impression professionnelle nécessite généralement 3mm de fond perdu."
        case .exportMode: return "Mode d'export"
        case .singlePages: return "Pages simples"
        case .spreads: return "Doubles pages"
        case .productionWrap: return "Production"
        case .printMarks: return "Marques d'impression"
        case .cropMarks: return "Traits de coupe"
        case .registrationMarks: return "Repères de calage"
        case .colorBars: return "Barres de couleur"
        case .pageInfo: return "Info page"
        case .bookInfo: return "Info livre"
        case .exporting: return "Export en cours..."
        case .exportComplete: return "Export terminé"
        case .exportFailed: return "Échec de l'export"
        case .estimatedSize: return "Taille estimée"
        case .customDPI: return "Personnalisé:"
        case .impositionPreview: return "Aperçu d'imposition"
        case .sheet(let num): return "Feuille \(num)"
        case .frontSide: return "Recto"
        case .backSide: return "Verso"
        case .blank: return "Vide"
        case .sheets(let count): return "\(count) feuilles"
        
        case .cropMarksHelp: return "Lignes indiquant où couper lors de l'impression. Activez cette option pour afficher les traits de coupe dans le PDF."
        case .registrationMarksHelp: return "Marques de référence pour aligner l'impression multicolore. Activez cette option pour afficher les repères de calage dans le PDF."
        case .colorBarsHelp: return "Barres de référence pour vérifier la précision des couleurs. Activez cette option pour afficher les barres de couleur dans le PDF."
        case .pageInfoHelp: return "Informations de métadonnées incluant les numéros de page et les dates. Activez cette option pour afficher les informations de page dans le PDF."
        case .layerSettings: return "Paramètres de calque"
        case .border: return "Bordure"
        case .style: return "Style"
        case .width: return "Largeur"
        case .cornerRadius: return "Rayon des coins"
        case .color: return "Couleur"
        case .feathering: return "Contour progressif"
        case .featherAmount: return "Intensité du contour"
        case .shadow: return "Ombre"
        case .blurRadius: return "Rayon de flou"
        case .opacity: return "Opacité"
        case .used: return "Utilisé"
        case .filter: return "Filtre"
        case .crop: return "Recadrer"
        case .textSettings: return "Paramètres de texte"
        case .content: return "Contenu"
        case .font: return "Police"
        case .fontSize: return "Taille de police"
        case .alignment: return "Alignement"
        case .editText: return "Modifier le texte"
        case .textAlignLeft: return "Gauche"
        case .textAlignCenter: return "Centré"
        case .textAlignRight: return "Droite"
        case .doubleClickToEdit: return "Double-cliquez pour modifier"
        
        // Sticker Picker
        case .stickerLibrary: return "Bibliothèque d'autocollants"
        case .stickerFavorites: return "Favoris"
        case .stickerCustom: return "Personnalisé"
        case .stickerFamily: return "Famille"
        case .stickerWeather: return "Météo"
        case .stickerHoliday: return "Fêtes"
        case .stickerSeasons: return "Saisons"
        case .stickerFruits: return "Nourriture"
        case .openStickersFolder: return "Ouvrir le dossier d'autocollants"
        case .importCustomSticker: return "Importer un autocollant personnalisé..."
        case .done: return "Terminé"
        case .swapLeftRight: return "Échanger gauche/droite"
        
        // Photo Navigation
        case .navigateToFrontCover: return "Aller à la couverture avant"
        case .navigateToBackCover: return "Aller à la couverture arrière"
        case .navigateToSpread(let index): return "Aller à la double page \(index)"
        case .goToPhotoUsage: return "Aller à l'utilisation de la photo"
        
        // Smart Import
        case .smartImport: return "Importation intelligente"
        case .smartImportWizard: return "Assistant d'importation intelligente"
        case .selectPhotoSource: return "Sélectionner la source des photos"
        case .folder: return "Dossier"
        case .selectPhotos: return "Sélectionner des photos"
        case .photoLibrary: return "Photothèque"
        case .icloud: return "iCloud"
        case .analyzingPhotos: return "Analyse des photos..."
        case .analyzingFeatures: return "Analyse locale des caractéristiques des photos...\n(Scène / Visage / Qualité)"
        case .smartGroupingSuggestions: return "Suggestions de groupage intelligent"
        case .finishEditing: return "Terminer l'édition"
        case .deleteSelectedCount(let count): return "Supprimer la sélection (\(count))"
        case .statistics: return "Statistiques"
        case .analyzedPhotosCount(let count): return "Photos analysées: \(count)"
        case .detectedFacesCount(let count): return "Visages détectés: \(count) groupes"
        case .locationGroupsCount(let count): return "Groupes de lieux: \(count)"
        case .chooseDesignStyle: return "Choisir le style de design"
        case .prioritySmartTemplate: return "Prioriser les recommandations intelligentes"
        case .generatingLayout: return "Génération de la mise en page..."
        case .previousStep: return "Précédent"
        case .nextStepLayout: return "Suivant: Style de mise en page"
        case .startGenerating: return "Démarrer la génération"
        case .library: return "Médiathèque"
        case .selectedCount(let count): return "(\(count) sélectionné)"
        case .clearSelection: return "Effacer"
        case .searchPhotos: return "Rechercher des photos..."
        case .noPhotos: return "Pas de photos"
        case .clickImportHelp: return "Cliquez sur + pour importer ou utiliser l'importation intelligente"
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
