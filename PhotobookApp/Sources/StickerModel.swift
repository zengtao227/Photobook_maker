import SwiftUI
#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformImage = UIImage
#endif

// MARK: - Models
enum StickerType: String, CaseIterable, Codable {
    case system
    case user
}

struct StickerCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String // Emoji
    let type: StickerType
}

struct Sticker: Identifiable, Hashable, Codable {
    let id: UUID
    let content: String // Emoji character or Image Name/Path
    let isEmoji: Bool
    let category: String
}

struct PhotoPage: Identifiable, Hashable {
    let id: UUID
    var order: Int
    var stickers: [Sticker] = []
    // In a real app, this would hold the photo asset identifier
    var thumbnail: String? 
}

// MARK: - Data Source
class StickerService: ObservableObject {
    @Published var systemCategories: [StickerCategory] = [
        .init(id: "family", name: "Family", icon: "👨👩👧", type: .system),
        .init(id: "weather", name: "Weather", icon: "🌤️", type: .system),
        .init(id: "holidays", name: "Holidays", icon: "🎄", type: .system),
        .init(id: "birthday", name: "Birthday", icon: "🎂", type: .system),
        .init(id: "seasons", name: "Seasons", icon: "🍂", type: .system),
        .init(id: "fruits", name: "Fruits", icon: "🍓", type: .system)
    ]
    
    @Published var stickers: [Sticker] = []
    @Published var userStickers: [Sticker] = []
    
    init() {
        loadSystemStickers()
    }
    
    private func loadSystemStickers() {
        // Preset Emojis
        let rawData: [(String, [String])] = [
            ("family", ["👨","👩","👴","👵","👶","👦","👧","🏠","❤️","👨👩👧","🐶","🐱"]),
            ("weather", ["☀️","🌤️","☁️","🌧️","⛈️","🌨️","🌪️","🌈","☔","🌬️","❄️","🌡️"]),
            ("holidays", ["🎄","🎅","🎃","👻","🧨","🧧","🦃","🥚","💘","🎆","🎋","🕎"]),
            ("birthday", ["🎂","🕯️","🎁","🎈","🎉","🎊","🥳","👑","🍰","🧁","🍭","🥂"]),
            ("seasons", ["🌸","🌷","🌻","🍦","🏊","🍂","🍁","🧣","⛄","⛷️","🧤","🧊"]),
            ("fruits", ["🍎","🍐","🍊","🍋","🍌","🍉","🍇","🍓","🫐","🍈","🍒","🍑","🥭","🍍","🥥","🥝"])
        ]
        
        self.stickers = rawData.flatMap { (cat, emojis) in
            emojis.map { Sticker(id: UUID(), content: $0, isEmoji: true, category: cat) }
        }
    }
    
    func addUserSticker(image: PlatformImage) {
        // In a real app, save image to disk and store path. Here we simulate.
        let newSticker = Sticker(id: UUID(), content: "temp_image_path", isEmoji: false, category: "custom")
        userStickers.append(newSticker)
    }
}
