import SwiftUI

struct InspectorPanel: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(BookContext.self) private var bookContext
    @Environment(EditorState.self) private var editorState
    
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
            Text("工具")
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            
            // Add Text Row
            HStack(spacing: 12) {
                Button {
                    editorState.addTextLayer(isLeftPage: true)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "textformat")
                            .font(.title2)
                        Text("左页文字")
                            .font(.caption)
                    }
                    .frame(width: 70, height: 60)
                }
                .buttonStyle(.bordered)
                .help("在左页添加文字")
                
                Button {
                    editorState.addTextLayer(isLeftPage: false)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "textformat")
                            .font(.title2)
                        Text("右页文字")
                            .font(.caption)
                    }
                    .frame(width: 70, height: 60)
                }
                .buttonStyle(.bordered)
                .help("在右页添加文字")
            }
            
            Divider()
            
            // Stickers Section - Inline display with expandable picker
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("贴纸")
                        .font(.subheadline.bold())
                        .foregroundColor(themeManager.theme.textColor)
                    Spacer()
                    Button {
                        showStickerPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("更多")
                            Image(systemName: "chevron.right")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(themeManager.theme.accentColor)
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
                    Text("添加到:")
                        .font(.caption)
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                    
                    Picker("", selection: $stickerTargetIsLeft) {
                        Text("左页").tag(true)
                        Text("右页").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }
        }
        .padding()
        .background(themeManager.theme.backgroundColor.opacity(0.5))
        .cornerRadius(themeManager.theme.cornerRadius)
        .sheet(isPresented: $showStickerPicker) {
            StickerPickerView(isLeftPage: stickerTargetIsLeft)
        }
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
            Text("画册设置")
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            
            // Preset Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("尺寸预设")
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
                    dimensionField("宽度", value: Bindable(bookContext).customWidth)
                    dimensionField("高度", value: Bindable(bookContext).customHeight)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                // Read-only display
                HStack {
                    Text("尺寸:")
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                    Spacer()
                    Text(bookContext.dimensionString)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(themeManager.theme.textColor)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(themeManager.theme.backgroundColor.opacity(0.5))
        .cornerRadius(themeManager.theme.cornerRadius)
    }
    
    // MARK: - Photo Layer Settings Section
    
    private func photoLayerSettingsSection(for layer: PhotoLayer) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("图层设置")
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            
            // Border Settings
            VStack(alignment: .leading, spacing: 8) {
                Text("边框")
                    .font(.subheadline.bold())
                    .foregroundColor(themeManager.theme.textColor)
                
                // Border Style Picker - Visual preview
                VStack(alignment: .leading, spacing: 4) {
                    Text("样式")
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
                    Text("宽度")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.0f px", layer.borderWidth))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: bindingForBorderWidth(layer), in: 0...20)
                
                // Corner Radius
                HStack {
                    Text("圆角")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.0f px", layer.borderCornerRadius))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: bindingForBorderCornerRadius(layer), in: 0...50)
                
                // Border Color
                HStack {
                    Text("颜色")
                        .font(.caption)
                    Spacer()
                    ColorPicker("", selection: bindingForBorderColor(layer))
                        .labelsHidden()
                }
            }
            
            Divider()
            
            // Feathering Settings
            VStack(alignment: .leading, spacing: 8) {
                Text("边缘羽化")
                    .font(.subheadline.bold())
                    .foregroundColor(themeManager.theme.textColor)
                
                HStack {
                    Text("羽化程度")
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
                Text("阴影")
                    .font(.subheadline.bold())
                    .foregroundColor(themeManager.theme.textColor)
                
                // Shadow Radius
                HStack {
                    Text("模糊半径")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.0f", layer.shadowRadius))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: bindingForShadowRadius(layer), in: 0...30)
                
                // Shadow Opacity
                HStack {
                    Text("透明度")
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
                Button("滤镜") {
                    editorState.startFiltering(layer.id)
                }
                .buttonStyle(.bordered)
                
                Button("裁剪") {
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
            Text("文字设置")
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text("内容")
                    .font(.caption)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
                TextField("文字内容", text: bindingForTextContent(layer))
                    .textFieldStyle(.roundedBorder)
            }
            
            Divider()
            
            // Font Style
            VStack(alignment: .leading, spacing: 8) {
                Text("样式")
                    .font(.subheadline.bold())
                
                // Font Picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("字体")
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
                    Text("字号")
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
                Text("对齐")
                    .font(.subheadline.bold())
                
                Picker("", selection: bindingForAlignment(layer)) {
                    ForEach(TextLayer.TextAlignment.allCases, id: \.self) { align in
                        Text(align.rawValue).tag(align)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Divider()
            
            Button("编辑文字") {
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
            get: { Color(hex: layer.colorHex) ?? .black },
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
