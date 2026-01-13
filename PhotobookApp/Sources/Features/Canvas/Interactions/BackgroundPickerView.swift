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
            case .solid:
                return localization.currentLanguage == .chinese ? "纯色" : "Solid"
            case .gradient:
                return localization.currentLanguage == .chinese ? "渐变" : "Gradient"
            case .pattern:
                return localization.currentLanguage == .chinese ? "图案" : "Pattern"
            case .texture:
                return localization.currentLanguage == .chinese ? "纹理" : "Texture"
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
            .navigationTitle(localization.currentLanguage == .chinese ? "背景" : "Background")
        } detail: {
            // 右侧：背景选项
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(backgroundsForCategory(selectedCategory), id: \.id) { background in
                        BackgroundThumbnail(background: background) {
                            applyBackground(background)
                            dismiss()
                        }
                    }
                }
                .padding()
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
            BackgroundItem(id: "white", name: localization.currentLanguage == .chinese ? "皓月白" : "Moon White", type: .solid("#FFFFFF")),
            BackgroundItem(id: "cream", name: localization.currentLanguage == .chinese ? "象牙白" : "Ivory Cream", type: .solid("#FFFDF5")),
            BackgroundItem(id: "beige", name: localization.currentLanguage == .chinese ? "素雅米" : "Elegant Beige", type: .solid("#F5F5DC")),
            BackgroundItem(id: "lightgray", name: localization.currentLanguage == .chinese ? "高级灰" : "Premium Gray", type: .solid("#E8E8E8")),
            BackgroundItem(id: "spacegray", name: localization.currentLanguage == .chinese ? "深空灰" : "Space Gray", type: .solid("#333333")),
            BackgroundItem(id: "charcoal", name: localization.currentLanguage == .chinese ? "磨砂黑" : "Charcoal Black", type: .solid("#1A1A1A")),
            BackgroundItem(id: "midnight", name: localization.currentLanguage == .chinese ? "午夜蓝" : "Midnight Blue", type: .solid("#0A192F")),
            BackgroundItem(id: "forest_solid", name: localization.currentLanguage == .chinese ? "森林绿" : "Forest Green", type: .solid("#1B3022")),
        ]
    }
    
    // 渐变背景
    private var gradientBackgrounds: [BackgroundItem] {
        [
            BackgroundItem(id: "mesh_dream", name: localization.currentLanguage == .chinese ? "幻彩弥散" : "Mesh Dream", type: .texture(.premium_mesh)),
            BackgroundItem(id: "aurora", name: localization.currentLanguage == .chinese ? "极光之森" : "Aurora Borealis", type: .gradient(["#243B55", "#141E30"])),
            BackgroundItem(id: "serenity", name: localization.currentLanguage == .chinese ? "宁静蓝" : "Serenity", type: .gradient(["#E0EAFC", "#CFDEF3"])),
            BackgroundItem(id: "rose_gold", name: localization.currentLanguage == .chinese ? "柔光金" : "Rose Gold", type: .gradient(["#F3904F", "#3B4371"])),
            BackgroundItem(id: "minimal_dark", name: localization.currentLanguage == .chinese ? "极简暗色" : "Minimal Dark", type: .gradient(["#232526", "#414345"])),
            BackgroundItem(id: "champagne", name: localization.currentLanguage == .chinese ? "香槟金" : "Champagne", type: .gradient(["#FFE29F", "#FFA99F", "#FF719A"])),
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
        ]
    }
    
    // 纹理背景
    private var textureBackgrounds: [BackgroundItem] {
        [
            BackgroundItem(id: "premium_mesh_item", name: localization.currentLanguage == .chinese ? "现代弥散" : "Modern Mesh", type: .texture(.premium_mesh)),
            BackgroundItem(id: "japanese_paper", name: localization.currentLanguage == .chinese ? "和纸质感" : "Japanese Paper", type: .texture(.washi_paper)),
            BackgroundItem(id: "white_marble", name: localization.currentLanguage == .chinese ? "雪花大理石" : "White Marble", type: .texture(.marble)),
            BackgroundItem(id: "luxury_linen", name: localization.currentLanguage == .chinese ? "高级亚麻" : "Fine Linen", type: .texture(.fabric)),
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
        case dots
        case stripes
        case grid
        case diagonal
        case hearts
        case stars
    }
    
    enum TextureType: String {
        case paper
        case fabric
        case wood
        case marble
        case premium_mesh
        case washi_paper
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
            case .dots:
                DotsPattern()
            case .stripes:
                StripesPattern()
            case .grid:
                GridPattern()
            case .diagonal:
                DiagonalPattern()
            case .hearts:
                HeartsPattern()
            case .stars:
                StarsPattern()
            }
        }
    }
    
    @ViewBuilder
    private func texturePreview(_ texture: BackgroundItem.TextureType) -> some View {
        ZStack {
            Color.white
            
            Text(texture.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Pattern Views

struct DotsPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 15
            let dotSize: CGFloat = 3
            
            for x in stride(from: 0, to: size.width, by: spacing) {
                for y in stride(from: 0, to: size.height, by: spacing) {
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(.gray.opacity(0.3)))
                }
            }
        }
    }
}

struct StripesPattern: View {
    var body: some View {
        Canvas { context, size in
            let stripeWidth: CGFloat = 10
            
            for x in stride(from: 0, to: size.width, by: stripeWidth * 2) {
                let rect = CGRect(x: x, y: 0, width: stripeWidth, height: size.height)
                context.fill(Path(rect), with: .color(.gray.opacity(0.2)))
            }
        }
    }
}

struct DiagonalPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 20
            
            for offset in stride(from: -size.height, to: size.width + size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: offset, y: 0))
                path.addLine(to: CGPoint(x: offset + size.height, y: size.height))
                context.stroke(path, with: .color(.gray.opacity(0.2)), lineWidth: 1)
            }
        }
    }
}

struct HeartsPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 25
            
            for x in stride(from: 0, to: size.width, by: spacing) {
                for y in stride(from: 0, to: size.height, by: spacing) {
                    context.draw(Text("♥").font(.system(size: 12)), at: CGPoint(x: x, y: y))
                }
            }
        }
    }
}

struct StarsPattern: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 25
            
            for x in stride(from: 0, to: size.width, by: spacing) {
                for y in stride(from: 0, to: size.height, by: spacing) {
                    context.draw(Text("★").font(.system(size: 12)), at: CGPoint(x: x, y: y))
                }
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
                BackgroundItem(id: "white", name: localization.currentLanguage == .chinese ? "皓月白" : "Moon White", type: .solid("#FFFFFF")),
                BackgroundItem(id: "cream", name: localization.currentLanguage == .chinese ? "象牙白" : "Ivory Cream", type: .solid("#FFFDF5")),
                BackgroundItem(id: "beige", name: localization.currentLanguage == .chinese ? "素雅米" : "Elegant Beige", type: .solid("#F5F5DC")),
                BackgroundItem(id: "lightgray", name: localization.currentLanguage == .chinese ? "高级灰" : "Premium Gray", type: .solid("#E8E8E8")),
                BackgroundItem(id: "spacegray", name: localization.currentLanguage == .chinese ? "深空灰" : "Space Gray", type: .solid("#333333")),
                BackgroundItem(id: "charcoal", name: localization.currentLanguage == .chinese ? "磨砂黑" : "Charcoal Black", type: .solid("#1A1A1A")),
            ]
        case .gradient:
            return [
                BackgroundItem(id: "mesh_dream", name: localization.currentLanguage == .chinese ? "幻彩弥散" : "Mesh Dream", type: .texture(.premium_mesh)),
                BackgroundItem(id: "aurora", name: localization.currentLanguage == .chinese ? "极光之森" : "Aurora Borealis", type: .gradient(["#243B55", "#141E30"])),
                BackgroundItem(id: "serenity", name: localization.currentLanguage == .chinese ? "宁静蓝" : "Serenity", type: .gradient(["#E0EAFC", "#CFDEF3"])),
                BackgroundItem(id: "champagne", name: localization.currentLanguage == .chinese ? "香槟金" : "Champagne", type: .gradient(["#FFE29F", "#FFA99F", "#FF719A"])),
            ]
        case .pattern:
            return [
                BackgroundItem(id: "dots", name: "Dots", type: .pattern(.dots)),
                BackgroundItem(id: "stripes", name: "Stripes", type: .pattern(.stripes)),
                BackgroundItem(id: "grid", name: "Grid", type: .pattern(.grid)),
                BackgroundItem(id: "diagonal", name: "Diagonal", type: .pattern(.diagonal)),
                BackgroundItem(id: "hearts", name: "Hearts", type: .pattern(.hearts)),
                BackgroundItem(id: "stars", name: "Stars", type: .pattern(.stars)),
            ]
        case .texture:
            return [
                BackgroundItem(id: "premium_mesh_item", name: localization.currentLanguage == .chinese ? "现代弥散" : "Modern Mesh", type: .texture(.premium_mesh)),
                BackgroundItem(id: "japanese_paper", name: localization.currentLanguage == .chinese ? "和纸质感" : "Japanese Paper", type: .texture(.washi_paper)),
                BackgroundItem(id: "white_marble", name: localization.currentLanguage == .chinese ? "雪花大理石" : "White Marble", type: .texture(.marble)),
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
                Text(textureType.rawValue.prefix(1).uppercased())
                    .font(.title)
                    .foregroundColor(.gray.opacity(0.3))
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
