// AutoLayoutEngine.swift
// V2 智能模板推荐与自动布局引擎

import Foundation
import SwiftUI

// MARK: - AutoLayoutEngine

/// 自动布局引擎
/// 根据照片特征智能推荐模板并自动填充布局
@MainActor
class AutoLayoutEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isProcessing = false
    @Published var currentStatus = ""
    
    // MARK: - Dependencies
    
    private let classifier: PhotoClassifier
    
    // MARK: - Initialization
    
    init(classifier: PhotoClassifier) {
        self.classifier = classifier
    }
    
    // MARK: - Public Methods
    
    /// 根据照片特征推荐最佳模板
    /// - Parameters:
    ///   - photos: 分类后的照片数组
    ///   - count: 推荐数量上限
    /// - Returns: 模板推荐结果
    func recommendTemplates(for photos: [ClassifiedPhoto], count: Int = 3) -> [TemplateRecommendation] {
        guard !photos.isEmpty else { return [] }
        
        // 分析照片特征
        let analysis = analyzePhotoSet(photos)
        
        // 获取所有可用模板
        let allTemplates = LayoutTemplate.allTemplates
        
        // 计算每个模板的匹配分数
        var recommendations: [TemplateRecommendation] = []
        
        for template in allTemplates {
            // 基本筛选：照片数量必须匹配（LayoutTemplate 的插槽数是固定的）
            guard template.slots.count == photos.count else { continue }
            
            let score = calculateMatchScore(template: template, analysis: analysis)
            let recommendation = TemplateRecommendation(
                template: template,
                score: score,
                reason: generateRecommendationReason(template: template, analysis: analysis)
            )
            recommendations.append(recommendation)
        }
        
        // 按分数排序并返回前N个
        return recommendations
            .sorted { $0.score > $1.score }
            .prefix(count)
            .map { $0 }
    }
    
    /// 自动填充模板
    /// - Parameters:
    ///   - template: 目标模板
    ///   - photos: 待填充的照片
    /// - Returns: (照片ID, 插槽索引, 裁切区域) 的映射数组
    func autoFillTemplate(_ template: LayoutTemplate, with photos: [ClassifiedPhoto]) -> [(photo: Photo, slotIndex: Int, cropRect: CGRect)] {
        var results: [(photo: Photo, slotIndex: Int, cropRect: CGRect)] = []
        
        // 按质量分数排序照片，高质量照片优先填入主要插槽
        // 这里简单认为面积大的插槽是主要插槽
        let sortedPhotos = photos.sorted { $0.qualityScore > $1.qualityScore }
        
        // 对插槽按面积排序
        let sortedSlots = template.slots.enumerated().sorted {
            ($0.element.rect.width * $0.element.rect.height) > ($1.element.rect.width * $1.element.rect.height)
        }
        
        // 填充
        for (i, slotInfo) in sortedSlots.enumerated() {
            guard i < sortedPhotos.count else { break }
            
            let photo = sortedPhotos[i]
            let slot = slotInfo.element
            let originalIndex = slotInfo.offset
            
            // 计算最佳裁切
            let cropRect = calculateOptimalCrop(photo: photo, slot: slot)
            
            results.append((photo: photo.photo, slotIndex: originalIndex, cropRect: cropRect))
        }
        
        return results
    }
    
    /// 批量生成整书布局建议
    /// - Parameter groups: 智能分组后的照片组
    /// - Returns: 页面布局建议
    /// 
    /// IMPORTANT: Event Isolation Rule
    /// Each PhotoGroup MUST start on a new page spread.
    /// Photos from different groups are NEVER mixed on the same page.
    func generateBookLayout(groups: [PhotoGroup], classifiedPhotos: [ClassifiedPhoto]) -> [PageSuggestion] {
        var suggestions: [PageSuggestion] = []
        var pageCounter = 2
        
        for group in groups {
            // 获取该组的分类照片
            let groupPhotos = classifiedPhotos.filter { cp in
                group.photos.contains(where: { $0.id == cp.photo.id })
            }
            
            guard !groupPhotos.isEmpty else { continue }
            
            // 简单的分页策略：每页最多4张
            let pageSize = 4
            let chunks = stride(from: 0, to: groupPhotos.count, by: pageSize).map {
                Array(groupPhotos[$0..<min($0 + pageSize, groupPhotos.count)])
            }
            
            // Mark the first page of this group for event isolation tracking
            var isFirstPageOfGroup = true
            
            for chunk in chunks {
                guard !chunk.isEmpty else { continue }
                
                // 推荐模板
                let recommendations = recommendTemplates(for: chunk, count: 1)
                
                if let bestTemplate = recommendations.first?.template {
                    var suggestion = PageSuggestion(
                        template: bestTemplate,
                        photos: chunk.map { $0.photo },
                        pageNumber: pageCounter
                    )
                    // Tag first page of group for event isolation
                    suggestion.isGroupStart = isFirstPageOfGroup
                    suggestion.groupId = group.id
                    suggestions.append(suggestion)
                    pageCounter += 1
                } else {
                    // Fallback
                    let fallbackTemplate = LayoutTemplate.bestTemplate(forPhotoCount: chunk.count)
                    var suggestion = PageSuggestion(
                        template: fallbackTemplate,
                        photos: chunk.map { $0.photo },
                        pageNumber: pageCounter
                    )
                    suggestion.isGroupStart = isFirstPageOfGroup
                    suggestion.groupId = group.id
                    suggestions.append(suggestion)
                    pageCounter += 1
                }
                
                isFirstPageOfGroup = false
            }
        }
        
        return suggestions
    }
    
    // MARK: - Private Helper Methods
    
    /// 照片集特征分析
    private struct PhotoSetAnalysis {
        let count: Int
        let dominantScene: SceneCategory?
        let dominantOrientation: PhotoOrientation
        let averageQuality: Float
        let hasFaces: Bool
    }
    
    private func analyzePhotoSet(_ photos: [ClassifiedPhoto]) -> PhotoSetAnalysis {
        var sceneCounts: [SceneCategory: Int] = [:]
        var orientationCounts: [PhotoOrientation: Int] = [:]
        var totalQuality: Float = 0
        var faceCount = 0
        
        for photo in photos {
            if let scene = photo.sceneCategory {
                sceneCounts[scene, default: 0] += 1
            }
            orientationCounts[photo.orientation, default: 0] += 1
            totalQuality += photo.qualityScore
            if photo.hasFaces {
                faceCount += 1
            }
        }
        
        let dominantScene = sceneCounts.max(by: { $0.value < $1.value })?.key
        
        let dominantOrientation: PhotoOrientation
        if (orientationCounts[.landscape] ?? 0) >= (orientationCounts[.portrait] ?? 0) {
            dominantOrientation = .landscape
        } else {
            dominantOrientation = .portrait
        }
        
        return PhotoSetAnalysis(
            count: photos.count,
            dominantScene: dominantScene,
            dominantOrientation: dominantOrientation,
            averageQuality: totalQuality / Float(max(1, photos.count)),
            hasFaces: faceCount > 0
        )
    }
    
    private func calculateMatchScore(template: LayoutTemplate, analysis: PhotoSetAnalysis) -> Double {
        var score: Double = 0.5 // 基础分
        
        // 场景匹配 (权重 0.3)
        if let scene = analysis.dominantScene {
            if template.suitableScenes.contains(scene) {
                score += 0.3
            } else if template.suitableScenes.contains(.other) {
                 // 中性模板
                score += 0.1
            }
        }
        
        // 方向匹配 (权重 0.3)
        // 检查模板是否适合主要的照片方向
        if template.suitableOrientations.contains(analysis.dominantOrientation) {
            score += 0.3
        }
        
        // 风格微调 (权重 0.1)
        if analysis.hasFaces && (template.styleTag == .classic || template.styleTag == .magazine) {
            score += 0.1
        }
        
        return min(1.0, score)
    }
    
    private func generateRecommendationReason(template: LayoutTemplate, analysis: PhotoSetAnalysis) -> String {
        var reasons: [String] = []
        
        if let scene = analysis.dominantScene, template.suitableScenes.contains(scene) {
            reasons.append("适合\(scene.displayName)")
        }
        
        if template.suitableOrientations.contains(analysis.dominantOrientation) {
            reasons.append("匹配照片方向")
        }
        
        if reasons.isEmpty {
            return "自动推荐"
        }
        
        return reasons.joined(separator: "，")
    }
    
    private func calculateOptimalCrop(photo: ClassifiedPhoto, slot: LayoutSlot) -> CGRect {
        // 简化的裁切逻辑：保持居中，如果有脸则优先尝试包含脸部（这里暂未实现具体的脸部坐标映射，仅做框架）
        // 实际的 photo 对象里可能没有脸部坐标信息（ClassifiedPhoto 结构体中目前主要存统计信息）
        // 真正的智能裁切需要访问 PhotoClassifier 的详细 FaceObservation
        
        // 这里实现一个简单的 "Cover" 模式裁切计算
        let slotRatio = slot.rect.width / slot.rect.height
        
        // 假设照片默认比例，实际应读取 photo.width/height
        // 这里做一个假设：landscape=4:3, portrait=3:4
        let photoRatio: CGFloat
        switch photo.orientation {
        case .landscape: photoRatio = 4.0/3.0
        case .portrait: photoRatio = 3.0/4.0
        case .square: photoRatio = 1.0
        }
        
        var cropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        
        if photoRatio > slotRatio {
            // 照片更宽，裁切左右
            let newWidth = slotRatio / photoRatio // < 1
            let xOffset = (1.0 - newWidth) / 2.0
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: 1.0)
        } else {
            // 照片更高，裁切上下
            let newHeight = photoRatio / slotRatio // < 1
            let yOffset = (1.0 - newHeight) / 2.0
            cropRect = CGRect(x: 0, y: yOffset, width: 1.0, height: newHeight)
        }
        
        return cropRect
    }
    
    // MARK: - Legacy Compatibility
    
    struct LayoutResult {
        let photoPlacements: [(Photo, CGRect)]
    }
    
    /// Legacy method for compatibility with EditorState
    func layoutPhotos(_ photos: [Photo], onPageSize pageSize: PageSize) -> LayoutResult {
        // Create dummy classified photos
        let classified = photos.map { photo -> ClassifiedPhoto in
             let w = CGFloat(photo.width ?? 1)
             let h = CGFloat(photo.height ?? 1)
             let orientation: PhotoOrientation = w >= h ? .landscape : (w == h ? .square : .portrait)
             
             // Initializer allows only minimal params, others are vars
             var cp = ClassifiedPhoto(
                 photo: photo,
                 sceneCategory: .other,
                 qualityScore: 0.8
             )
             cp.orientation = orientation
             cp.hasFaces = false
             cp.faceCount = 0
             return cp
        }
        
        // Recommend
        let recommendations = recommendTemplates(for: classified, count: 1)
        
        guard let bestTemplate = recommendations.first?.template else {
             return LayoutResult(photoPlacements: [])
        }
        
        // Fill
        let filledResult = autoFillTemplate(bestTemplate, with: classified)
        
        // Convert to absolute frames
        var placements: [(Photo, CGRect)] = []
        let pageWidth = pageSize.dimensionsInPoints.width
        let pageHeight = pageSize.dimensionsInPoints.height
        
        for item in filledResult {
            // Find slot rect
            if item.slotIndex < bestTemplate.slots.count {
                let slotRect = bestTemplate.slots[item.slotIndex].rect
                let absFrame = CGRect(
                    x: slotRect.origin.x * pageWidth,
                    y: slotRect.origin.y * pageHeight,
                    width: slotRect.width * pageWidth,
                    height: slotRect.height * pageHeight
                )
                placements.append((item.photo, absFrame))
            }
        }
        
        return LayoutResult(photoPlacements: placements)
    }
}
