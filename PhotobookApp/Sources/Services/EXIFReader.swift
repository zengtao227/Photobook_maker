import Foundation
import ImageIO
import CoreLocation

/// Reads EXIF metadata from photos
class EXIFReader {

    /// Get the date taken from EXIF data
    func getDateTaken(from url: URL) -> Date? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }
        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
           let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
            return parseExifDate(dateString)
        }
        if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
           let dateString = tiff[kCGImagePropertyTIFFDateTime as String] as? String {
            return parseExifDate(dateString)
        }
        let fileManager = FileManager.default
        if let attributes = try? fileManager.attributesOfItem(atPath: url.path),
           let modDate = attributes[.modificationDate] as? Date {
            return modDate
        }
        return nil
    }

    /// Get all metadata from a photo
    func getAllMetadata(from url: URL) -> PhotoMetadata? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return nil
        }
        var metadata = PhotoMetadata()
        
        // Get raw dimensions
        let rawWidth = properties[kCGImagePropertyPixelWidth as String] as? Int ?? 0
        let rawHeight = properties[kCGImagePropertyPixelHeight as String] as? Int ?? 0
        
        // Check EXIF orientation and swap dimensions if needed
        let orientation = properties[kCGImagePropertyOrientation as String] as? Int ?? 1
        // Orientations 5-8 have width/height swapped
        if orientation >= 5 && orientation <= 8 {
            metadata.width = rawHeight
            metadata.height = rawWidth
        } else {
            metadata.width = rawWidth
            metadata.height = rawHeight
        }
        
        if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            if let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                metadata.dateTaken = parseExifDate(dateString)
            }
            metadata.fNumber = exif[kCGImagePropertyExifFNumber as String] as? Double
            metadata.exposureTime = exif[kCGImagePropertyExifExposureTime as String] as? Double
            metadata.isoSpeed = (exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int])?.first
            metadata.focalLength = exif[kCGImagePropertyExifFocalLength as String] as? Double
        }
        if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            metadata.cameraMake = tiff[kCGImagePropertyTIFFMake as String] as? String
            metadata.cameraModel = tiff[kCGImagePropertyTIFFModel as String] as? String
        }
        if let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            if let lat = gps[kCGImagePropertyGPSLatitude as String] as? Double,
               let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
               let lon = gps[kCGImagePropertyGPSLongitude as String] as? Double,
               let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String {
                let latitude = latRef == "S" ? -lat : lat
                let longitude = lonRef == "W" ? -lon : lon
                metadata.location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }
        return metadata
    }

    private func parseExifDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: dateString)
    }
    
    /// Convert coordinates to a human-readable location name
    func reverseGeocode(location: CLLocationCoordinate2D) async -> String? {
        let geocoder = CLGeocoder()
        let loc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(loc)
            if let placemark = placemarks.first {
                return placemark.locality ?? placemark.name ?? placemark.country
            }
        } catch {
            print("❌ Reverse geocoding failed: \(error.localizedDescription)")
        }
        return nil
    }
}

struct PhotoMetadata {
    var width: Int?
    var height: Int?
    var dateTaken: Date?
    var cameraMake: String?
    var cameraModel: String?
    var fNumber: Double?
    var exposureTime: Double?
    var isoSpeed: Int?
    var focalLength: Double?
    var location: CLLocationCoordinate2D?

    var cameraDescription: String? {
        if let make = cameraMake, let model = cameraModel {
            return "\(make) \(model)"
        }
        return cameraModel ?? cameraMake
    }

    var exposureDescription: String? {
        var parts: [String] = []
        if let f = fNumber { parts.append("f/\(String(format: "%.1f", f))") }
        if let exp = exposureTime {
            if exp >= 1 { parts.append("\(String(format: "%.1f", exp))s") }
            else { parts.append("1/\(Int(1/exp))s") }
        }
        if let iso = isoSpeed { parts.append("ISO \(iso)") }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}
