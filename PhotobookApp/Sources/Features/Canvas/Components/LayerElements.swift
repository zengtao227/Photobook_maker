import SwiftUI
import AppKit

// MARK: - Text Layer Element

struct TextLayerElement: View {
    let layer: TextLayer
    
    private var swiftUIAlignment: SwiftUI.TextAlignment {
        switch layer.alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
    
    var body: some View {
        Text(layer.text)
            .font(.custom(layer.fontName, size: layer.fontSize))
            .fontWeight(layer.isBold ? .bold : .regular)
            .italic(layer.isItalic)
            .foregroundColor(Color(hex: layer.colorHex))
            .multilineTextAlignment(swiftUIAlignment)
            .frame(width: layer.frame.width, height: layer.frame.height, alignment: alignmentForFrame)
            .background(
                layer.backgroundColorHex != nil 
                    ? Color(hex: layer.backgroundColorHex!) 
                    : Color.clear
            )
            .contentShape(Rectangle())
    }
    
    private var alignmentForFrame: Alignment {
        switch layer.alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

// MARK: - Photo Layer Element

struct PhotoLayerElement: View {
    let layer: PhotoLayer
    
    @State private var filteredImage: NSImage?
    @State private var originalImageSize: CGSize = .zero
    
    /// 检查是否进行了裁切（不是完整图片）
    private var isCropped: Bool {
        guard let normRect = layer.normalizedCropRect else { return false }
        // 如果裁切区域不是完整图片（0,0,1,1），则认为进行了裁切
        let isFullImage = normRect.origin.x < 0.01 && 
                          normRect.origin.y < 0.01 && 
                          normRect.width > 0.99 && 
                          normRect.height > 0.99
        return !isFullImage
    }
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let filtered = filteredImage {
                    croppedImageView(nsImage: filtered, frameSize: geometry.size)
                } else {
                    AsyncImage(url: layer.photoUrl) { phase in
                        if let image = phase.image {
                            // 获取原始图片尺寸
                            image
                                .resizable()
                                .aspectRatio(contentMode: isCropped ? .fill : .fit)
                                .rotationEffect(.degrees(layer.cropRotation))
                                .scaleEffect(isCropped ? layer.cropScale : 1.0)
                                .offset(isCropped ? layer.cropOffset : .zero)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .mask(maskView)
        .overlay(borderOverlay)
        .shadow(
            color: Color.black.opacity(layer.shadowOpacity),
            radius: layer.shadowRadius,
            x: 0,
            y: layer.shadowRadius / 3
        )
        .opacity(layer.opacity)
        .allowsHitTesting(false)
        .onAppear { loadFilteredImage() }
        .onChange(of: layer.filterType) { _, _ in loadFilteredImage() }
        .onChange(of: layer.brightness) { _, _ in loadFilteredImage() }
        .onChange(of: layer.contrast) { _, _ in loadFilteredImage() }
        .onChange(of: layer.saturation) { _, _ in loadFilteredImage() }
        .onChange(of: layer.vignetteIntensity) { _, _ in loadFilteredImage() }
        .onChange(of: layer.sharpenIntensity) { _, _ in loadFilteredImage() }
        .onChange(of: layer.temperature) { _, _ in loadFilteredImage() }
    }
    
    @ViewBuilder
    private func croppedImageView(nsImage: NSImage, frameSize: CGSize) -> some View {
        Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: isCropped ? .fill : .fit)
            .rotationEffect(.degrees(layer.cropRotation))
            .scaleEffect(isCropped ? layer.cropScale : 1.0)
            .offset(isCropped ? layer.cropOffset : .zero)
            .frame(width: frameSize.width, height: frameSize.height)
            .clipped()
    }
    
    @ViewBuilder
    private var maskView: some View {
        if layer.borderStyle == .stamp {
            StampShape().fill(style: FillStyle(eoFill: true))
        } else if layer.feathering > 0 {
            RoundedRectangle(cornerRadius: layer.borderCornerRadius)
                .padding(layer.feathering / 2)
                .blur(radius: layer.feathering / 2)
        } else {
            RoundedRectangle(cornerRadius: layer.borderCornerRadius)
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        if layer.borderWidth > 0 {
            if layer.borderStyle == .double {
                ZStack {
                    RoundedRectangle(cornerRadius: layer.borderCornerRadius)
                        .stroke(Color(hex: layer.borderColorHex), lineWidth: layer.borderWidth)
                    RoundedRectangle(cornerRadius: max(0, layer.borderCornerRadius - 4))
                        .stroke(Color(hex: layer.borderColorHex), lineWidth: max(1, layer.borderWidth / 3))
                        .padding(4)
                }
            } else if layer.borderStyle == .stamp {
                StampShape()
                    .stroke(Color(hex: layer.borderColorHex), lineWidth: layer.borderWidth)
            } else {
                RoundedRectangle(cornerRadius: layer.borderCornerRadius)
                    .stroke(
                        Color(hex: layer.borderColorHex),
                        style: StrokeStyle(
                            lineWidth: layer.borderWidth,
                            dash: layer.borderStyle.dashPattern
                        )
                    )
            }
        }
    }
    
    private func loadFilteredImage() {
        guard layer.filterType != .none || 
              layer.brightness != 0 || 
              layer.contrast != 1 || 
              layer.saturation != 1 ||
              layer.vignetteIntensity > 0 ||
              layer.sharpenIntensity > 0 ||
              layer.temperature != 6500 else {
            filteredImage = nil
            return
        }
        
        Task {
            filteredImage = await generateFilteredImage(
                from: layer.photoUrl,
                filter: layer.filterType,
                brightness: layer.brightness,
                contrast: layer.contrast,
                saturation: layer.saturation,
                vignette: layer.vignetteIntensity,
                sharpen: layer.sharpenIntensity,
                temperature: layer.temperature
            )
        }
    }
}

// MARK: - Sticker Layer Element

struct StickerLayerElement: View {
    let layer: StickerLayer
    
    var body: some View {
        Group {
            switch layer.content {
            case .url(let url):
                AsyncImage(url: url) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                
            case .systemImage(let name):
                Image(systemName: name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(hex: layer.colorHex ?? "#000000"))
                    
            case .emoji(let char):
                Text(char)
                    .font(.system(size: min(layer.frame.width, layer.frame.height)))
                    .minimumScaleFactor(0.1)
            }
        }
        .frame(width: layer.frame.width, height: layer.frame.height)
        .rotationEffect(.degrees(layer.rotation))
        .contentShape(Rectangle())
        .shadow(
            color: Color.black.opacity(layer.shadowOpacity),
            radius: layer.shadowRadius,
            x: 0,
            y: layer.shadowRadius / 3
        )
    }
}
