import Foundation
import AppKit

/// Represents a single photo with its metadata
struct Photo: Identifiable, Hashable, Codable {
    let id: UUID
    let url: URL
    let dateTaken: Date?
    var thumbnailImage: NSImage? // Changed to var so we can set it later, though let is fine with init

    // EXIF metadata
    var width: Int?
    var height: Int?
    var cameraModel: String?
    var location: String?

    // Hashable: Ignore image
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Photo, rhs: Photo) -> Bool {
        lhs.id == rhs.id
    }

    // CodingKeys: Exclude thumbnailImage
    enum CodingKeys: String, CodingKey {
        case id, url, dateTaken, width, height, cameraModel, location
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
        thumbnailImage = nil // Default to nil, will ideally reload later
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
        // Skip thumbnailImage
    }

    // Normal Init
    init(id: UUID = UUID(), url: URL, dateTaken: Date? = nil, thumbnailImage: NSImage? = nil) {
        self.id = id
        self.url = url
        self.dateTaken = dateTaken
        self.thumbnailImage = thumbnailImage
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
    var pagesAllocated: Int = 3  // Default pages per month
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
