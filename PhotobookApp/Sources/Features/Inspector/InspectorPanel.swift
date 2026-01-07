import SwiftUI

struct InspectorPanel: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(BookContext.self) private var bookContext
    @Environment(EditorState.self) private var editorState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section: Book Settings
                bookSettingsSection
                
                // Section: Selected Layer (if any)
                if let selectedLayer = selectedPhotoLayer {
                    layerSettingsSection(for: selectedLayer)
                }
            }
            .padding()
        }
        .animation(.easeInOut, value: bookContext.pageSize)
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
    
    // MARK: - Layer Settings Section
    
    private func layerSettingsSection(for layer: PhotoLayer) -> some View {
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
