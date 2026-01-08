import SwiftUI

struct InspectorPanel: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(BookContext.self) private var bookContext
    @Environment(EditorState.self) private var editorState
    @Environment(LocalizationManager.self) private var localization
    
    @State private var showStickerPicker = false
    @State private var stickerTargetIsLeft = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Quick Tools
                toolsSection
                
                // Section: Book Settings
                bookSettingsSection
                
                // Section: Selected Layer (if any)
                if let selectedPhotoLayer = selectedPhotoLayer {
                    photoLayerSettingsSection(for: selectedPhotoLayer)
                } else if let selectedTextLayer = selectedTextLayer {
                    textLayerSettingsSection(for: selectedTextLayer)
                }
            }
            .padding()
        }
        .animation(.easeInOut, value: bookContext.pageSize)
    }
    
    // MARK: - Tools Section
    
    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized(.tools))
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            
            // Add Text Row
            HStack(spacing: 12) {
                Button {
                    editorState.addTextLayer(text: localization.localized(.doubleClickToEdit), isLeftPage: true)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "textformat")
                            .font(.title2)
                        Text(localization.localized(.leftPageText))
                            .font(.caption)
                    }
                    .frame(width: 70, height: 60)
                }
                .buttonStyle(.bordered)
                .help(localization.localized(.leftPageText))
                
                Button {
                    editorState.addTextLayer(text: localization.localized(.doubleClickToEdit), isLeftPage: false)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "textformat")
                            .font(.title2)
                        Text(localization.localized(.rightPageText))
                            .font(.caption)
                    }
                    .frame(width: 70, height: 60)
                }
                .buttonStyle(.bordered)
                .help(localization.localized(.rightPageText))
            }
            
            Divider()
            
            // Stickers Section - Inline display with popover picker
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(localization.localized(.stickers))
                        .font(.subheadline.bold())
                        .foregroundColor(themeManager.theme.textColor)
                    Spacer()
                    Button {
                        showStickerPicker.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Text(localization.localized(.more))
                            Image(systemName: "chevron.right")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(themeManager.theme.accentColor)
                    .popover(isPresented: $showStickerPicker, arrowEdge: .leading) {
                        StickerPickerPopover(isLeftPage: stickerTargetIsLeft)
                            .frame(width: 400, height: 500)
                    }
                }
                
                // Quick sticker grid - show common stickers directly
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 8) {
                    ForEach(quickStickers, id: \.self) { sticker in
                        StickerQuickButton(sticker: sticker) {
                            addQuickSticker(sticker)
                        }
                    }
                }
                
                // Target page selector
                HStack {
                    Text(localization.localized(.addTo))
                        .font(.caption)
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                    
                    Picker("", selection: $stickerTargetIsLeft) {
                        Text(localization.localized(.leftPage)).tag(true)
                        Text(localization.localized(.rightPage)).tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }
        }
        .padding()
        .background(themeManager.theme.backgroundColor.opacity(0.5))
        .cornerRadius(themeManager.theme.cornerRadius)
    }
    
    // Quick stickers for inline display
    private var quickStickers: [String] {
        ["❤️", "⭐️", "🎉", "🎂", "🌸", "☀️", "🎄", "👍", "✨", "🏠"]
    }
    
    private func addQuickSticker(_ emoji: String) {
        editorState.addEmojiSticker(emoji: emoji, isLeftPage: stickerTargetIsLeft)
    }
    
    // MARK: - Book Settings Section
    
    private var bookSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized(.bookSettings))
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            
            // Binding Type Picker - Use Menu instead of Segmented for 4 options
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.bindingType))
                    .font(.caption)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
                
                // Menu Picker for better display of 4 options
                Picker(localization.localized(.bindingType), selection: bindingForBindingType) {
                    ForEach(BookBindingType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: bindingTypeIcon(type))
                            Text(bindingTypeName(type))
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Binding type description - FIXED: Now shows correct description
                Text(bindingTypeDescription(for: editorState.bookStructure.bindingType))
                    .font(.caption2)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
                    .padding(.top, 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider()
            
            // Preset Picker
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.sizePreset))
                    .font(.caption)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
                
                Picker("", selection: Bindable(bookContext).pageSize) {
                    ForEach(BookPageSize.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .labelsHidden()
            }
            
            // Custom Dimensions (Visible only if Custom)
            if bookContext.pageSize == .custom {
                HStack {
                    dimensionField(localization.localized(.width), value: Bindable(bookContext).customWidth)
                    dimensionField(localization.currentLanguage == .chinese ? "高度" : "Height", value: Bindable(bookContext).customHeight)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                // Read-only display
                HStack {
                    Text("\(localization.localized(.size)):")
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                    Spacer()
                    Text(bookContext.dimensionString)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(themeManager.theme.textColor)
                }
                .padding(.top, 4)
            }
            
            // Page count info
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(localization.localized(.totalPagesLabel)):")
                        .font(.caption)
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                    Spacer()
                    Text("\(totalPageCount) \(localization.localized(.pages))")
                        .font(.caption.bold())
                        .foregroundColor(themeManager.theme.textColor)
                }
                
                // FIXED: Only show validation for saddle stitch
                if editorState.bookStructure.bindingType == .saddleStitch {
                    let remainder = totalPageCount % 4
                    if remainder != 0 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(localization.currentLanguage == .chinese 
                                ? "骑马钉需要 4 的倍数，还需 \(4 - remainder) 页"
                                : "Saddle stitch needs multiple of 4, need \(4 - remainder) more")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(localization.localized(.pagesValid))
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                HStack {
                    Text("\(localization.localized(.spineWidth)):")
                        .font(.caption)
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                    Spacer()
                    Text(String(format: "%.1f mm", editorState.bookStructure.spineWidthMM))
                        .font(.caption)
                        .foregroundColor(themeManager.theme.textColor)
                }
            }
        }
        .padding()
        .background(themeManager.theme.backgroundColor.opacity(0.5))
        .cornerRadius(themeManager.theme.cornerRadius)
    }
    
    // MARK: - Binding Type Helpers
    
    private var bindingForBindingType: Binding<BookBindingType> {
        Binding(
            get: { editorState.bookStructure.bindingType },
            set: { newType in
                editorState.bookStructure.bindingType = newType
                editorState.bookStructure.paperThicknessMM = newType.defaultPaperThicknessMM
                editorState.lastModified = Date()
                editorState.updateCounter += 1
            }
        )
    }
    
    private func bindingTypeIcon(_ type: BookBindingType) -> String {
        switch type {
        case .softcover: return "book.closed"
        case .hardcover: return "book.closed.fill"
        case .layflat: return "book.pages"
        case .saddleStitch: return "paperclip"
        }
    }
    
    // Localized binding type name
    private func bindingTypeName(_ type: BookBindingType) -> String {
        switch type {
        case .softcover: return localization.localized(.softcover)
        case .hardcover: return localization.localized(.hardcover)
        case .layflat: return localization.localized(.layflat)
        case .saddleStitch: return localization.localized(.saddleStitch)
        }
    }
    
    // Localized binding type description
    private func bindingTypeDescription(for type: BookBindingType) -> String {
        switch type {
        case .softcover:
            return localization.localized(.softcoverDesc)
        case .hardcover:
            return localization.localized(.hardcoverDesc)
        case .layflat:
            return localization.localized(.layflatDesc)
        case .saddleStitch:
            return localization.localized(.saddleStitchDesc)
        }
    }
    
    private var totalPageCount: Int {
        editorState.bookStructure.totalInnerPages + 2 // +2 for covers
    }
    
    // MARK: - Photo Layer Settings Section
    
    private func photoLayerSettingsSection(for layer: PhotoLayer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized(.layerSettings))
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            
            // Border Settings
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.border))
                    .font(.subheadline.bold())
                    .foregroundColor(themeManager.theme.textColor)
                
                // Border Style Picker - Visual preview
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.localized(.style))
                        .font(.caption)
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                    
                    HStack(spacing: 8) {
                        ForEach(PhotoLayer.BorderStyle.allCases, id: \.self) { style in
                            BorderStyleButton(
                                style: style,
                                isSelected: layer.borderStyle == style,
                                color: Color(hex: layer.borderColorHex)
                            ) {
                                editorState.updateLayerBorder(id: layer.id, borderStyle: style)
                            }
                        }
                    }
                }
                
                // Border Width
                HStack {
                    Text(localization.localized(.width))
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.0f px", layer.borderWidth))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: bindingForBorderWidth(layer), in: 0...20)
                
                // Corner Radius
                HStack {
                    Text(localization.localized(.cornerRadius))
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.0f px", layer.borderCornerRadius))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: bindingForBorderCornerRadius(layer), in: 0...50)
                
                // Border Color
                HStack {
                    Text(localization.localized(.color))
                        .font(.caption)
                    Spacer()
                    ColorPicker("", selection: bindingForBorderColor(layer))
                        .labelsHidden()
                }
            }
            
            Divider()
            
            // Feathering Settings
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.feathering))
                    .font(.subheadline.bold())
                    .foregroundColor(themeManager.theme.textColor)
                
                HStack {
                    Text(localization.localized(.featherAmount))
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.0f px", layer.feathering))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: bindingForFeathering(layer), in: 0...50)
            }
            
            Divider()
            
            // Shadow Settings
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.shadow))
                    .font(.subheadline.bold())
                    .foregroundColor(themeManager.theme.textColor)
                
                // Shadow Radius
                HStack {
                    Text(localization.localized(.blurRadius))
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.0f", layer.shadowRadius))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: bindingForShadowRadius(layer), in: 0...30)
                
                // Shadow Opacity
                HStack {
                    Text(localization.localized(.opacity))
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.0f%%", layer.shadowOpacity * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: bindingForShadowOpacity(layer), in: 0...1)
            }
            
            Divider()
            
            // Quick Actions
            HStack {
                Button(localization.localized(.filter)) {
                    editorState.startFiltering(layer.id)
                }
                .buttonStyle(.bordered)
                
                Button(localization.localized(.crop)) {
                    editorState.startCropping(layer.id)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(themeManager.theme.backgroundColor.opacity(0.5))
        .cornerRadius(themeManager.theme.cornerRadius)
    }
    
    // MARK: - Text Layer Settings Section
    
    private func textLayerSettingsSection(for layer: TextLayer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.localized(.textSettings))
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.localized(.content))
                    .font(.caption)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
                TextField(localization.localized(.editText), text: bindingForTextContent(layer))
                    .textFieldStyle(.roundedBorder)
            }
            
            Divider()
            
            // Font Style
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.style))
                    .font(.subheadline.bold())
                
                // Font Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.localized(.font))
                        .font(.caption)
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                    
                    Picker("", selection: bindingForFontName(layer)) {
                        ForEach(availableFonts, id: \.self) { fontName in
                            Text(fontName)
                                .font(.custom(fontName, size: 14))
                                .tag(fontName)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack {
                    Text(localization.localized(.fontSize))
                        .font(.caption)
                    Spacer()
                    Text("\(Int(layer.fontSize)) pt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: bindingForFontSize(layer), in: 12...72, step: 1)
                
                HStack(spacing: 12) {
                    Toggle(isOn: bindingForBold(layer)) {
                        Image(systemName: "bold")
                    }
                    .toggleStyle(.button)
                    
                    Toggle(isOn: bindingForItalic(layer)) {
                        Image(systemName: "italic")
                    }
                    .toggleStyle(.button)
                    
                    ColorPicker("", selection: bindingForTextColor(layer))
                        .labelsHidden()
                }
            }
            
            Divider()
            
            // Alignment
            VStack(alignment: .leading, spacing: 8) {
                Text(localization.localized(.alignment))
                    .font(.subheadline.bold())
                
                Picker("", selection: bindingForAlignment(layer)) {
                    ForEach(TextLayer.TextAlignment.allCases, id: \.self) { align in
                        Text(align.displayName(localization: localization)).tag(align)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Divider()
            
            Button(localization.localized(.editText)) {
                editorState.startTextEditing(layer.id)
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(themeManager.theme.backgroundColor.opacity(0.5))
        .cornerRadius(themeManager.theme.cornerRadius)
    }
    
    // MARK: - Helpers
    
    private var selectedPhotoLayer: PhotoLayer? {
        guard let id = editorState.selectedLayerId else { return nil }
        if let layer = editorState.leftPage.layers.first(where: { $0.id == id })?.layer as? PhotoLayer {
            return layer
        }
        if let layer = editorState.rightPage.layers.first(where: { $0.id == id })?.layer as? PhotoLayer {
            return layer
        }
        return nil
    }
    
    private var selectedTextLayer: TextLayer? {
        guard let id = editorState.selectedLayerId else { return nil }
        if let layer = editorState.leftPage.layers.first(where: { $0.id == id })?.layer as? TextLayer {
            return layer
        }
        if let layer = editorState.rightPage.layers.first(where: { $0.id == id })?.layer as? TextLayer {
            return layer
        }
        return nil
    }
    
    // MARK: - Text Bindings
    
    private func bindingForTextContent(_ layer: TextLayer) -> Binding<String> {
        Binding(
            get: { layer.text },
            set: { editorState.updateTextContent(id: layer.id, text: $0) }
        )
    }
    
    private func bindingForFontSize(_ layer: TextLayer) -> Binding<Double> {
        Binding(
            get: { layer.fontSize },
            set: { editorState.updateTextStyle(id: layer.id, fontSize: $0) }
        )
    }
    
    private func bindingForTextColor(_ layer: TextLayer) -> Binding<Color> {
        Binding(
            get: { Color(hex: layer.colorHex) },
            set: { editorState.updateTextStyle(id: layer.id, colorHex: $0.toHex()) }
        )
    }
    
    private func bindingForBold(_ layer: TextLayer) -> Binding<Bool> {
        Binding(
            get: { layer.isBold },
            set: { editorState.updateTextStyle(id: layer.id, isBold: $0) }
        )
    }
    
    private func bindingForItalic(_ layer: TextLayer) -> Binding<Bool> {
        Binding(
            get: { layer.isItalic },
            set: { editorState.updateTextStyle(id: layer.id, isItalic: $0) }
        )
    }
    
    private func bindingForAlignment(_ layer: TextLayer) -> Binding<TextLayer.TextAlignment> {
        Binding(
            get: { layer.alignment },
            set: { editorState.updateTextStyle(id: layer.id, alignment: $0) }
        )
    }
    
    private func bindingForFontName(_ layer: TextLayer) -> Binding<String> {
        Binding(
            get: { layer.fontName },
            set: { editorState.updateTextStyle(id: layer.id, fontName: $0) }
        )
    }
    
    // Available fonts for text layers
    private var availableFonts: [String] {
        [
            // Chinese Fonts (MacOS System)
            "PingFang SC",
            "PingFang TC",
            "Songti SC",
            "Kaiti SC",
            "Heiti SC",
            "STXingkai",     // 华文行楷
            "STYuanti",      // 华文圆体
            "Wawa SC",       // 娃娃体
            "Hannotate SC",  // 手札体 (可爱风格)
            "HanziPen SC",   // 翩翩体 (可爱风格)
            "Libian SC",     // 隶变
            
            // English Fonts
            "Helvetica Neue",
            "Arial",
            "Times New Roman",
            "Georgia",
            "Courier New",
            "Menlo",
            "SF Pro Display",
            "Avenir Next",
            "Palatino",
            "Futura",
            "Didot",
            "Optima",
            "Gill Sans",
            "Baskerville",
            "Cochin"
        ]
    }
    
    private func bindingForBorderWidth(_ layer: PhotoLayer) -> Binding<Double> {
        Binding(
            get: { layer.borderWidth },
            set: { editorState.updateLayerBorder(id: layer.id, borderWidth: $0) }
        )
    }
    
    private func bindingForBorderColor(_ layer: PhotoLayer) -> Binding<Color> {
        Binding(
            get: { Color(hex: layer.borderColorHex) },
            set: { editorState.updateLayerBorder(id: layer.id, borderColorHex: $0.toHex()) }
        )
    }
    
    private func bindingForBorderCornerRadius(_ layer: PhotoLayer) -> Binding<Double> {
        Binding(
            get: { layer.borderCornerRadius },
            set: { editorState.updateLayerBorder(id: layer.id, borderCornerRadius: $0) }
        )
    }
    
    private func bindingForFeathering(_ layer: PhotoLayer) -> Binding<Double> {
        Binding(
            get: { layer.feathering },
            set: { editorState.updateLayerFeathering(id: layer.id, feathering: $0) }
        )
    }
    
    private func bindingForShadowRadius(_ layer: PhotoLayer) -> Binding<Double> {
        Binding(
            get: { layer.shadowRadius },
            set: { editorState.updateLayerShadow(id: layer.id, shadowRadius: $0, shadowOpacity: layer.shadowOpacity) }
        )
    }
    
    private func bindingForShadowOpacity(_ layer: PhotoLayer) -> Binding<Double> {
        Binding(
            get: { layer.shadowOpacity },
            set: { editorState.updateLayerShadow(id: layer.id, shadowRadius: layer.shadowRadius, shadowOpacity: $0) }
        )
    }
    
    private func dimensionField(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label + " (mm)")
                .font(.caption2)
                .foregroundColor(themeManager.theme.secondaryTextColor)
            TextField("", value: value, format: .number)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Sticker Quick Button

struct StickerQuickButton: View {
    let sticker: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(sticker)
                .font(.system(size: 24))
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isHovered ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Border Style Button

struct BorderStyleButton: View {
    let style: PhotoLayer.BorderStyle
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Preview of the border style
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 40, height: 30)
                    
                    // Draw the border style preview
                    // Draw the border style preview
                    if style == .double {
                        // Double border
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(color, lineWidth: 2)
                            .frame(width: 34, height: 24)
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(color, lineWidth: 1)
                            .frame(width: 28, height: 18)
                    } else if style == .stamp {
                        // Stamp Border Preview (Simulated with dots)
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [0.1, 6]))
                            .frame(width: 34, height: 24)
                    } else {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(
                                color,
                                style: StrokeStyle(
                                    lineWidth: 2,
                                    dash: style.dashPattern
                                )
                            )
                            .frame(width: 34, height: 24)
                    }
                }
                
                Text(style.rawValue)
                    .font(.system(size: 9))
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Extensions for Hex (toHex only, init is in AppTheme.swift)

extension Color {
    func toHex() -> String {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return "#FFFFFF"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
