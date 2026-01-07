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
            
            HStack(spacing: 12) {
                // Add Text Button
                Button {
                    editorState.addTextLayer(isLeftPage: true)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "textformat")
                            .font(.title2)
                        Text("添加文字")
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
            
            HStack(spacing: 12) {
                // Import Sticker Button (Left)
                Button {
                    stickerTargetIsLeft = true
                    showStickerPicker = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "star")
                            .font(.title2)
                        Text("左页贴纸")
                            .font(.caption)
                    }
                    .frame(width: 70, height: 60)
                }
                .buttonStyle(.bordered)
                .help("添加贴纸到左页")
                
                // Import Sticker Button (Right)
                Button {
                    stickerTargetIsLeft = false
                    showStickerPicker = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "star")
                            .font(.title2)
                        Text("右页贴纸")
                            .font(.caption)
                    }
                    .frame(width: 70, height: 60)
                }
                .buttonStyle(.bordered)
                .help("添加贴纸到右页")
            }
        }
                .buttonStyle(.bordered)
                .help("导入图片作为贴纸到右页")
            }
        }
        .padding()
        .background(themeManager.theme.backgroundColor.opacity(0.5))
        .cornerRadius(themeManager.theme.cornerRadius)
        .sheet(isPresented: $showStickerPicker) {
            StickerPickerView(isLeftPage: stickerTargetIsLeft)
        }
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
    
    private func bindingForBorderWidth(_ layer: PhotoLayer) -> Binding<Double> {
        Binding(
            get: { layer.borderWidth },
            set: { editorState.updateLayerBorder(id: layer.id, borderWidth: $0, borderColorHex: layer.borderColorHex) }
        )
    }
    
    private func bindingForBorderColor(_ layer: PhotoLayer) -> Binding<Color> {
        Binding(
            get: { Color(hex: layer.borderColorHex) ?? .white },
            set: { editorState.updateLayerBorder(id: layer.id, borderWidth: layer.borderWidth, borderColorHex: $0.toHex()) }
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
