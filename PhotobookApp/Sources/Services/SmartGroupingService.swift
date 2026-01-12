import Foundation
import CoreLocation

/// Represents a cluster of photos grouped by logic
struct PhotoEvent: Identifiable {
    let id: UUID = UUID()
    let name: String
    let startDate: Date
    let endDate: Date
    let locationName: String?
    let sceneType: String?
    var photos: [Photo]
    
    var dateDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return formatter.string(from: startDate)
        } else {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
}

class SmartGroupingService {
    
    /// Group photos into meaningful events
    func groupIntoEvents(photos: [Photo]) -> [PhotoEvent] {
        guard !photos.isEmpty else { return [] }
        
        // 1. Sort by date
        let sortedPhotos = photos.sorted { ($0.dateTaken ?? .distantPast) < ($1.dateTaken ?? .distantPast) }
        
        var events: [PhotoEvent] = []
        var currentCluster: [Photo] = []
        
        // Time gap threshold: 4 hours
        let timeGapThreshold: TimeInterval = 4 * 3600 
        
        for photo in sortedPhotos {
            if currentCluster.isEmpty {
                currentCluster.append(photo)
                continue
            }
            
            let lastPhoto = currentCluster.last!
            let lastDate = lastPhoto.dateTaken ?? .distantPast
            let currentDate = photo.dateTaken ?? .distantPast
            
            // Check time gap
            let timeGap = currentDate.timeIntervalSince(lastDate)
            
            // Check location change (if available)
            var locationChanged = false
            if let lat1 = lastPhoto.latitude, let lon1 = lastPhoto.longitude,
               let lat2 = photo.latitude, let lon2 = photo.longitude {
                let loc1 = CLLocation(latitude: lat1, longitude: lon1)
                let loc2 = CLLocation(latitude: lat2, longitude: lon2)
                if loc1.distance(from: loc2) > 1000 { // 1km threshold
                    locationChanged = true
                }
            }
            
            if timeGap > timeGapThreshold || locationChanged {
                if let event = createEvent(from: currentCluster) {
                    events.append(event)
                }
                currentCluster = [photo]
            } else {
                currentCluster.append(photo)
            }
        }
        
        if !currentCluster.isEmpty {
            if let event = createEvent(from: currentCluster) {
                events.append(event)
            }
        }
        return events
    }
    
    private func createEvent(from photos: [Photo]) -> PhotoEvent? {
        guard let first = photos.first, let last = photos.last else { return nil }
        
        let startDate = first.dateTaken ?? .distantPast
        let endDate = last.dateTaken ?? .distantPast
        
        let locations = photos.compactMap { $0.locationName }
        let locationName = locations.mostFrequent()
        
        let scenes = photos.compactMap { $0.sceneLabel }
        let sceneType = scenes.mostFrequent()
        
        var name = ""
        if let scene = sceneType {
            name = scene.capitalized
        } else {
            name = "Event"
        }
        
        if let loc = locationName {
            name += " in \(loc)"
        }
        
        return PhotoEvent(
            name: name,
            startDate: startDate,
            endDate: endDate,
            locationName: locationName,
            sceneType: sceneType,
            photos: photos
        )
    }
}

extension Array where Element: Hashable {
    func mostFrequent() -> Element? {
        let counts = reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key
    }
}
