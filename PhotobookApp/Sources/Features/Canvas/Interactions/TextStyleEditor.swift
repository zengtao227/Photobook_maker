//
//  TextEditor.swift
//  PhotobookApp
//
//  文字编辑器 - 提供文字输入和样式调整
//

import SwiftUI

struct TextStyleEditor: View {
    let layer: TextLayer
    let onSave: (String, Double, String, String, Bool, Bool, TextLayer.TextAlignment) -> Void
    let onCancel: () -> Void
    
    @State private var text: String
    @State private var fontSize: Double
    @State private var fontName: String
    @State private var colorHex: String
    @State private var isBold: Bool
    @State private var isItalic: Bool
    @State private var alignment: TextLayer.TextAlignment
    
    // Available fonts (Dynamically loaded)
    @State private var availableFonts: [String] = []
    
    // Core Logic to fetch fonts
    private func loadFonts() {
        let manager = NSFontManager.shared
        let systemFonts = manager.availableFonts
        
        // Priority fonts (Chinese/Japanese/Common)
        let priorityFonts = [
            "PingFang SC", "PingFang TC", "PingFang HK",
            "Heiti SC", "Heiti TC",
            "Songti SC", "Songti TC",
            "Kaiti SC", "Kaiti TC",
            "Hiragino Sans", "Hiragino Sans GB",
            "Helvetica Neue", "Arial", "Times New Roman"
        ]
        
        var sortedFonts = priorityFonts.filter { systemFonts.contains($0) }
        let otherFonts = systemFonts.filter { !priorityFonts.contains($0) }.sorted()
        sortedFonts.append(contentsOf: otherFonts)
        
        self.availableFonts = sortedFonts
    }
    
    init(layer: TextLayer, 
         onSave: @escaping (String, Double, String, String, Bool, Bool, TextLayer.TextAlignment) -> Void,
         onCancel: @escaping () -> Void) {
        self.layer = layer
        self.onSave = onSave
        self.onCancel = onCancel
        self._text = State(initialValue: layer.text)
        self._fontSize = State(initialValue: layer.fontSize)
        self._fontName = State(initialValue: layer.fontName)
        self._colorHex = State(initialValue: layer.colorHex)
        self._isBold = State(initialValue: layer.isBold)
        self._isItalic = State(initialValue: layer.isItalic)
        self._alignment = State(initialValue: layer.alignment)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("编辑文字")
                    .font(.headline)
                Spacer()
                Button("取消") { onCancel() }
                Button("完成") {
                    onSave(text, fontSize, fontName, colorHex, isBold, isItalic, alignment)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            HStack(spacing: 0) {
                // Left: Preview
                VStack {
                    Spacer()
                    Text(text.isEmpty ? "预览文字" : text)
                        .font(.custom(fontName, size: fontSize))
                        .fontWeight(isBold ? .bold : .regular)
                        .italic(isItalic)
                        .foregroundColor(Color(hex: colorHex))
                        .multilineTextAlignment(swiftUIAlignment)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    Spacer()
                }
                .frame(minWidth: 300)
                .background(Color.gray.opacity(0.2))
                
                Divider()
                
                // Right: Controls
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Text Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("文字内容")
                                .font(.subheadline.bold())
                            TextEditor(text: $text)
                                .frame(height: 80)
                                .padding(4)
                                .background(Color(nsColor: .textBackgroundColor))
                                .cornerRadius(6)
                        }
                        
                        Divider()
                        
                        // Font Settings
                        VStack(alignment: .leading, spacing: 8) {
                            Text("字体")
                                .font(.subheadline.bold())
                            
                            // Font Picker
                            Picker("字体", selection: $fontName) {
                                ForEach(availableFonts, id: \.self) { font in
                                    Text(font).font(.custom(font, size: 14)).tag(font)
                                }
                            }
                            .labelsHidden()
                            
                            // Font Size
                            HStack {
                                Text("字号")
                                Spacer()
                                Text("\(Int(fontSize)) pt")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $fontSize, in: 12...72, step: 1)
                            
                            // Style toggles
                            HStack(spacing: 12) {
                                Toggle(isOn: $isBold) {
                                    Image(systemName: "bold")
                                }
                                .toggleStyle(.button)
                                
                                Toggle(isOn: $isItalic) {
                                    Image(systemName: "italic")
                                }
                                .toggleStyle(.button)
                            }
                        }
                        
                        Divider()
                        
                        // Color
                        VStack(alignment: .leading, spacing: 8) {
                            Text("颜色")
                                .font(.subheadline.bold())
                            ColorPicker("文字颜色", selection: bindingForColor())
                        }
                        
                        Divider()
                        
                        // Alignment
                        VStack(alignment: .leading, spacing: 8) {
                            Text("对齐")
                                .font(.subheadline.bold())
                            Picker("", selection: $alignment) {
                                ForEach(TextLayer.TextAlignment.allCases, id: \.self) { align in
                                    Text(align.rawValue).tag(align)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding()
                }
                .frame(width: 280)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            loadFonts()
        }
    }
    
    private var swiftUIAlignment: SwiftUI.TextAlignment {
        switch alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
    
    private func bindingForColor() -> Binding<Color> {
        Binding(
            get: { Color(hex: colorHex) },
            set: { colorHex = $0.toHex() }
        )
    }
}

// MARK: - Inline Text Editor (for double-click editing)

struct InlineTextEditor: View {
    let layer: TextLayer
    let onCommit: (String) -> Void
    let onCancel: () -> Void
    
    @State private var editedText: String
    @FocusState private var isFocused: Bool
    
    init(layer: TextLayer, onCommit: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.layer = layer
        self.onCommit = onCommit
        self.onCancel = onCancel
        self._editedText = State(initialValue: layer.text)
    }
    
    var body: some View {
        TextField("输入文字", text: $editedText, axis: .vertical)
            .font(.custom(layer.fontName, size: layer.fontSize))
            .fontWeight(layer.isBold ? .bold : .regular)
            .italic(layer.isItalic)
            .foregroundColor(Color(hex: layer.colorHex))
            .textFieldStyle(.plain)
            .focused($isFocused)
            .onSubmit {
                onCommit(editedText)
            }
            .onExitCommand {
                onCancel()
            }
            .onAppear {
                isFocused = true
            }
    }
}
