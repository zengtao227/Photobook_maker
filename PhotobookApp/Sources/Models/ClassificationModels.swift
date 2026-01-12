import Foundation
import CoreLocation

// MARK: - Activity Type

/// 活动类型枚举
enum ActivityType: Equatable, Hashable {
    case sports(SportType)      // 运动
    case travel                 // 旅行
    case dining                 // 美食
    case party                  // 聚会/活动
    case family                 // 家庭活动
    case outdoor                // 户外活动
    case indoor                 // 室内活动
    case special(SpecialEvent)  // 特殊事件
    case unknown
    
    var displayName: String {
        switch self {
        case .sports(let type): return type.displayName
        case .travel: return "旅行"
        case .dining: return "美食"
        case .party: return "聚会"
        case .family: return "家庭时光"
        case .outdoor: return "户外活动"
        case .indoor: return "室内活动"
        case .special(let event): return event.displayName
        case .unknown: return "其他活动"
        }
    }
    
    var icon: String {
        switch self {
        case .sports: return "figure.run"
        case .travel: return "airplane"
        case .dining: return "fork.knife"
        case .party: return "party.popper"
        case .family: return "figure.2.and.child.holdinghands"
        case .outdoor: return "leaf"
        case .indoor: return "house"
        case .special: return "star.fill"
        case .unknown: return "photo"
        }
    }
}

/// 运动类型
enum SportType: String, Equatable, Hashable {
    case basketball = "篮球"
    case football = "足球"
    case skiing = "滑雪"
    case cycling = "骑行"
    case swimming = "游泳"
    case running = "跑步"
    case hiking = "徒步"
    case tennis = "网球"
    case other = "运动"
    
    var displayName: String { rawValue }
}

/// 特殊事件类型
enum SpecialEvent: String, Equatable, Hashable {
    case wedding = "婚礼"
    case birthday = "生日"
    case graduation = "毕业典礼"
    case anniversary = "纪念日"
    case other = "特殊活动"
    
    var displayName: String { rawValue }
}

// MARK: - Scene Category

/// 场景分类枚举
enum SceneCategory: String, Codable, CaseIterable, Identifiable {
    case landscape    // 风景
    case portrait     // 人像
    case food         // 美食
    case architecture // 建筑
    case animal       // 动物
    case document     // 文档
    case event        // 活动/聚会
    case nature       // 自然
    case urban        // 城市
    case travel       // 旅行
    case family       // 家庭
    case other        // 其他
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .landscape: return "风景"
        case .portrait: return "人像"
        case .food: return "美食"
        case .architecture: return "建筑"
        case .animal: return "动物"
        case .document: return "文档"
        case .event: return "活动"
        case .nature: return "自然"
        case .urban: return "城市"
        case .travel: return "旅行"
        case .family: return "家庭"
        case .other: return "其他"
        }
    }
    
    var icon: String {
        switch self {
        case .landscape: return "mountain.2"
        case .portrait: return "person"
        case .food: return "fork.knife"
        case .architecture: return "building.2"
        case .animal: return "pawprint"
        case .document: return "doc.text"
        case .event: return "party.popper"
        case .nature: return "leaf"
        case .urban: return "building"
        case .travel: return "airplane"
        case .family: return "figure.2.and.child.holdinghands"
        case .other: return "photo"
        }
    }
}

// MARK: - Photo Orientation

/// 照片方向
enum PhotoOrientation: String, Codable {
    case landscape  // 横向
    case portrait   // 纵向
    case square     // 方形
}

// MARK: - Template Style

/// 模板风格
enum TemplateStyle: String, Codable, CaseIterable, Identifiable {
    case minimal    // 简约现代
    case magazine   // 杂志风格
    case classic    // 经典传统
    case family     // 温馨家庭
    case artistic   // 艺术创意
    case travel     // 旅行日记
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .minimal: return "简约现代"
        case .magazine: return "杂志风格"
        case .classic: return "经典传统"
        case .family: return "温馨家庭"
        case .artistic: return "艺术创意"
        case .travel: return "旅行日记"
        }
    }
}

// MARK: - Face Cluster

/// 人脸聚类
struct FaceCluster: Identifiable, Codable {
    let id: UUID
    var representativePhotoId: UUID
    var memberPhotoIds: [UUID]
    var userAssignedName: String?
    
    var photoCount: Int { memberPhotoIds.count }
    
    init(id: UUID = UUID(), representativePhotoId: UUID, memberPhotoIds: [UUID] = [], userAssignedName: String? = nil) {
        self.id = id
        self.representativePhotoId = representativePhotoId
        self.memberPhotoIds = memberPhotoIds
        self.userAssignedName = userAssignedName
    }
}

// MARK: - Location Group

/// 地点分组
struct LocationGroup: Identifiable, Codable {
    let id: UUID
    var placeName: String
    var latitude: Double
    var longitude: Double
    var photoIds: [UUID]
    var startDate: Date?
    var endDate: Date?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var photoCount: Int { photoIds.count }
    
    init(id: UUID = UUID(), placeName: String, latitude: Double, longitude: Double, photoIds: [UUID] = [], startDate: Date? = nil, endDate: Date? = nil) {
        self.id = id
        self.placeName = placeName
        self.latitude = latitude
        self.longitude = longitude
        self.photoIds = photoIds
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Photo Group (for Smart Import)

/// 照片分组（用于智能导入）
struct PhotoGroup: Identifiable {
    let id: UUID
    var name: String
    var icon: String
    var photos: [Photo]
    var groupType: GroupType
    var isSelected: Bool = true
    
    enum GroupType {
        case scene(SceneCategory)
        case location(LocationGroup)
        case date(Date)
        case face(FaceCluster)
        case custom
    }
    
    var photoCount: Int { photos.count }
    
    init(id: UUID = UUID(), name: String, icon: String, photos: [Photo], groupType: GroupType) {
        self.id = id
        self.name = name
        self.icon = icon
        self.photos = photos
        self.groupType = groupType
    }
}

// MARK: - Classified Photo

/// 已分类的照片（包含分析结果）
struct ClassifiedPhoto {
    let photo: Photo
    var sceneCategory: SceneCategory?
    var orientation: PhotoOrientation
    var qualityScore: Float  // 0-1
    var hasFaces: Bool
    var faceCount: Int
    
    init(photo: Photo, sceneCategory: SceneCategory? = nil, qualityScore: Float = 0.5) {
        self.photo = photo
        self.sceneCategory = sceneCategory
        self.qualityScore = qualityScore
        self.hasFaces = false
        self.faceCount = 0
        
        // 计算方向
        if let w = photo.width, let h = photo.height {
            let ratio = Double(w) / Double(h)
            if ratio > 1.1 {
                self.orientation = .landscape
            } else if ratio < 0.9 {
                self.orientation = .portrait
            } else {
                self.orientation = .square
            }
        } else {
            self.orientation = .landscape
        }
    }
}

// MARK: - Template Recommendation

/// 模板推荐结果
struct TemplateRecommendation: Identifiable {
    let id = UUID()
    let template: LayoutTemplate
    let score: Double  // 0-1 匹配分数
    let reason: String // 推荐理由
}

// MARK: - Page Suggestion

/// 页面布局建议
struct PageSuggestion: Identifiable {
    let id = UUID()
    var template: LayoutTemplate
    var photos: [Photo]
    var pageNumber: Int
    
    // Event Isolation properties
    var isGroupStart: Bool = false  // True if this is the first page of a new group
    var groupId: UUID? = nil        // ID of the group this page belongs to
}
