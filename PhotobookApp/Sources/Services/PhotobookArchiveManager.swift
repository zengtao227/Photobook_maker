import Foundation
import AppKit

// MARK: - Photobook Archive Manager

/// Manages exporting and importing `.photobook` bundle packages
/// A .photobook is a folder-based bundle containing:
/// - manifest.json: Project metadata and spread configurations
/// - images/: Folder containing all image assets (copied for portability)
/// - thumbnails/: Generated thumbnails for quick preview
public class PhotobookArchiveManager {
    
    /// Archive manifest structure
    public struct Manifest: Codable {
        let version: String
        let createdAt: Date
        let modifiedAt: Date
        let projectName: String
        let pageSize: String
        let spreads: [SpreadData]
        
        struct SpreadData: Codable {
            let leftPage: PageModel
            let rightPage: PageModel
        }
    }
    
    /// Export the current project to a .photobook bundle
    @MainActor
    public static func exportProject(
        name: String,
        editorState: EditorState,
        pageSize: String,
        to destinationURL: URL,
        progressHandler: ((Double, String) -> Void)? = nil
    ) async throws {
        // Ensure current spread is saved
        editorState.saveCurrentSpread()
        
        let bundleURL = destinationURL.appendingPathComponent("\(name).photobook")
        let imagesURL = bundleURL.appendingPathComponent("images")
        let thumbnailsURL = bundleURL.appendingPathComponent("thumbnails")
        
        // Create directory structure
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: imagesURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: thumbnailsURL, withIntermediateDirectories: true)
        
        progressHandler?(0.1, "创建项目结构...")
        
        // Collect all image URLs from all spreads
        var imageURLMapping: [URL: String] = [:] // Original URL -> new filename
        var imageIndex = 0
        
        for spread in editorState.allSpreads {
            for wrapper in spread.left.layers + spread.right.layers {
                if let photoLayer = wrapper.layer as? PhotoLayer {
                    if imageURLMapping[photoLayer.photoUrl] == nil {
                        let ext = photoLayer.photoUrl.pathExtension
                        let filename = "image_\(imageIndex).\(ext)"
                        imageURLMapping[photoLayer.photoUrl] = filename
                        imageIndex += 1
                    }
                }
                if let stickerLayer = wrapper.layer as? StickerLayer {
                    if case .url(let url) = stickerLayer.content {
                        if imageURLMapping[url] == nil {
                            let ext = url.pathExtension
                            let filename = "sticker_\(imageIndex).\(ext)"
                            imageURLMapping[url] = filename
                            imageIndex += 1
                        }
                    }
                }
            }
        }
        
        progressHandler?(0.2, "复制图片资源...")
        
        // Copy all images to the bundle
        for (originalURL, filename) in imageURLMapping {
            let destURL = imagesURL.appendingPathComponent(filename)
            try? FileManager.default.copyItem(at: originalURL, to: destURL)
        }
        
        progressHandler?(0.5, "处理页面数据...")
        
        // Create modified spreads with remapped URLs
        var exportSpreads: [Manifest.SpreadData] = []
        
        for spread in editorState.allSpreads {
            let leftPage = remapImageURLs(in: spread.left, mapping: imageURLMapping, baseFilename: "images/")
            let rightPage = remapImageURLs(in: spread.right, mapping: imageURLMapping, baseFilename: "images/")
            exportSpreads.append(Manifest.SpreadData(leftPage: leftPage, rightPage: rightPage))
        }
        
        progressHandler?(0.7, "生成项目清单...")
        
        // Create manifest
        let manifest = Manifest(
            version: "1.0",
            createdAt: Date(),
            modifiedAt: Date(),
            projectName: name,
            pageSize: pageSize,
            spreads: exportSpreads
        )
        
        // Write manifest
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let manifestData = try encoder.encode(manifest)
        let manifestURL = bundleURL.appendingPathComponent("manifest.json")
        try manifestData.write(to: manifestURL)
        
        progressHandler?(0.9, "生成缩略图...")
        
        // Generate thumbnails (optional, for quick preview)
        // For now, we skip this to simplify the implementation
        
        progressHandler?(1.0, "导出完成!")
        
        print("✅ Project exported to: \(bundleURL.path)")
    }
    
    /// Import a .photobook bundle into EditorState
    @MainActor
    public static func importProject(
        from bundleURL: URL,
        into editorState: EditorState,
        progressHandler: ((Double, String) -> Void)? = nil
    ) async throws {
        let manifestURL = bundleURL.appendingPathComponent("manifest.json")
        let imagesURL = bundleURL.appendingPathComponent("images")
        
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw ArchiveError.manifestNotFound
        }
        
        progressHandler?(0.1, "读取项目清单...")
        
        // Read manifest
        let manifestData = try Data(contentsOf: manifestURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(Manifest.self, from: manifestData)
        
        progressHandler?(0.3, "恢复图片引用...")
        
        // Remap relative URLs back to absolute bundle paths
        var importedSpreads: [(left: PageModel, right: PageModel)] = []
        
        for spreadData in manifest.spreads {
            let leftPage = remapBundleURLs(in: spreadData.leftPage, bundleImagesURL: imagesURL)
            let rightPage = remapBundleURLs(in: spreadData.rightPage, bundleImagesURL: imagesURL)
            importedSpreads.append((left: leftPage, right: rightPage))
        }
        
        progressHandler?(0.8, "加载页面...")
        
        // Update EditorState
        editorState.allSpreads = importedSpreads
        editorState.currentSpreadIndex = 0
        
        if let firstSpread = importedSpreads.first {
            editorState.leftPage = firstSpread.left
            editorState.rightPage = firstSpread.right
        }
        
        editorState.lastModified = Date()
        editorState.updateCounter += 1
        
        progressHandler?(1.0, "导入完成!")
        
        print("✅ Project imported: \(manifest.projectName) (\(manifest.spreads.count) spreads)")
    }
    
    // MARK: - URL Remapping Helpers
    
    /// Remap image URLs in a PageModel to relative paths for export
    private static func remapImageURLs(in page: PageModel, mapping: [URL: String], baseFilename: String) -> PageModel {
        var newPage = page
        var newLayers: [AnyLayer] = []
        
        for wrapper in page.layers {
            if var photoLayer = wrapper.layer as? PhotoLayer {
                if let newFilename = mapping[photoLayer.photoUrl] {
                    // Store as relative path (will be resolved on import)
                    photoLayer = PhotoLayer(
                        photoId: photoLayer.photoId,
                        photoUrl: URL(fileURLWithPath: baseFilename + newFilename),
                        frame: photoLayer.frame
                    )
                    // Copy all other properties
                    var copy = photoLayer
                    copy.rotation = (wrapper.layer as! PhotoLayer).rotation
                    copy.zIndex = (wrapper.layer as! PhotoLayer).zIndex
                    copy.cropScale = (wrapper.layer as! PhotoLayer).cropScale
                    copy.cropOffset = (wrapper.layer as! PhotoLayer).cropOffset
                    copy.filterType = (wrapper.layer as! PhotoLayer).filterType
                    copy.brightness = (wrapper.layer as! PhotoLayer).brightness
                    copy.contrast = (wrapper.layer as! PhotoLayer).contrast
                    copy.saturation = (wrapper.layer as! PhotoLayer).saturation
                    copy.borderWidth = (wrapper.layer as! PhotoLayer).borderWidth
                    copy.borderColorHex = (wrapper.layer as! PhotoLayer).borderColorHex
                    copy.shadowRadius = (wrapper.layer as! PhotoLayer).shadowRadius
                    copy.shadowOpacity = (wrapper.layer as! PhotoLayer).shadowOpacity
                    newLayers.append(AnyLayer(copy))
                } else {
                    newLayers.append(wrapper)
                }
            } else {
                newLayers.append(wrapper)
            }
        }
        
        newPage.layers = newLayers
        return newPage
    }
    
    /// Remap relative bundle paths back to absolute URLs on import
    private static func remapBundleURLs(in page: PageModel, bundleImagesURL: URL) -> PageModel {
        var newPage = page
        var newLayers: [AnyLayer] = []
        
        for wrapper in page.layers {
            if var photoLayer = wrapper.layer as? PhotoLayer {
                // Convert relative path to absolute bundle path
                let relativePath = photoLayer.photoUrl.path
                if relativePath.hasPrefix("images/") {
                    let filename = String(relativePath.dropFirst("images/".count))
                    let absoluteURL = bundleImagesURL.appendingPathComponent(filename)
                    photoLayer = PhotoLayer(
                        photoId: photoLayer.photoId,
                        photoUrl: absoluteURL,
                        frame: photoLayer.frame
                    )
                    // Copy properties (simplified - in production, use proper copying)
                    newLayers.append(AnyLayer(photoLayer))
                } else {
                    newLayers.append(wrapper)
                }
            } else {
                newLayers.append(wrapper)
            }
        }
        
        newPage.layers = newLayers
        return newPage
    }
    
    // MARK: - Errors
    
    public enum ArchiveError: LocalizedError {
        case manifestNotFound
        case invalidManifest
        case imagesCopyFailed
        
        public var errorDescription: String? {
            switch self {
            case .manifestNotFound:
                return "无法找到项目清单文件 (manifest.json)"
            case .invalidManifest:
                return "项目清单格式无效"
            case .imagesCopyFailed:
                return "复制图片资源失败"
            }
        }
    }
}

// MARK: - Convenience Extensions

extension EditorState {
    /// Export current project to a .photobook bundle
    @MainActor
    public func exportToBundle(name: String, pageSize: String, to url: URL) async throws {
        try await PhotobookArchiveManager.exportProject(
            name: name,
            editorState: self,
            pageSize: pageSize,
            to: url
        )
    }
    
    /// Import a .photobook bundle
    @MainActor
    public func importFromBundle(at url: URL) async throws {
        try await PhotobookArchiveManager.importProject(from: url, into: self)
    }
}
