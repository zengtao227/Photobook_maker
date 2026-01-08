import Foundation
import SwiftUI
import Observation

/// 管理自定义贴纸的服务
@Observable
public class StickerManager {
    public var customStickers: [CustomSticker] = []
    
    private let fileManager = FileManager.default
    private var customStickersDirectory: URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("PhotobookPro")
            .appendingPathComponent("Stickers")
    }
    
    public init() {
        createStickersDirectoryIfNeeded()
        loadCustomStickers()
    }
    
    /// 创建自定义贴纸文件夹（如果不存在）
    private func createStickersDirectoryIfNeeded() {
        guard let directory = customStickersDirectory else { return }
        
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                print("✅ Created custom stickers directory: \(directory.path)")
                
                // 创建一个README文件说明如何使用
                let readmeURL = directory.appendingPathComponent("README.txt")
                let readmeText = """
                Custom Stickers Folder
                ======================
                
                Place your custom sticker images in this folder.
                
                Supported formats:
                - PNG (recommended, supports transparency)
                - JPEG/JPG
                - SVG (vector graphics)
                
                Tips:
                - Use transparent PNG for best results
                - Recommended size: 512x512 pixels or larger
                - Files will appear in the "Custom" category in the sticker picker
                
                将您的自定义贴纸图片放在此文件夹中。
                
                支持的格式：
                - PNG（推荐，支持透明度）
                - JPEG/JPG
                - SVG（矢量图形）
                
                提示：
                - 使用透明PNG效果最佳
                - 推荐尺寸：512x512像素或更大
                - 文件将显示在贴纸选择器的"自定义"类别中
                """
                
                try? readmeText.write(to: readmeURL, atomically: true, encoding: .utf8)
            } catch {
                print("❌ Failed to create stickers directory: \(error)")
            }
        }
    }
    
    /// 加载自定义贴纸
    public func loadCustomStickers() {
        guard let directory = customStickersDirectory else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            
            customStickers = files.compactMap { url in
                // 只加载图片文件
                let ext = url.pathExtension.lowercased()
                guard ["png", "jpg", "jpeg", "svg"].contains(ext) else { return nil }
                
                return CustomSticker(
                    id: url.lastPathComponent,
                    name: url.deletingPathExtension().lastPathComponent,
                    url: url
                )
            }
            .sorted { $0.name < $1.name }
            
            print("✅ Loaded \(customStickers.count) custom stickers")
        } catch {
            print("❌ Failed to load custom stickers: \(error)")
        }
    }
    
    /// 打开自定义贴纸文件夹
    public func openStickersFolder() {
        guard let directory = customStickersDirectory else { return }
        NSWorkspace.shared.open(directory)
    }
    
    /// 添加自定义贴纸到画布
    public func addCustomStickerToCanvas(
        sticker: CustomSticker,
        editorState: EditorState,
        isLeftPage: Bool,
        center: CGPoint,
        scale: CGFloat
    ) {
        // 转换为逻辑坐标
        let logicalCenter = CGPoint(
            x: center.x / scale,
            y: center.y / scale
        )
        
        // 创建StickerLayer
        let layer = StickerLayer(
            content: .url(sticker.url),
            frame: CGRect(
                x: logicalCenter.x - 50,
                y: logicalCenter.y - 50,
                width: 100,
                height: 100
            )
        )
        
        // 添加到页面
        if isLeftPage {
            editorState.leftPage.layers.append(AnyLayer(layer: layer))
        } else {
            editorState.rightPage.layers.append(AnyLayer(layer: layer))
        }
        
        editorState.lastModified = Date()
        editorState.updateCounter += 1
    }
}

/// 自定义贴纸模型
public struct CustomSticker: Identifiable {
    public let id: String
    public let name: String
    public let url: URL
}
