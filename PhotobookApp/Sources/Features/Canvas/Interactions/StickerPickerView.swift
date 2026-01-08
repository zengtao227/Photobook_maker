import SwiftUI

struct StickerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EditorState.self) private var editorState
    @State private var stickerManager = StickerManager()
    
    let isLeftPage: Bool
    
    @State private var selectedCategory: StickerCategory = .favorites
    @State private var isImporting = false
    
    enum StickerCategory: String, CaseIterable, Identifiable {
        case favorites = "精选/收藏"
        case custom = "自定义"
        case family = "家庭活动"
        case weather = "天气"
        case holiday = "节日/生日"
        case seasons = "四季"
        case fruits = "水果/食物"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .favorites: return "star.fill"
            case .custom: return "folder.fill"
            case .family: return "figure.2.and.child.holdinghands"
            case .weather: return "cloud.sun.fill"
            case .holiday: return "gift.fill"
            case .seasons: return "leaf.fill"
            case .fruits: return "fork.knife"
            }
        }
    }
    
    // Data Source
    private var stickers: [StickerItem] {
        switch selectedCategory {
        case .favorites:
            return [
                .emoji("❤️"), .emoji("👍"), .system("star.fill", .yellow), .system("heart.fill", .red),
                .emoji("✨"), .emoji("💡"), .system("checkmark.seal.fill", .blue),
                .emoji("🎉"), .emoji("🌟"), .emoji("💖"), .emoji("🔥"), .emoji("💯"),
                .system("sparkles", .yellow), .system("flame.fill", .orange), .system("bolt.fill", .yellow)
            ]
        case .family:
            return [
                .system("house.fill", .blue), .system("car.fill", .gray), .system("figure.walk", .black),
                .emoji("👨‍👩‍👧‍👦"), .emoji("🏠"), .emoji("🚗"), .emoji("🐕"), .emoji("🐈"),
                .emoji("🚴"), .emoji("🥘"), .emoji("🧸"), .emoji("👶"), .emoji("👧"), .emoji("👦"),
                .emoji("🎒"), .emoji("📚"), .emoji("⚽️"), .emoji("🎮"), .emoji("🎨"),
                .system("figure.2.and.child.holdinghands", .blue), .system("pawprint.fill", .brown)
            ]
        case .weather:
             return [
                .system("sun.max.fill", .orange), .system("cloud.rain.fill", .blue), .system("cloud.snow.fill", .cyan),
                .system("bolt.fill", .yellow), .system("moon.stars.fill", .purple),
                .emoji("☀️"), .emoji("🌧️"), .emoji("❄️"), .emoji("🌈"), .emoji("⚡️"),
                .emoji("🌤️"), .emoji("⛅️"), .emoji("🌥️"), .emoji("☁️"), .emoji("🌦️"),
                .emoji("🌨️"), .emoji("⛈️"), .emoji("🌩️"), .emoji("🌪️"), .emoji("🌫️"),
                .system("cloud.sun.fill", .orange), .system("cloud.bolt.fill", .purple)
             ]
        case .holiday:
             return [
                .system("birthday.cake.fill", .pink), .system("gift.fill", .red), .system("party.popper.fill", .purple),
                .emoji("🎂"), .emoji("🎄"), .emoji("🧧"), .emoji("🎃"), .emoji("🎆"), .emoji("💍"),
                .emoji("🎁"), .emoji("🎊"), .emoji("🎈"), .emoji("🎀"), .emoji("🎇"), .emoji("🎐"),
                .emoji("🎑"), .emoji("🎏"), .emoji("🎗️"), .emoji("🎟️"), .emoji("🎫"), .emoji("🎖️"),
                .emoji("🏆"), .emoji("🥇"), .emoji("🥈"), .emoji("🥉"),
                .system("balloon.fill", .red)
             ]
        case .seasons:
             return [
                .system("leaf.fill", .green), .system("snowflake", .cyan), .system("sun.max.fill", .orange),
                .emoji("🌸"), .emoji("🌻"), .emoji("🍁"), .emoji("🍂"), .emoji("❄️"), .emoji("🏖️"),
                .emoji("🌺"), .emoji("🌷"), .emoji("🌹"), .emoji("🌼"), .emoji("🌾"), .emoji("🌿"),
                .emoji("☘️"), .emoji("🍀"), .emoji("🌵"), .emoji("🌴"), .emoji("🌳"), .emoji("🌲"),
                .system("tree.fill", .green), .system("cloud.sun.rain.fill", .blue)
             ]
        case .fruits:
             return [
                .emoji("🍎"), .emoji("🍌"), .emoji("🍇"), .emoji("🍓"), .emoji("🍑"), .emoji("🍉"), .emoji("🍍"),
                .emoji("🍔"), .emoji("🍕"), .emoji("🍦"), .emoji("🍺"), .emoji("☕️"),
                .emoji("🍊"), .emoji("🍋"), .emoji("🍐"), .emoji("🥝"), .emoji("🥑"), .emoji("🍅"),
                .emoji("🥕"), .emoji("🌽"), .emoji("🥒"), .emoji("🥦"), .emoji("🍆"), .emoji("🥔"),
                .emoji("🍞"), .emoji("🥐"), .emoji("🥖"), .emoji("🧀"), .emoji("🥚"), .emoji("🍳"),
                .emoji("🥓"), .emoji("🥩"), .emoji("🍗"), .emoji("🍖"), .emoji("🌭"), .emoji("🍟"),
                .emoji("🍿"), .emoji("🧂"), .emoji("🥗"), .emoji("🍝"), .emoji("🍜"), .emoji("🍲"),
                .emoji("🍱"), .emoji("🍛"), .emoji("🍣"), .emoji("🍤"), .emoji("🥟"), .emoji("🍥"),
                .emoji("🍡"), .emoji("🥠"), .emoji("🍧"), .emoji("🍨"), .emoji("🍩"), .emoji("🍪"),
                .emoji("🎂"), .emoji("🍰"), .emoji("🧁"), .emoji("🥧"), .emoji("🍫"), .emoji("🍬"),
                .emoji("🍭"), .emoji("🍮"), .emoji("🍯"), .emoji("🍼"), .emoji("🥛"), .emoji("🍵"),
                .emoji("🍶"), .emoji("🍾"), .emoji("🍷"), .emoji("🍸"), .emoji("🍹"), .emoji("🧃"),
                .emoji("🧉"), .emoji("🧊")
             ]
        }
    }
    
    struct StickerItem: Identifiable {
        let id = UUID()
        enum Kind {
            case system(String, Color)
            case emoji(String)
        }
        let kind: Kind
        
        static func system(_ name: String, _ color: Color = .black) -> StickerItem {
            .init(kind: .system(name, color))
        }
        
        static func emoji(_ char: String) -> StickerItem {
            .init(kind: .emoji(char))
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(StickerCategory.allCases, selection: $selectedCategory) { category in
                NavigationLink(value: category) {
                    Label(category.rawValue, systemImage: category.icon)
                }
            }
            .navigationTitle("贴纸库")
            
            VStack {
                Spacer()
                Button {
                    isImporting = true
                } label: {
                    Label("导入自定义贴纸...", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
            }
        } detail: {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                    ForEach(stickers) { sticker in
                        Button {
                            addSticker(sticker)
                            dismiss()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 80)
                                
                                switch sticker.kind {
                                case .system(let name, let color):
                                    Image(systemName: name)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(color)
                                case .emoji(let char):
                                    Text(char)
                                        .font(.system(size: 40))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle(selectedCategory.rawValue)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.image]) { result in
            switch result {
            case .success(let url):
                // Security scoped resource access
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                editorState.addStickerLayer(url: url, isLeftPage: isLeftPage)
                dismiss() // Import successful, close picker
            case .failure(let error):
                print("Import sticker failed: \(error.localizedDescription)")
            }
        }
    }

    func addSticker(_ item: StickerItem) {
        switch item.kind {
        case .system(let name, let color):
            editorState.addSystemSticker(name: name, colorHex: color.toHex(), isLeftPage: isLeftPage)
        case .emoji(let char):
            editorState.addEmojiSticker(emoji: char, isLeftPage: isLeftPage)
        }
    }
}


// MARK: - Sticker Picker Popover (Compact version for sidebar)

struct StickerPickerPopover: View {
    @Environment(EditorState.self) private var editorState
    
    let isLeftPage: Bool
    
    @State private var selectedCategory: StickerCategory = .favorites
    @State private var isImporting = false
    
    enum StickerCategory: String, CaseIterable, Identifiable {
        case favorites = "精选"
        case family = "家庭"
        case weather = "天气"
        case holiday = "节日"
        case seasons = "四季"
        case fruits = "食物"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .favorites: return "star.fill"
            case .family: return "figure.2.and.child.holdinghands"
            case .weather: return "cloud.sun.fill"
            case .holiday: return "gift.fill"
            case .seasons: return "leaf.fill"
            case .fruits: return "fork.knife"
            }
        }
    }
    
    // Data Source
    private var stickers: [StickerItem] {
        switch selectedCategory {
        case .favorites:
            return [
                .emoji("❤️"), .emoji("👍"), .system("star.fill", .yellow), .system("heart.fill", .red),
                .emoji("✨"), .emoji("💡"), .system("checkmark.seal.fill", .blue),
                .emoji("🎉"), .emoji("🌟"), .emoji("💖"), .emoji("🔥"), .emoji("💯"),
                .system("sparkles", .yellow), .system("flame.fill", .orange), .system("bolt.fill", .yellow)
            ]
        case .family:
            return [
                .system("house.fill", .blue), .system("car.fill", .gray), .system("figure.walk", .black),
                .emoji("👨‍👩‍👧‍👦"), .emoji("🏠"), .emoji("🚗"), .emoji("🐕"), .emoji("🐈"),
                .emoji("🚴"), .emoji("🥘"), .emoji("🧸"), .emoji("👶"), .emoji("👧"), .emoji("👦"),
                .emoji("🎒"), .emoji("📚"), .emoji("⚽️"), .emoji("🎮"), .emoji("🎨"),
                .system("figure.2.and.child.holdinghands", .blue), .system("pawprint.fill", .brown)
            ]
        case .weather:
             return [
                .system("sun.max.fill", .orange), .system("cloud.rain.fill", .blue), .system("cloud.snow.fill", .cyan),
                .system("bolt.fill", .yellow), .system("moon.stars.fill", .purple),
                .emoji("☀️"), .emoji("🌧️"), .emoji("❄️"), .emoji("🌈"), .emoji("⚡️"),
                .emoji("🌤️"), .emoji("⛅️"), .emoji("🌥️"), .emoji("☁️"), .emoji("🌦️"),
                .emoji("🌨️"), .emoji("⛈️"), .emoji("🌩️"), .emoji("🌪️"), .emoji("🌫️"),
                .system("cloud.sun.fill", .orange), .system("cloud.bolt.fill", .purple)
             ]
        case .holiday:
             return [
                .system("birthday.cake.fill", .pink), .system("gift.fill", .red),
                .emoji("🎂"), .emoji("🎄"), .emoji("🧧"), .emoji("🎃"), .emoji("🎆"), .emoji("💍"),
                .emoji("🎁"), .emoji("🎊"), .emoji("🎈"), .emoji("🎀"), .emoji("🎇"), .emoji("🎐"),
                .emoji("🎑"), .emoji("🎏"), .emoji("🎗️"), .emoji("🎟️"), .emoji("🎫"), .emoji("🎖️"),
                .emoji("🏆"), .emoji("🥇"), .emoji("🥈"), .emoji("🥉"),
                .system("party.popper.fill", .purple), .system("balloon.fill", .red)
             ]
        case .seasons:
             return [
                .system("leaf.fill", .green), .system("snowflake", .cyan), .system("sun.max.fill", .orange),
                .emoji("🌸"), .emoji("🌻"), .emoji("🍁"), .emoji("🍂"), .emoji("❄️"), .emoji("🏖️"),
                .emoji("🌺"), .emoji("🌷"), .emoji("🌹"), .emoji("🌼"), .emoji("🌾"), .emoji("🌿"),
                .emoji("☘️"), .emoji("🍀"), .emoji("🌵"), .emoji("🌴"), .emoji("🌳"), .emoji("🌲"),
                .system("tree.fill", .green), .system("cloud.sun.rain.fill", .blue)
             ]
        case .fruits:
             return [
                .emoji("🍎"), .emoji("🍌"), .emoji("🍇"), .emoji("🍓"), .emoji("🍑"), .emoji("🍉"), .emoji("🍍"),
                .emoji("🍔"), .emoji("🍕"), .emoji("🍦"), .emoji("🍺"), .emoji("☕️"),
                .emoji("🍊"), .emoji("🍋"), .emoji("🍐"), .emoji("🥝"), .emoji("🥑"), .emoji("🍅"),
                .emoji("🥕"), .emoji("🌽"), .emoji("🥒"), .emoji("🥦"), .emoji("🍆"), .emoji("🥔"),
                .emoji("🍞"), .emoji("🥐"), .emoji("🥖"), .emoji("🧀"), .emoji("🥚"), .emoji("🍳"),
                .emoji("🥓"), .emoji("🥩"), .emoji("🍗"), .emoji("🍖"), .emoji("🌭"), .emoji("🍟"),
                .emoji("🍿"), .emoji("🧂"), .emoji("🥗"), .emoji("🍝"), .emoji("🍜"), .emoji("🍲"),
                .emoji("🍱"), .emoji("🍛"), .emoji("🍣"), .emoji("🍤"), .emoji("🥟"), .emoji("🍥"),
                .emoji("🍡"), .emoji("🥠"), .emoji("🍧"), .emoji("🍨"), .emoji("🍩"), .emoji("🍪"),
                .emoji("🎂"), .emoji("🍰"), .emoji("🧁"), .emoji("🥧"), .emoji("🍫"), .emoji("🍬"),
                .emoji("🍭"), .emoji("🍮"), .emoji("🍯"), .emoji("🍼"), .emoji("🥛"), .emoji("🍵"),
                .emoji("🍶"), .emoji("🍾"), .emoji("🍷"), .emoji("🍸"), .emoji("🍹"), .emoji("🧃"),
                .emoji("🧉"), .emoji("🧊")
             ]
        }
    }
    
    struct StickerItem: Identifiable {
        let id = UUID()
        enum Kind {
            case system(String, Color)
            case emoji(String)
        }
        let kind: Kind
        
        static func system(_ name: String, _ color: Color = .black) -> StickerItem {
            .init(kind: .system(name, color))
        }
        
        static func emoji(_ char: String) -> StickerItem {
            .init(kind: .emoji(char))
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(StickerCategory.allCases) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 16))
                                Text(category.rawValue)
                                    .font(.system(size: 9))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(selectedCategory == category ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(selectedCategory == category ? .blue : .secondary)
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Sticker grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 8) {
                    ForEach(stickers) { sticker in
                        Button {
                            addSticker(sticker)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                
                                switch sticker.kind {
                                case .system(let name, let color):
                                    Image(systemName: name)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(color)
                                case .emoji(let char):
                                    Text(char)
                                        .font(.system(size: 28))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
            }
            
            Divider()
            
            // Import button
            Button {
                isImporting = true
            } label: {
                Label("导入自定义...", systemImage: "plus.circle")
                    .font(.caption)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(8)
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.image]) { result in
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                editorState.addStickerLayer(url: url, isLeftPage: isLeftPage)
            case .failure(let error):
                print("Import sticker failed: \(error.localizedDescription)")
            }
        }
    }

    func addSticker(_ item: StickerItem) {
        switch item.kind {
        case .system(let name, let color):
            editorState.addSystemSticker(name: name, colorHex: color.toHex(), isLeftPage: isLeftPage)
        case .emoji(let char):
            editorState.addEmojiSticker(emoji: char, isLeftPage: isLeftPage)
        }
    }
}
