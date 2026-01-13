import Foundation
import Vision
import AppKit
import CoreLocation
import ImageIO

/// Face observation result
struct FaceObservation: Identifiable {
    let id = UUID()
    let boundingBox: CGRect
    let confidence: Float
    var faceprint: [Float]?  // Feature vector for clustering
}

/// Photo classification service using Apple Vision framework
@MainActor
class PhotoClassifier: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var currentStatus: String = ""
    @Published var classifiedPhotos: [ClassifiedPhoto] = []
    @Published var faceClust: [FaceCluster] = []
    @Published var locationGroups: [LocationGroup] = []
    
    // MARK: - Private Properties
    
    private let geocoder = CLGeocoder()
    
    // Vision request handlers
    private lazy var classificationRequest: VNClassifyImageRequest = {
        let request = VNClassifyImageRequest()
        request.revision = VNClassifyImageRequestRevision1
        return request
    }()
    
    private lazy var faceDetectionRequest: VNDetectFaceRectanglesRequest = {
        let request = VNDetectFaceRectanglesRequest()
        return request
    }()
    
    private lazy var qualityRequest: VNDetectFaceCaptureQualityRequest = {
        let request = VNDetectFaceCaptureQualityRequest()
        return request
    }()
    
    // MARK: - Scene Classification
    
    /// Classify scene category for an image
    func classifyScene(_ image: CGImage) async -> SceneCategory {
        return await withCheckedContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform([classificationRequest])
                
                if let results = classificationRequest.results {
                    let category = mapVisionResultsToCategory(results)
                    continuation.resume(returning: category)
                } else {
                    continuation.resume(returning: .other)
                }
            } catch {
                print("Scene classification error: \(error)")
                continuation.resume(returning: .other)
            }
        }
    }
    
    /// Map Vision classification results to our SceneCategory
    private func mapVisionResultsToCategory(_ results: [VNClassificationObservation]) -> SceneCategory {
        // Get top classifications with confidence > 0.1 (lowered threshold for better coverage)
        let topResults = results.filter { $0.confidence > 0.1 }.prefix(10)
        
        // Score each category based on matching keywords
        var categoryScores: [SceneCategory: Float] = [:]
        
        for result in topResults {
            let identifier = result.identifier.lowercased()
            let confidence = result.confidence
            
            // Landscape/Nature keywords
            if identifier.contains("mountain") || identifier.contains("beach") ||
               identifier.contains("ocean") || identifier.contains("lake") ||
               identifier.contains("sky") || identifier.contains("sunset") ||
               identifier.contains("sunrise") || identifier.contains("horizon") ||
               identifier.contains("sea") || identifier.contains("coast") ||
               identifier.contains("valley") || identifier.contains("cliff") ||
               identifier.contains("waterfall") || identifier.contains("river") {
                categoryScores[.landscape, default: 0] += confidence
            }
            
            // Portrait/People keywords
            if identifier.contains("person") || identifier.contains("people") ||
               identifier.contains("face") || identifier.contains("portrait") ||
               identifier.contains("selfie") || identifier.contains("man") ||
               identifier.contains("woman") || identifier.contains("child") ||
               identifier.contains("baby") || identifier.contains("group") {
                categoryScores[.portrait, default: 0] += confidence
            }
            
            // Food keywords
            if identifier.contains("food") || identifier.contains("meal") ||
               identifier.contains("dish") || identifier.contains("restaurant") ||
               identifier.contains("cuisine") || identifier.contains("dessert") ||
               identifier.contains("fruit") || identifier.contains("vegetable") ||
               identifier.contains("cake") || identifier.contains("pizza") ||
               identifier.contains("coffee") || identifier.contains("drink") {
                categoryScores[.food, default: 0] += confidence
            }
            
            // Architecture keywords
            if identifier.contains("building") || identifier.contains("architecture") ||
               identifier.contains("house") || identifier.contains("church") ||
               identifier.contains("temple") || identifier.contains("tower") ||
               identifier.contains("bridge") || identifier.contains("castle") ||
               identifier.contains("monument") || identifier.contains("skyscraper") {
                categoryScores[.architecture, default: 0] += confidence
            }
            
            // Animal keywords
            if identifier.contains("animal") || identifier.contains("dog") ||
               identifier.contains("cat") || identifier.contains("bird") ||
               identifier.contains("pet") || identifier.contains("wildlife") ||
               identifier.contains("horse") || identifier.contains("fish") ||
               identifier.contains("insect") || identifier.contains("butterfly") {
                categoryScores[.animal, default: 0] += confidence
            }
            
            // Nature keywords
            if identifier.contains("flower") || identifier.contains("tree") ||
               identifier.contains("plant") || identifier.contains("garden") ||
               identifier.contains("forest") || identifier.contains("nature") ||
               identifier.contains("grass") || identifier.contains("leaf") ||
               identifier.contains("park") || identifier.contains("green") {
                categoryScores[.nature, default: 0] += confidence
            }
            
            // Urban keywords
            if identifier.contains("city") || identifier.contains("street") ||
               identifier.contains("urban") || identifier.contains("traffic") ||
               identifier.contains("road") || identifier.contains("car") ||
               identifier.contains("downtown") || identifier.contains("night") {
                categoryScores[.urban, default: 0] += confidence
            }
            
            // Event keywords
            if identifier.contains("party") || identifier.contains("celebration") ||
               identifier.contains("wedding") || identifier.contains("birthday") ||
               identifier.contains("concert") || identifier.contains("festival") ||
               identifier.contains("ceremony") || identifier.contains("graduation") {
                categoryScores[.event, default: 0] += confidence
            }
            
            // Travel keywords
            if identifier.contains("travel") || identifier.contains("vacation") ||
               identifier.contains("tourist") || identifier.contains("landmark") ||
               identifier.contains("airport") || identifier.contains("hotel") ||
               identifier.contains("suitcase") || identifier.contains("map") {
                categoryScores[.travel, default: 0] += confidence
            }
            
            // Document keywords
            if identifier.contains("document") || identifier.contains("text") ||
               identifier.contains("paper") || identifier.contains("book") ||
               identifier.contains("screen") || identifier.contains("computer") {
                categoryScores[.document, default: 0] += confidence
            }
        }
        
        // Return the category with highest score, or .other if no matches
        if let bestCategory = categoryScores.max(by: { $0.value < $1.value }), bestCategory.value > 0.15 {
            return bestCategory.key
        }
        
        return .other
    }

    
    // MARK: - Face Detection
    
    /// Detect faces in an image
    func detectFaces(_ image: CGImage) async -> [FaceObservation] {
        return await withCheckedContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform([faceDetectionRequest])
                
                if let results = faceDetectionRequest.results {
                    let observations = results.map { face in
                        FaceObservation(
                            boundingBox: face.boundingBox,
                            confidence: face.confidence
                        )
                    }
                    continuation.resume(returning: observations)
                } else {
                    continuation.resume(returning: [])
                }
            } catch {
                print("Face detection error: \(error)")
                continuation.resume(returning: [])
            }
        }
    }
    
    /// Cluster faces based on similarity (simplified version)
    func clusterFaces(_ allObservations: [[FaceObservation]], photoIds: [UUID]) -> [FaceCluster] {
        // Simple clustering: group by similar bounding box sizes
        // In production, use face embeddings for proper clustering
        var clusters: [FaceCluster] = []
        
        for (index, observations) in allObservations.enumerated() where !observations.isEmpty {
            let photoId = photoIds[index]
            
            // For now, create one cluster per unique face detected
            // This is a simplified implementation
            if clusters.isEmpty {
                clusters.append(FaceCluster(
                    representativePhotoId: photoId,
                    memberPhotoIds: [photoId]
                ))
            } else {
                // Add to existing cluster (simplified)
                clusters[0].memberPhotoIds.append(photoId)
            }
        }
        
        return clusters
    }
    
    // MARK: - Activity-Based Event Grouping
    
    /// 基于活动/事件的智能分组
    /// 这是最高优先级的分组方式，能够识别跨越多天的连续活动
    func groupByActivity(_ photos: [ClassifiedPhoto]) -> [PhotoGroup] {
        var groups: [PhotoGroup] = []
        
        // 1. 首先按场景类型初步分类
        let sceneGroups = Dictionary(grouping: photos, by: { $0.sceneCategory ?? .other })
        
        // 2. 对每个场景类型进行时空分析
        for (scene, scenePhotos) in sceneGroups {
            guard scenePhotos.count >= 2 else { continue }
            
            // 按时间排序
            let sortedPhotos = scenePhotos.sorted { 
                ($0.photo.dateTaken ?? Date.distantPast) < ($1.photo.dateTaken ?? Date.distantPast)
            }
            
            // 3. 检测活动类型
            let activityType = detectActivityType(for: sortedPhotos, scene: scene)
            
            // 4. 基于时空连续性进行聚类
            let clusters = clusterBySpatioContinuity(sortedPhotos, activityType: activityType)
            
            // 5. 为每个聚类创建分组
            for cluster in clusters {
                let eventName = generateEventName(for: cluster, activityType: activityType, scene: scene)
                let group = PhotoGroup(
                    id: UUID(),
                    name: eventName,
                    icon: activityType.icon,
                    photos: cluster.map { $0.photo },
                    groupType: .scene(scene)
                )
                groups.append(group)
            }
        }
        
        return groups
    }
    
    /// 检测活动类型
    private func detectActivityType(for photos: [ClassifiedPhoto], scene: SceneCategory) -> ActivityType {
        // 基于场景和关键词检测活动类型
        switch scene {
        case .landscape, .nature:
            // 检查是否是户外运动
            if photos.count > 10 {
                return .outdoor
            }
            return .travel
            
        case .portrait:
            // 检查是否是聚会或家庭活动
            let hasManyFaces = photos.filter { $0.faceCount > 2 }.count > photos.count / 2
            if hasManyFaces {
                return .party
            }
            return .family
            
        case .food:
            return .dining
            
        case .architecture:
            return .travel
            
        case .urban:
            // 可能是城市游或日常活动
            return .travel
            
        case .event:
            return .party
            
        case .animal:
            return .outdoor
            
        default:
            return .unknown
        }
    }
    
    /// 基于时空连续性进行聚类
    /// 关键：识别跨越多天的连续活动（如3天滑雪、7天旅行）
    private func clusterBySpatioContinuity(_ photos: [ClassifiedPhoto], activityType: ActivityType) -> [[ClassifiedPhoto]] {
        guard !photos.isEmpty else { return [] }
        
        var clusters: [[ClassifiedPhoto]] = []
        var currentCluster: [ClassifiedPhoto] = [photos[0]]
        
        // 根据活动类型设置不同的时间阈值
        let timeGap: TimeInterval
        switch activityType {
        case .travel:
            timeGap = 86400 * 2  // 旅行：2天内算连续
        case .sports:
            timeGap = 14400      // 运动：4小时内算连续
        case .dining:
            timeGap = 7200       // 美食：2小时内算连续
        case .party:
            timeGap = 14400      // 聚会：4小时内算连续
        default:
            timeGap = 14400      // 默认：4小时
        }
        
        for i in 1..<photos.count {
            let prevPhoto = photos[i-1]
            let currPhoto = photos[i]
            
            guard let prevDate = prevPhoto.photo.dateTaken,
                  let currDate = currPhoto.photo.dateTaken else {
                currentCluster.append(currPhoto)
                continue
            }
            
            let timeDiff = currDate.timeIntervalSince(prevDate)
            
            // 检查时间连续性
            let isTimeContinuous = timeDiff <= timeGap
            
            // 检查地点连续性（如果有GPS）
            var isLocationContinuous = true
            if let prevLat = prevPhoto.photo.latitude, let prevLon = prevPhoto.photo.longitude,
               let currLat = currPhoto.photo.latitude, let currLon = currPhoto.photo.longitude {
                let distance = sqrt(pow(prevLat - currLat, 2) + pow(prevLon - currLon, 2))
                // 旅行活动允许更大的地理跨度
                let maxDistance: Double = (activityType == .travel) ? 1.0 : 0.1  // 度数
                isLocationContinuous = distance < maxDistance
            }
            
            if isTimeContinuous && isLocationContinuous {
                currentCluster.append(currPhoto)
            } else {
                // 开始新的聚类
                if currentCluster.count >= 2 {
                    clusters.append(currentCluster)
                }
                currentCluster = [currPhoto]
            }
        }
        
        // 添加最后一个聚类
        if currentCluster.count >= 2 {
            clusters.append(currentCluster)
        }
        
        return clusters
    }
    
    /// 生成事件名称
    private func generateEventName(for photos: [ClassifiedPhoto], activityType: ActivityType, scene: SceneCategory) -> String {
        guard let firstDate = photos.first?.photo.dateTaken,
              let lastDate = photos.last?.photo.dateTaken else {
            return activityType.displayName
        }
        
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        // 判断是单日还是多日活动
        let isSameDay = calendar.isDate(firstDate, inSameDayAs: lastDate)
        
        if isSameDay {
            // 单日活动
            formatter.dateFormat = "M月d日"
            let dateStr = formatter.string(from: firstDate)
            
            // 添加时间段提示
            let hour = calendar.component(.hour, from: firstDate)
            let timeHint: String
            if hour < 6 {
                timeHint = "凌晨"
            } else if hour < 12 {
                timeHint = "上午"
            } else if hour < 18 {
                timeHint = "下午"
            } else {
                timeHint = "晚上"
            }
            
            return "\(activityType.displayName) - \(dateStr) \(timeHint)"
        } else {
            // 多日活动
            let daysDiff = calendar.dateComponents([.day], from: firstDate, to: lastDate).day ?? 0
            
            if daysDiff <= 7 {
                // 短期活动：显示具体日期
                formatter.dateFormat = "M月d日"
                let startStr = formatter.string(from: firstDate)
                let endStr = formatter.string(from: lastDate)
                return "\(activityType.displayName) - \(startStr)至\(endStr)"
            } else {
                // 长期活动：显示天数
                return "\(activityType.displayName) - \(daysDiff + 1)天"
            }
        }
    }
    
    // MARK: - Time-Based Event Grouping
    
    /// Group photos by time events - photos taken within a time gap are considered same event
    /// - Parameters:
    ///   - photos: Array of photos to group
    ///   - gap: Time interval in seconds (default 4 hours = 14400 seconds)
    /// - Returns: Array of PhotoGroups representing time-based events
    func groupByTimeEvent(_ photos: [Photo], gap: TimeInterval = 14400) -> [PhotoGroup] {
        // Filter photos with valid dates and sort by date
        let datedPhotos = photos.filter { $0.dateTaken != nil }
            .sorted { $0.dateTaken! < $1.dateTaken! }
        
        guard !datedPhotos.isEmpty else { return [] }
        
        var groups: [PhotoGroup] = []
        var currentEventPhotos: [Photo] = [datedPhotos[0]]
        var eventStartDate: Date = datedPhotos[0].dateTaken!
        
        for i in 1..<datedPhotos.count {
            let photo = datedPhotos[i]
            let previousPhoto = datedPhotos[i - 1]
            
            let timeDiff = photo.dateTaken!.timeIntervalSince(previousPhoto.dateTaken!)
            
            if timeDiff > gap {
                // Start a new event group
                let eventName = formatEventName(startDate: eventStartDate, endDate: previousPhoto.dateTaken!, photoCount: currentEventPhotos.count)
                let group = PhotoGroup(
                    id: UUID(),
                    name: eventName,
                    icon: "calendar.circle.fill",
                    photos: currentEventPhotos,
                    groupType: .custom
                )
                groups.append(group)
                
                // Reset for new event
                currentEventPhotos = [photo]
                eventStartDate = photo.dateTaken!
            } else {
                // Continue current event
                currentEventPhotos.append(photo)
            }
        }
        
        // Don't forget the last group
        if !currentEventPhotos.isEmpty {
            let lastDate = currentEventPhotos.last?.dateTaken ?? eventStartDate
            let eventName = formatEventName(startDate: eventStartDate, endDate: lastDate, photoCount: currentEventPhotos.count)
            let group = PhotoGroup(
                id: UUID(),
                name: eventName,
                icon: "calendar.circle.fill",
                photos: currentEventPhotos,
                groupType: .custom
            )
            groups.append(group)
        }
        
        return groups
    }
    
    /// Format event name based on date range
    private func formatEventName(startDate: Date, endDate: Date, photoCount: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        let calendar = Calendar.current
        let sameDay = calendar.isDate(startDate, inSameDayAs: endDate)
        
        if sameDay {
            formatter.dateFormat = "M月d日"
            let dateStr = formatter.string(from: startDate)
            
            // Add time of day hint
            let hour = calendar.component(.hour, from: startDate)
            let timeHint: String
            if hour < 6 {
                timeHint = "凌晨"
            } else if hour < 12 {
                timeHint = "上午"
            } else if hour < 18 {
                timeHint = "下午"
            } else {
                timeHint = "晚上"
            }
            return "\(dateStr) \(timeHint)"
        } else {
            // Multi-day event
            formatter.dateFormat = "M月d日"
            let startStr = formatter.string(from: startDate)
            let endStr = formatter.string(from: endDate)
            return "\(startStr) - \(endStr)"
        }
    }
    
    // MARK: - Location Grouping
    
    /// Group photos by location using DBSCAN-like clustering
    func groupByLocation(_ photos: [Photo]) async -> [LocationGroup] {
        // Filter photos with GPS data
        let geoPhotos = photos.filter { $0.latitude != nil && $0.longitude != nil }
        
        guard !geoPhotos.isEmpty else { return [] }
        
        // Simple distance-based clustering (radius: ~1km)
        let clusterRadius: Double = 0.01  // ~1km in degrees
        var groups: [LocationGroup] = []
        var assigned = Set<UUID>()
        
        for photo in geoPhotos {
            guard !assigned.contains(photo.id),
                  let lat = photo.latitude,
                  let lon = photo.longitude else { continue }
            
            // Find nearby photos
            var clusterPhotos = [photo]
            
            for other in geoPhotos {
                guard !assigned.contains(other.id),
                      other.id != photo.id,
                      let otherLat = other.latitude,
                      let otherLon = other.longitude else { continue }
                
                let distance = sqrt(pow(lat - otherLat, 2) + pow(lon - otherLon, 2))
                if distance < clusterRadius {
                    clusterPhotos.append(other)
                }
            }
            
            // Mark as assigned
            for p in clusterPhotos {
                assigned.insert(p.id)
            }
            
            // Get place name via reverse geocoding
            let placeName = await reverseGeocode(latitude: lat, longitude: lon)
            
            // Calculate date range
            let dates = clusterPhotos.compactMap { $0.dateTaken }.sorted()
            
            let group = LocationGroup(
                placeName: placeName,
                latitude: lat,
                longitude: lon,
                photoIds: clusterPhotos.map { $0.id },
                startDate: dates.first,
                endDate: dates.last
            )
            
            groups.append(group)
        }
        
        return groups
    }
    
    /// Reverse geocode coordinates to place name
    private func reverseGeocode(latitude: Double, longitude: Double) async -> String {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                // Build place name from components
                var components: [String] = []
                if let locality = placemark.locality {
                    components.append(locality)
                }
                if let country = placemark.country {
                    components.append(country)
                }
                return components.isEmpty ? "未知地点" : components.joined(separator: ", ")
            }
        } catch {
            print("Geocoding error: \(error)")
        }
        
        return "未知地点"
    }

    
    // MARK: - Quality Assessment
    
    /// Assess photo quality (0-1 score)
    func assessQuality(_ image: CGImage) async -> Float {
        return await withCheckedContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            // Use face capture quality as a proxy for overall quality
            // Higher quality faces usually mean better photos
            do {
                try handler.perform([qualityRequest])
                
                if let results = qualityRequest.results, !results.isEmpty {
                    let avgQuality = results.compactMap { $0.faceCaptureQuality }.reduce(0, +) / Float(results.count)
                    continuation.resume(returning: avgQuality)
                } else {
                    // No faces, use default quality based on resolution
                    let resolution = Float(image.width * image.height)
                    let maxResolution: Float = 12_000_000  // 12MP
                    let quality = min(resolution / maxResolution, 1.0)
                    continuation.resume(returning: quality * 0.7)  // Cap at 0.7 for non-face photos
                }
            } catch {
                continuation.resume(returning: 0.5)
            }
        }
    }
    
    // MARK: - Main Analysis Entry Point
    
    func analyzePhotos(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }
        
        await MainActor.run {
            self.isProcessing = true
            self.progress = 0
            self.currentStatus = "读取元数据..."
            self.classifiedPhotos = []
            self.faceClust = []
            self.locationGroups = []
        }
        
        // 1. Create Photo objects and read EXIF in parallel
        var photos: [Photo] = []
        _ = urls.count
        
        // Parallel metadata extraction
        photos = await withTaskGroup(of: Photo.self) { group in
            for url in urls {
                group.addTask {
                    var photo = Photo(url: url)
                    // Basic metadata extraction
                    if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                       let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] {
                        
                        // GPS
                        if let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
                           let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
                           let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double {
                            let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String ?? "N"
                            let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String ?? "E"
                            photo.latitude = (latRef == "S") ? -lat : lat
                            photo.longitude = (lonRef == "W") ? -lon : lon
                        }
                        
                        // Date
                        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
                           let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                            photo.dateTaken = formatter.date(from: dateString)
                        }
                    }
                    return photo
                }
            }
            
            var results: [Photo] = []
            for await photo in group {
                results.append(photo)
            }
            return results
        }
        
        // Sort to maintain order if possible, though not strictly required
        photos.sort { $0.url.path < $1.url.path }
        
        // 2. Classify Scenes & Detect Faces (and update progress)
        let classified = await classifyPhotos(photos) { progress, status in
            Task { @MainActor in
                self.progress = progress
                self.currentStatus = status
            }
        }
        
        await MainActor.run {
            self.classifiedPhotos = classified
            self.currentStatus = "正在整理地点..."
        }
        
        // 3. Group by Location
        let locations = await groupByLocation(photos)
        
        await MainActor.run {
            self.locationGroups = locations
            self.isProcessing = false
            self.currentStatus = "分析完成"
            self.progress = 1.0
        }
    }

    // MARK: - Batch Processing
    
    /// Classify a batch of photos
    func classifyPhotos(_ photos: [Photo], progressHandler: ((Double, String) -> Void)? = nil) async -> [ClassifiedPhoto] {
        let total = photos.count
        var finishedCount = 0
        
        // Use a task group with a concurrency limit to avoid memory spikes
        let results = await withTaskGroup(of: ClassifiedPhoto?.self) { group in
            var allResults: [ClassifiedPhoto] = []
            let concurrencyLimit = 4
            
            // Initial batch
            for i in 0..<min(concurrencyLimit, total) {
                let photo = photos[i]
                group.addTask { [weak self] in
                    return await self?.processSinglePhoto(photo)
                }
            }
            
            var nextIndex = concurrencyLimit
            for await result in group {
                finishedCount += 1
                if let result = result {
                    allResults.append(result)
                }
                
                // Update progress on main thread
                let currentProgress = Double(finishedCount) / Double(total)
                let status = "分析照片 \(finishedCount)/\(total)"
                Task { @MainActor [weak self] in
                    self?.progress = currentProgress
                    self?.currentStatus = status
                }
                progressHandler?(currentProgress, status)
                
                // Add next task
                if nextIndex < total {
                    let photo = photos[nextIndex]
                    group.addTask { [weak self] in
                        return await self?.processSinglePhoto(photo)
                    }
                    nextIndex += 1
                }
            }
            return allResults
        }
        
        await MainActor.run {
            self.isProcessing = false
            self.progress = 1.0
            self.currentStatus = "分析完成"
        }
        
        return results
    }

    /// Process a single photo: scene, faces, and quality
    private func processSinglePhoto(_ photo: Photo) async -> ClassifiedPhoto {
        // Optimization: Use a small thumbnail for Vision instead of full image
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 512 // Vision usually prefers around 300-500px
        ]
        
        guard let source = CGImageSourceCreateWithURL(photo.url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return ClassifiedPhoto(photo: photo)
        }
        
        // Perform analyses (these are async but sequential for a single image)
        async let scene = classifyScene(cgImage)
        async let faces = detectFaces(cgImage)
        async let quality = assessQuality(cgImage)
        
        let (resolvedScene, resolvedFaces, resolvedQuality) = await (scene, faces, quality)
        
        var classified = ClassifiedPhoto(
            photo: photo,
            sceneCategory: resolvedScene,
            qualityScore: resolvedQuality
        )
        classified.hasFaces = !resolvedFaces.isEmpty
        classified.faceCount = resolvedFaces.count
        
        return classified
    }
    
    // MARK: - Smart Grouping
    
    /// Create smart photo groups based on classification results
    func createSmartGroups(from classifiedPhotos: [ClassifiedPhoto], locationGroups: [LocationGroup]) -> [PhotoGroup] {
        var groups: [PhotoGroup] = []
        
        // 1. Group by scene category
        var sceneGroups: [SceneCategory: [Photo]] = [:]
        for cp in classifiedPhotos {
            if let scene = cp.sceneCategory, scene != .other {
                sceneGroups[scene, default: []].append(cp.photo)
            }
        }
        
        // Create groups for scenes with enough photos (at least 2)
        for (scene, photos) in sceneGroups where photos.count >= 2 {
            groups.append(PhotoGroup(
                name: scene.displayName,
                icon: scene.icon,
                photos: photos,
                groupType: .scene(scene)
            ))
        }
        
        // 2. Add location groups
        for locGroup in locationGroups where locGroup.photoIds.count >= 2 {
            let photos = classifiedPhotos
                .filter { locGroup.photoIds.contains($0.photo.id) }
                .map { $0.photo }
            
            if !photos.isEmpty {
                // Check if this location group overlaps significantly with existing scene groups
                let existingPhotoIds = Set(groups.flatMap { $0.photos.map { $0.id } })
                let newPhotos = photos.filter { !existingPhotoIds.contains($0.id) }
                
                // Only add if there are unique photos or the group is large enough
                if newPhotos.count >= 2 || photos.count >= 5 {
                    groups.append(PhotoGroup(
                        name: "📍 " + locGroup.placeName,
                        icon: "mappin.circle.fill",
                        photos: photos,
                        groupType: .location(locGroup)
                    ))
                }
            }
        }
        
        // 3. Group photos with faces (people photos)
        let photosWithFaces = classifiedPhotos.filter { $0.hasFaces && $0.faceCount > 0 }
        if photosWithFaces.count >= 3 {
            let facePhotos = photosWithFaces.map { $0.photo }
            // Only add if not already covered by portrait category
            let portraitGroup = groups.first { 
                if case .scene(let scene) = $0.groupType, scene == .portrait {
                    return true
                }
                return false
            }
            if portraitGroup == nil || portraitGroup!.photos.count < facePhotos.count {
                // Remove portrait group if exists and add people group instead
                groups.removeAll { 
                    if case .scene(let scene) = $0.groupType, scene == .portrait {
                        return true
                    }
                    return false
                }
                groups.append(PhotoGroup(
                    name: "人物照片",
                    icon: "person.2.fill",
                    photos: facePhotos,
                    groupType: .scene(.portrait)
                ))
            }
        }
        
        // 4. Create "Other" group for uncategorized photos
        let categorizedIds = Set(groups.flatMap { $0.photos.map { $0.id } })
        let uncategorized = classifiedPhotos
            .filter { !categorizedIds.contains($0.photo.id) }
            .map { $0.photo }
        
        if !uncategorized.isEmpty {
            groups.append(PhotoGroup(
                name: "其他照片",
                icon: "photo.stack",
                photos: uncategorized,
                groupType: .custom
            ))
        }
        
        // 5. Sort by photo count (largest first)
        groups.sort { $0.photoCount > $1.photoCount }
        
        // 6. If no groups created at all, create a single group with all photos
        if groups.isEmpty && !classifiedPhotos.isEmpty {
            groups.append(PhotoGroup(
                name: "所有照片",
                icon: "photo.stack",
                photos: classifiedPhotos.map { $0.photo },
                groupType: .custom
            ))
        }
        
        return groups
    }
}
