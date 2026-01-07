//
//  FilterEditor.swift
//  PhotobookApp
//
//  滤镜编辑器 - 提供预设滤镜和参数调整
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

//
//  FilterEditor.swift
//  PhotobookApp
//
//  滤镜编辑器 - 提供预设滤镜和参数调整
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct FilterEditor: View {
    let layer: PhotoLayer
    let onSave: (PhotoLayer.FilterType, Double, Double, Double, Double, Double, Double) -> Void
    let onCancel: () -> Void
    
    @State private var selectedFilter: PhotoLayer.FilterType
    @State private var brightness: Double
    @State private var contrast: Double
    @State private var saturation: Double
    
    // Advanced params
    @State private var vignetteIntensity: Double
    @State private var sharpenIntensity: Double
    @State private var temperature: Double
    
    @State private var previewImage: NSImage?
    
    init(layer: PhotoLayer, 
         onSave: @escaping (PhotoLayer.FilterType, Double, Double, Double, Double, Double, Double) -> Void, 
         onCancel: @escaping () -> Void) {
        self.layer = layer
        self.onSave = onSave
        self.onCancel = onCancel
        self._selectedFilter = State(initialValue: layer.filterType)
        self._brightness = State(initialValue: layer.brightness)
        self._contrast = State(initialValue: layer.contrast)
        self._saturation = State(initialValue: layer.saturation)
        self._vignetteIntensity = State(initialValue: layer.vignetteIntensity)
        self._sharpenIntensity = State(initialValue: layer.sharpenIntensity)
        self._temperature = State(initialValue: layer.temperature)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("滤镜与调整")
                    .font(.headline)
                Spacer()
                Button("取消") { onCancel() }
                Button("应用") {
                    onSave(selectedFilter, brightness, contrast, saturation, vignetteIntensity, sharpenIntensity, temperature)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            HStack(spacing: 0) {
                // Left: Preview
                VStack {
                    if let image = previewImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 5)
                            .padding()
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(minWidth: 400)
                .background(Color.black.opacity(0.8))
                
                Divider()
                
                // Right: Controls
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Filter Presets
                        VStack(alignment: .leading, spacing: 8) {
                            Text("预设滤镜")
                                .font(.subheadline.bold())
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 8) {
                                ForEach(PhotoLayer.FilterType.allCases, id: \.self) { filter in
                                    FilterPresetButton(
                                        filter: filter,
                                        isSelected: selectedFilter == filter
                                    ) {
                                        selectedFilter = filter
                                        updatePreview()
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Basic Adjustments
                        VStack(alignment: .leading, spacing: 16) {
                            Text("基础调整")
                                .font(.subheadline.bold())
                            
                            // Brightness
                            SliderControl(label: "亮度", value: $brightness, range: -1...1, format: "%.0f%%", multiplier: 100) { updatePreview() }
                            
                            // Contrast
                            SliderControl(label: "对比度", value: $contrast, range: 0.5...2, format: "%.0f%%", multiplier: 100) { updatePreview() }
                            
                            // Saturation
                            SliderControl(label: "饱和度", value: $saturation, range: 0...2, format: "%.0f%%", multiplier: 100) { updatePreview() }
                        }
                        
                        Divider()
                        
                        // Advanced Adjustments
                        VStack(alignment: .leading, spacing: 16) {
                            Text("高级调整")
                                .font(.subheadline.bold())
                            
                            // Vignette
                            SliderControl(label: "暗角", value: $vignetteIntensity, range: 0...2, format: "%.1f") { updatePreview() }
                            
                            // Sharpen
                            SliderControl(label: "锐化", value: $sharpenIntensity, range: 0...2, format: "%.1f") { updatePreview() }
                            
                            // Temperature
                            SliderControl(label: "色温", value: $temperature, range: 3000...9000, format: "%.0f K") { updatePreview() }
                        }
                        
                        Divider()
                        
                        // Reset Button
                        Button("重置所有调整") {
                            brightness = 0
                            contrast = 1
                            saturation = 1
                            vignetteIntensity = 0
                            sharpenIntensity = 0
                            temperature = 6500
                            updatePreview()
                        }
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
                .frame(width: 260)
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onAppear {
            updatePreview()
        }
    }
    
    private func updatePreview() {
        Task {
            previewImage = await generateFilteredImage(
                from: layer.photoUrl,
                filter: selectedFilter,
                brightness: brightness,
                contrast: contrast,
                saturation: saturation,
                vignette: vignetteIntensity,
                sharpen: sharpenIntensity,
                temperature: temperature
            )
        }
    }
}

// Helper View for Sliders
struct SliderControl: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String
    var multiplier: Double = 1.0
    let onCommit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: format, value * multiplier))
                    .foregroundColor(.secondary)
            }
            Slider(value: $value, in: range) { _ in
                onCommit()
            }
        }
    }
}

struct FilterPresetButton: View {
    let filter: PhotoLayer.FilterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorForFilter(filter))
                    .frame(width: 50, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                Text(filter.rawValue)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func colorForFilter(_ filter: PhotoLayer.FilterType) -> Color {
        switch filter {
        case .none: return Color.gray.opacity(0.3)
        case .blackAndWhite: return Color.gray
        case .sepia: return Color.brown.opacity(0.6)
        case .chrome: return Color.yellow.opacity(0.4)
        case .fade: return Color.white.opacity(0.5)
        case .instant: return Color.orange.opacity(0.3)
        case .noir: return Color.black.opacity(0.7)
        case .process: return Color.cyan.opacity(0.3)
        case .tonal: return Color.gray.opacity(0.5)
        case .transfer: return Color.pink.opacity(0.3)
        }
    }
}

// MARK: - Core Image Filter Processing

func generateFilteredImage(
    from url: URL,
    filter: PhotoLayer.FilterType,
    brightness: Double,
    contrast: Double,
    saturation: Double,
    vignette: Double = 0,
    sharpen: Double = 0,
    temperature: Double = 6500
) async -> NSImage? {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            guard let ciImage = CIImage(contentsOf: url) else {
                continuation.resume(returning: nil)
                return
            }
            
            var outputImage = ciImage
            
            // 1. Preset filter
            if filter != .none {
                if let filteredImage = applyPresetFilter(to: outputImage, filter: filter) {
                    outputImage = filteredImage
                }
            }
            
            // 2. Basic Adjustments (Color Controls)
            if brightness != 0 || contrast != 1 || saturation != 1 {
                let colorControls = CIFilter.colorControls()
                colorControls.inputImage = outputImage
                colorControls.brightness = Float(brightness)
                colorControls.contrast = Float(contrast)
                colorControls.saturation = Float(saturation)
                
                if let adjusted = colorControls.outputImage {
                    outputImage = adjusted
                }
            }
            
            // 3. Advanced: Temperature
            if temperature != 6500 {
                let tempFilter = CIFilter.temperatureAndTint()
                tempFilter.inputImage = outputImage
                tempFilter.neutral = CIVector(x: CGFloat(temperature), y: 0)
                tempFilter.targetNeutral = CIVector(x: 6500, y: 0) // Standard white point
                
                if let adjusted = tempFilter.outputImage {
                    outputImage = adjusted
                }
            }
            
            // 4. Advanced: Sharpen
            if sharpen > 0 {
                let sharpenFilter = CIFilter.sharpenLuminance()
                sharpenFilter.inputImage = outputImage
                sharpenFilter.sharpness = Float(sharpen)
                
                if let adjusted = sharpenFilter.outputImage {
                    outputImage = adjusted
                }
            }
            
            // 5. Advanced: Vignette
            if vignette > 0 {
                let vignetteFilter = CIFilter.vignette()
                vignetteFilter.inputImage = outputImage
                vignetteFilter.intensity = Float(vignette)
                vignetteFilter.radius = Float(1.0)
                
                if let adjusted = vignetteFilter.outputImage {
                    outputImage = adjusted
                }
            }
            
            // Convert to NSImage
            let context = CIContext()
            guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                continuation.resume(returning: nil)
                return
            }
            
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            continuation.resume(returning: nsImage)
        }
    }
}

private func applyPresetFilter(to image: CIImage, filter: PhotoLayer.FilterType) -> CIImage? {
    let filterName: String?
    
    switch filter {
    case .none:
        return image
    case .blackAndWhite:
        let noir = CIFilter.photoEffectMono()
        noir.inputImage = image
        return noir.outputImage
    case .sepia:
        let sepia = CIFilter.sepiaTone()
        sepia.inputImage = image
        sepia.intensity = 0.8
        return sepia.outputImage
    case .chrome:
        filterName = "CIPhotoEffectChrome"
    case .fade:
        filterName = "CIPhotoEffectFade"
    case .instant:
        filterName = "CIPhotoEffectInstant"
    case .noir:
        filterName = "CIPhotoEffectNoir"
    case .process:
        filterName = "CIPhotoEffectProcess"
    case .tonal:
        filterName = "CIPhotoEffectTonal"
    case .transfer:
        filterName = "CIPhotoEffectTransfer"
    }
    
    guard let name = filterName, let ciFilter = CIFilter(name: name) else {
        return image
    }
    
    ciFilter.setValue(image, forKey: kCIInputImageKey)
    return ciFilter.outputImage
}

// Apply filter to layer for display
func applyFiltersToImage(_ nsImage: NSImage, layer: PhotoLayer) -> NSImage {
    guard layer.filterType != .none || layer.brightness != 0 || layer.contrast != 1 || layer.saturation != 1 else {
        return nsImage
    }
    
    guard let tiffData = nsImage.tiffRepresentation,
          let ciImage = CIImage(data: tiffData) else {
        return nsImage
    }
    
    var outputImage = ciImage
    
    // Apply preset filter
    if layer.filterType != .none {
        if let filtered = applyPresetFilter(to: outputImage, filter: layer.filterType) {
            outputImage = filtered
        }
    }
    
    // Apply adjustments
    if layer.brightness != 0 || layer.contrast != 1 || layer.saturation != 1 {
        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = outputImage
        colorControls.brightness = Float(layer.brightness)
        colorControls.contrast = Float(layer.contrast)
        colorControls.saturation = Float(layer.saturation)
        
        if let adjusted = colorControls.outputImage {
            outputImage = adjusted
        }
    }
    
    // Convert back to NSImage
    let context = CIContext()
    guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
        return nsImage
    }
    
    return NSImage(cgImage: cgImage, size: nsImage.size)
}
