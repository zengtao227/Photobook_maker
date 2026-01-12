import Foundation
import AppKit

/// Represents a single photo with its metadata
struct Photo: Identifiable, Hashable, Codable, @unchecked Sendable {
    let id: UUID
    let url: URL
    var dateTaken: Date?
    var thumbnailImage: NSImage?

    // EXIF metadata
    var width: Int?
    var height: Int?
    var cameraModel: String?
    var sceneLabel: String?
    var latitude: Double?
    var longitude: Double?
    var locationName: String?
    var location: String?
    
    // V2 智能分类属性
    var sceneCategory: SceneCategory?
    var faceClusterIds: [UUID]?
    var locationGroupId: UUID?
    var qualityScore: Float?  // 0-1，用于智能推荐封面
    var hasFaces: Bool?
    var faceCount: Int?

    // Hashable: Ignore image
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Photo, rhs: Photo) -> Bool {
        lhs.id == rhs.id
    }

    // CodingKeys: Exclude thumbnailImage
    enum CodingKeys: String, CodingKey {
        case id, url, dateTaken, width, height, cameraModel, location, sceneLabel, latitude, longitude, locationName
        case sceneCategory, faceClusterIds, locationGroupId, qualityScore, hasFaces, faceCount
    }

    // Decode
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        url = try container.decode(URL.self, forKey: .url)
        dateTaken = try container.decodeIfPresent(Date.self, forKey: .dateTaken)
        width = try container.decodeIfPresent(Int.self, forKey: .width)
        height = try container.decodeIfPresent(Int.self, forKey: .height)
        cameraModel = try container.decodeIfPresent(String.self, forKey: .cameraModel)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        sceneLabel = try container.decodeIfPresent(String.self, forKey: .sceneLabel)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        // V2 属性
        sceneCategory = try container.decodeIfPresent(SceneCategory.self, forKey: .sceneCategory)
        faceClusterIds = try container.decodeIfPresent([UUID].self, forKey: .faceClusterIds)
        locationGroupId = try container.decodeIfPresent(UUID.self, forKey: .locationGroupId)
        qualityScore = try container.decodeIfPresent(Float.self, forKey: .qualityScore)
        hasFaces = try container.decodeIfPresent(Bool.self, forKey: .hasFaces)
        faceCount = try container.decodeIfPresent(Int.self, forKey: .faceCount)
        thumbnailImage = nil
    }

    // Encode
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(dateTaken, forKey: .dateTaken)
        try container.encodeIfPresent(width, forKey: .width)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(cameraModel, forKey: .cameraModel)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(sceneLabel, forKey: .sceneLabel)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        try container.encodeIfPresent(locationName, forKey: .locationName)
        // V2 属性
        try container.encodeIfPresent(sceneCategory, forKey: .sceneCategory)
        try container.encodeIfPresent(faceClusterIds, forKey: .faceClusterIds)
        try container.encodeIfPresent(locationGroupId, forKey: .locationGroupId)
        try container.encodeIfPresent(qualityScore, forKey: .qualityScore)
        try container.encodeIfPresent(hasFaces, forKey: .hasFaces)
        try container.encodeIfPresent(faceCount, forKey: .faceCount)
    }

    // Normal Init
    init(id: UUID = UUID(), url: URL, dateTaken: Date? = nil, thumbnailImage: NSImage? = nil) {
        self.id = id
        self.url = url
        self.dateTaken = dateTaken
        self.thumbnailImage = thumbnailImage
        
        // Automatically read image dimensions
        if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
           let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
            self.width = properties[kCGImagePropertyPixelWidth as String] as? Int
            self.height = properties[kCGImagePropertyPixelHeight as String] as? Int
        }
    }

    // For display
    var filename: String {
        url.lastPathComponent
    }

    var monthKey: String {
        guard let date = dateTaken else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    var displayMonth: String {
        guard let date = dateTaken else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

/// Group of photos by month
struct MonthGroup: Identifiable {
    let id: String
    let month: String
    let monthKey: String
    var photos: [Photo]
    var pagesAllocated: Int = 3
    init(month: String, monthKey: String, photos: [Photo]) {
        self.id = monthKey
        self.month = month
        self.monthKey = monthKey
        self.photos = photos
    }
}

/// Lightweight page model for the navigator
struct PhotoPage: Identifiable, Codable {
    let id: UUID
    var order: Int
    init(id: UUID = UUID(), order: Int) {
        self.id = id
        self.order = order
    }
}
