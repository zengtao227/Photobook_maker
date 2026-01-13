import SwiftUI

/// 背景选择器 - 为页面选择背景
struct BackgroundPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EditorState.self) private var editorState
    @Environment(LocalizationManager.self) private var localization
    
    let isLeftPage: Bool
    
    @State private var selectedCategory: BackgroundCategory = .solid
    
    enum BackgroundCategory: CaseIterable, Identifiable {
        case solid      // 纯色
        case gradient   // 渐变
        case pattern    // 图案
        case texture    // 纹理
        
        var id: String {
            switch self {
            case .solid: return "solid"
            case .gradient: return "gradient"
            case .pattern: return "pattern"
            case .texture: return "texture"
            }
        }
        
        func localizedName(_ localization: LocalizationManager) -> String {
            switch self {
            case .solid: return localization.localized(.solid)
            case .gradient: return localization.localized(.gradient)
            case .pattern: return localization.localized(.pattern)
            case .texture: return localization.localized(.texture)
            }
        }
        
        var icon: String {
            switch self {
            case .solid: return "square.fill"
            case .gradient: return "square.lefthalf.filled"
            case .pattern: return "square.grid.2x2"
            case .texture: return "square.grid.3x3"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // 左侧：分类列表
            List(BackgroundCategory.allCases, selection: $selectedCategory) { category in
                NavigationLink(value: category) {
                    Label(category.localizedName(localization), systemImage: category.icon)
                }
            }
            .navigationTitle(localization.localized(.background))
        } detail: {
            // 右侧：背景选项
            VStack(spacing: 0) {
                // Opacity Slider (Only for pattern and texture)
                if selectedCategory == .pattern || selectedCategory == .texture {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(localization.currentLanguage == .chinese ? "图案透明度" : "Pattern Opacity")
                                .font(.headline)
                            Spacer()
                            Text("\(Int((isLeftPage ? editorState.leftPage.backgroundOpacity : editorState.rightPage.backgroundOpacity) * 100))%")
                                .font(.caption)
                                .monospacedDigit()
                        }
                        
                        Slider(value: Binding(
                            get: { isLeftPage ? editorState.leftPage.backgroundOpacity : editorState.rightPage.backgroundOpacity },
                            set: { newValue in
                                if isLeftPage {
                                    editorState.leftPage.backgroundOpacity = newValue
                                } else {
                                    editorState.rightPage.backgroundOpacity = newValue
                                }
                                editorState.updateCounter += 1
                            }
                        ), in: 0...1)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                }
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                        ForEach(backgroundsForCategory(selectedCategory), id: \.id) { background in
                            BackgroundThumbnail(background: background) {
                                applyBackground(background)
                                // dismiss() // Keep open to adjust opacity
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(selectedCategory.localizedName(localization))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localization.localized(.done)) {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
    // MARK: - Background Data
    
    private func backgroundsForCategory(_ category: BackgroundCategory) -> [BackgroundItem] {
        switch category {
        case .solid:
            return solidColors
        case .gradient:
            return gradientBackgrounds
        case .pattern:
            return patternBackgrounds
        case .texture:
            return textureBackgrounds
        }
    }
    
    // 纯色背景
    private var solidColors: [BackgroundItem] {
        [
            BackgroundItem(id: "white", name: "White", type: .solid("#FFFFFF")),
            BackgroundItem(id: "cream", name: "Cream", type: .solid("#FFF8E7")),
            BackgroundItem(id: "beige", name: "Beige", type: .solid("#F5F5DC")),
            BackgroundItem(id: "lightgray", name: "Light Gray", type: .solid("#F0F0F0")),
            BackgroundItem(id: "softblue", name: "Soft Blue", type: .solid("#E3F2FD")),
            BackgroundItem(id: "softpink", name: "Soft Pink", type: .solid("#FCE4EC")),
            BackgroundItem(id: "softgreen", name: "Soft Green", type: .solid("#E8F5E9")),
            BackgroundItem(id: "softyellow", name: "Soft Yellow", type: .solid("#FFFDE7")),
            BackgroundItem(id: "lavender", name: "Lavender", type: .solid("#F3E5F5")),
            BackgroundItem(id: "peach", name: "Peach", type: .solid("#FFE0B2")),
            BackgroundItem(id: "mint", name: "Mint", type: .solid("#E0F2F1")),
            BackgroundItem(id: "rose", name: "Rose", type: .solid("#FFEBEE")),
        ]
    }
    
    // 渐变背景
    private var gradientBackgrounds: [BackgroundItem] {
        [
            BackgroundItem(id: "sunset", name: "Sunset", type: .gradient(["#FF6B6B", "#FFE66D"])),
            BackgroundItem(id: "ocean", name: "Ocean", type: .gradient(["#667eea", "#764ba2"])),
            BackgroundItem(id: "forest", name: "Forest", type: .gradient(["#134E5E", "#71B280"])),
            BackgroundItem(id: "candy", name: "Candy", type: .gradient(["#FFA8E2", "#FF6BD6"])),
            BackgroundItem(id: "sky", name: "Sky", type: .gradient(["#56CCF2", "#2F80ED"])),
            BackgroundItem(id: "peach_gradient", name: "Peach", type: .gradient(["#FFECD2", "#FCB69F"])),
            BackgroundItem(id: "purple_dream", name: "Purple Dream", type: .gradient(["#C471F5", "#FA71CD"])),
            BackgroundItem(id: "mint_gradient", name: "Mint", type: .gradient(["#A8EDEA", "#FED6E3"])),
        ]
    }
    
    // 图案背景
    private var patternBackgrounds: [BackgroundItem] {
        [
            BackgroundItem(id: "dots", name: "Dots", type: .pattern(.dots)),
            BackgroundItem(id: "stripes", name: "Stripes", type: .pattern(.stripes)),
            BackgroundItem(id: "grid", name: "Grid", type: .pattern(.grid)),
            BackgroundItem(id: "diagonal", name: "Diagonal", type: .pattern(.diagonal)),
            BackgroundItem(id: "hearts", name: "Hearts", type: .pattern(.hearts)),
            BackgroundItem(id: "stars", name: "Stars", type: .pattern(.stars)),
            BackgroundItem(id: "waves", name: "Waves", type: .pattern(.waves)),
            BackgroundItem(id: "checks", name: "Checks", type: .pattern(.checks)),
            BackgroundItem(id: "zigzag", name: "Zigzag", type: .pattern(.zigzag)),
        ]
    }
    
    // 纹理背景
    private var textureBackgrounds: [BackgroundItem] {
        [
            BackgroundItem(id: "paper", name: "Paper", type: .texture(.paper)),
            BackgroundItem(id: "fabric", name: "Fabric", type: .texture(.fabric)),
            BackgroundItem(id: "wood", name: "Wood", type: .texture(.wood)),
            BackgroundItem(id: "marble", name: "Marble", type: .texture(.marble)),
        ]
    }
    
    // MARK: - Apply Background
    
    private func applyBackground(_ background: BackgroundItem) {
        let pageModel = isLeftPage ? editorState.leftPage : editorState.rightPage
        var updatedPage = pageModel
        
        switch background.type {
        case .solid(let colorHex):
            updatedPage.backgroundColorHex = colorHex
            updatedPage.backgroundType = .solid
            
        case .gradient(let colors):
            updatedPage.backgroundType = .gradient
            updatedPage.gradientColors = colors
            
        case .pattern(let patternType):
            updatedPage.backgroundType = .pattern
            updatedPage.patternType = patternType.rawValue
            
        case .texture(let textureType):
            updatedPage.backgroundType = .texture
            updatedPage.textureType = textureType.rawValue
        }
        
        if isLeftPage {
            editorState.leftPage = updatedPage
        } else {
            editorState.rightPage = updatedPage
        }
        
        editorState.saveCurrentState()
        editorState.lastModified = Date()
        editorState.updateCounter += 1
    }
}

// MARK: - Background Item

struct BackgroundItem: Identifiable {
    let id: String
    let name: String
    let type: BackgroundType
    
    enum BackgroundType {
        case solid(String)  // 颜色hex
        case gradient([String])  // 渐变颜色数组
        case pattern(PatternType)
        case texture(TextureType)
    }
    
    enum PatternType: String {
        case dots, stripes, grid, diagonal, hearts, stars, waves, checks, zigzag
    }
    
    enum TextureType: String {
        case paper
        case fabric
        case wood
        case marble
    }
}

// MARK: - Background Thumbnail

struct BackgroundThumbnail: View {
    let background: BackgroundItem
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 背景预览
                backgroundPreview
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHovering ? Color.blue : Color.gray.opacity(0.3), lineWidth: isHovering ? 2 : 1)
                    )
                
                // 名称标签
                VStack {
                    Spacer()
                    Text(background.name)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                        .padding(4)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    @ViewBuilder
    private var backgroundPreview: some View {
        switch background.type {
        case .solid(let colorHex):
            Color(hex: colorHex)
            
        case .gradient(let colors):
            LinearGradient(
                colors: colors.map { Color(hex: $0) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .pattern(let patternType):
            patternPreview(patternType)
            
        case .texture(let textureType):
            texturePreview(textureType)
        }
    }
    
    @ViewBuilder
    private func patternPreview(_ pattern: BackgroundItem.PatternType) -> some View {
        ZStack {
            Color.white
            
            switch pattern {
            case .dots: DotsPattern()
            case .stripes: StripesPattern()
            case .grid: GridPattern()
            case .diagonal: DiagonalPattern()
            case .hearts: HeartsPattern()
            case .stars: StarsPattern()
            case .waves: WavesPattern()
            case .checks: ChecksPattern()
            case .zigzag: ZigzagPattern()
            }
        }
    }
    
    @ViewBuilder
    private func texturePreview(_ texture: BackgroundItem.TextureType) -> some View {
        ZStack {
            Color.white
            switch texture {
            case .paper: DotsPattern().opacity(0.3)
            case .fabric: DiagonalPattern().opacity(0.4)
            case .wood: StripesPattern().opacity(0.5)
            case .marble: GridPattern().stroke(Color.gray.opacity(0.3), lineWidth: 1.0)
            }
        }
    }
}

// MARK: - Background Picker Popover (Compact version for sidebar)

struct BackgroundPickerPopover: View {
    @Environment(EditorState.self) private var editorState
    @Environment(LocalizationManager.self) private var localization
    
    let isLeftPage: Bool
    
    @State private var selectedCategory: BackgroundCategory = .solid
    
    enum BackgroundCategory: CaseIterable, Identifiable {
        case solid, gradient, pattern, texture
        
        var id: String {
            switch self {
            case .solid: return "solid"
            case .gradient: return "gradient"
            case .pattern: return "pattern"
            case .texture: return "texture"
            }
        }
        
        func localizedName(_ localization: LocalizationManager) -> String {
            switch self {
            case .solid: return localization.currentLanguage == .chinese ? "纯色" : "Solid"
            case .gradient: return localization.currentLanguage == .chinese ? "渐变" : "Gradient"
            case .pattern: return localization.currentLanguage == .chinese ? "图案" : "Pattern"
            case .texture: return localization.currentLanguage == .chinese ? "纹理" : "Texture"
            }
        }
        
        var icon: String {
            switch self {
            case .solid: return "square.fill"
            case .gradient: return "square.lefthalf.filled"
            case .pattern: return "square.grid.2x2"
            case .texture: return "square.grid.3x3"
            }
        }
    }
    
    private var backgrounds: [BackgroundItem] {
        switch selectedCategory {
        case .solid:
            return [
                BackgroundItem(id: "white", name: "White", type: .solid("#FFFFFF")),
                BackgroundItem(id: "cream", name: "Cream", type: .solid("#FFF8E7")),
                BackgroundItem(id: "beige", name: "Beige", type: .solid("#F5F5DC")),
                BackgroundItem(id: "lightgray", name: "Light Gray", type: .solid("#F0F0F0")),
                BackgroundItem(id: "softblue", name: "Soft Blue", type: .solid("#E3F2FD")),
                BackgroundItem(id: "softpink", name: "Soft Pink", type: .solid("#FCE4EC")),
                BackgroundItem(id: "softgreen", name: "Soft Green", type: .solid("#E8F5E9")),
                BackgroundItem(id: "softyellow", name: "Soft Yellow", type: .solid("#FFFDE7")),
                BackgroundItem(id: "lavender", name: "Lavender", type: .solid("#F3E5F5")),
                BackgroundItem(id: "peach", name: "Peach", type: .solid("#FFE0B2")),
                BackgroundItem(id: "mint", name: "Mint", type: .solid("#E0F2F1")),
                BackgroundItem(id: "rose", name: "Rose", type: .solid("#FFEBEE")),
            ]
        case .gradient:
            return [
                BackgroundItem(id: "sunset", name: "Sunset", type: .gradient(["#FF6B6B", "#FFE66D"])),
                BackgroundItem(id: "ocean", name: "Ocean", type: .gradient(["#667eea", "#764ba2"])),
                BackgroundItem(id: "forest", name: "Forest", type: .gradient(["#134E5E", "#71B280"])),
                BackgroundItem(id: "candy", name: "Candy", type: .gradient(["#FFA8E2", "#FF6BD6"])),
                BackgroundItem(id: "sky", name: "Sky", type: .gradient(["#56CCF2", "#2F80ED"])),
                BackgroundItem(id: "peach_gradient", name: "Peach", type: .gradient(["#FFECD2", "#FCB69F"])),
                BackgroundItem(id: "purple_dream", name: "Purple Dream", type: .gradient(["#C471F5", "#FA71CD"])),
                BackgroundItem(id: "mint_gradient", name: "Mint", type: .gradient(["#A8EDEA", "#FED6E3"])),
            ]
        case .pattern:
            return [
                BackgroundItem(id: "dots", name: "Dots", type: .pattern(.dots)),
                BackgroundItem(id: "stripes", name: "Stripes", type: .pattern(.stripes)),
                BackgroundItem(id: "grid", name: "Grid", type: .pattern(.grid)),
                BackgroundItem(id: "diagonal", name: "Diagonal", type: .pattern(.diagonal)),
                BackgroundItem(id: "hearts", name: "Hearts", type: .pattern(.hearts)),
                BackgroundItem(id: "stars", name: "Stars", type: .pattern(.stars)),
                BackgroundItem(id: "waves", name: "Waves", type: .pattern(.waves)),
                BackgroundItem(id: "checks", name: "Checks", type: .pattern(.checks)),
                BackgroundItem(id: "zigzag", name: "Zigzag", type: .pattern(.zigzag)),
            ]
        case .texture:
            return [
                BackgroundItem(id: "paper", name: "Paper", type: .texture(.paper)),
                BackgroundItem(id: "fabric", name: "Fabric", type: .texture(.fabric)),
                BackgroundItem(id: "wood", name: "Wood", type: .texture(.wood)),
                BackgroundItem(id: "marble", name: "Marble", type: .texture(.marble)),
            ]
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(BackgroundCategory.allCases) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 18))
                                Text(category.localizedName(localization))
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(selectedCategory == category ? .blue : .secondary)
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Background grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 12) {
                    ForEach(backgrounds) { background in
                        Button {
                            applyBackground(background)
                        } label: {
                            VStack(spacing: 4) {
                                backgroundPreview(background)
                                    .frame(width: 70, height: 70)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                
                                Text(background.name)
                                    .font(.system(size: 9))
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
            }
        }
    }
    
    @ViewBuilder
    private func backgroundPreview(_ background: BackgroundItem) -> some View {
        switch background.type {
        case .solid(let colorHex):
            Color(hex: colorHex)
            
        case .gradient(let colors):
            LinearGradient(
                colors: colors.map { Color(hex: $0) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
        case .pattern(let patternType):
            ZStack {
                Color.white
                patternView(patternType)
            }
            
        case .texture(let textureType):
            ZStack {
                Color.white
                switch textureType {
                case .paper: DotsPattern().opacity(0.3)
                case .fabric: DiagonalPattern().opacity(0.4)
                case .wood: StripesPattern().opacity(0.5)
                case .marble: GridPattern().stroke(Color.gray.opacity(0.3), lineWidth: 1.0)
                }
            }
        }
    }
    
    @ViewBuilder
    private func patternView(_ pattern: BackgroundItem.PatternType) -> some View {
        switch pattern {
        case .dots: DotsPattern()
        case .stripes: StripesPattern()
        case .grid: GridPattern()
        case .diagonal: DiagonalPattern()
        case .hearts: HeartsPattern()
        case .stars: StarsPattern()
        case .waves: WavesPattern()
        case .checks: ChecksPattern()
        case .zigzag: ZigzagPattern()
        }
    }
    
    private func applyBackground(_ background: BackgroundItem) {
        let pageModel = isLeftPage ? editorState.leftPage : editorState.rightPage
        var updatedPage = pageModel
        
        switch background.type {
        case .solid(let colorHex):
            updatedPage.backgroundColorHex = colorHex
            updatedPage.backgroundType = .solid
            
        case .gradient(let colors):
            updatedPage.backgroundType = .gradient
            updatedPage.gradientColors = colors
            
        case .pattern(let patternType):
            updatedPage.backgroundType = .pattern
            updatedPage.patternType = patternType.rawValue
            
        case .texture(let textureType):
            updatedPage.backgroundType = .texture
            updatedPage.textureType = textureType.rawValue
        }
        
        if isLeftPage {
            editorState.leftPage = updatedPage
        } else {
            editorState.rightPage = updatedPage
        }
        
        editorState.saveCurrentState()
        editorState.lastModified = Date()
        editorState.updateCounter += 1
    }
}
