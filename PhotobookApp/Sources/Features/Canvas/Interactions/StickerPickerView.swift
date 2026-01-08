import SwiftUI

struct StickerPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(EditorState.self) private var editorState
    @Environment(LocalizationManager.self) private var localization
    @State private var stickerManager = StickerManager()
    
    let isLeftPage: Bool
    
    @State private var selectedCategory: StickerCategory = .favorites
    @State private var isImporting = false
    
    enum StickerCategory: CaseIterable, Identifiable {
        case favorites
        case custom
        case family
        case weather
        case holiday
        case seasons
        case fruits
        
        var id: String { 
            switch self {
            case .favorites: return "favorites"
            case .custom: return "custom"
            case .family: return "family"
            case .weather: return "weather"
            case .holiday: return "holiday"
            case .seasons: return "seasons"
            case .fruits: return "fruits"
            }
        }
        
        func localizedName(_ localization: LocalizationManager) -> String {
            switch self {
            case .favorites: return localization.localized(.stickerFavorites)
            case .custom: return localization.localized(.stickerCustom)
            case .family: return localization.localized(.stickerFamily)
            case .weather: return localization.localized(.stickerWeather)
            case .holiday: return localization.localized(.stickerHoliday)
            case .seasons: return localization.localized(.stickerSeasons)
            case .fruits: return localization.localized(.stickerFruits)
            }
        }
        
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
        case .custom:
            return stickerManager.customStickers.map { .url($0.url, $0.name) }
        case .favorites:
            // Show user's favorite stickers
            return stickerManager.favoriteStickers.compactMap { favorite in
                switch favorite.type {
                case .emoji(let char):
                    return .emoji(char)
                case .system(let name, let colorHex):
                    return .system(name, Color(hex: colorHex))
                case .url(let urlString):
                    if let url = URL(string: urlString) {
                        return .url(url, url.lastPathComponent)
                    }
                    return nil
                }
            }
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
            case url(URL, String)
            case system(String, Color)
            case emoji(String)
        }
        let kind: Kind
        
        static func url(_ url: URL, _ name: String) -> StickerItem {
            .init(kind: .url(url, name))
        }
        
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
                    Label(category.localizedName(localization), systemImage: category.icon)
                }
            }
            .navigationTitle(localization.localized(.stickerLibrary))
            
            VStack {
                Spacer()
                
                // Open Stickers Folder button (only show in custom category)
                if selectedCategory == .custom {
                    Button {
                        stickerManager.openStickersFolder()
                    } label: {
                        Label(localization.localized(.openStickersFolder), systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                Button {
                    isImporting = true
                } label: {
                    Label(localization.localized(.importCustomSticker), systemImage: "plus.circle")
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
                        ZStack(alignment: .topTrailing) {
                            // Main sticker button
                            Button {
                                addSticker(sticker)
                                dismiss()
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(height: 80)
                                    
                                    switch sticker.kind {
                                    case .url(let url, _):
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 60, height: 60)
                                            case .failure(_):
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                            case .empty:
                                                ProgressView()
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
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
                            
                            // Favorite button (only show when not in favorites or custom category)
                            if selectedCategory != .favorites && selectedCategory != .custom {
                                Button {
                                    toggleFavorite(sticker)
                                } label: {
                                    Image(systemName: isFavorite(sticker) ? "star.fill" : "star")
                                        .font(.system(size: 12))
                                        .foregroundColor(isFavorite(sticker) ? .yellow : .gray)
                                        .padding(4)
                                        .background(Color.white.opacity(0.9))
                                        .clipShape(Circle())
                                        .shadow(radius: 2)
                                }
                                .buttonStyle(.plain)
                                .padding(4)
                            }
                            
                            // Remove from favorites button (only in favorites category)
                            if selectedCategory == .favorites {
                                Button {
                                    removeFromFavorites(sticker)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                        .padding(4)
                                }
                                .buttonStyle(.plain)
                                .padding(4)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(selectedCategory.localizedName(localization))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(localization.localized(.done)) {
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
        .onAppear {
            // Reload custom stickers when view appears
            stickerManager.loadCustomStickers()
        }
    }

    func addSticker(_ item: StickerItem) {
        switch item.kind {
        case .url(let url, _):
            editorState.addStickerLayer(url: url, isLeftPage: isLeftPage)
        case .system(let name, let color):
            editorState.addSystemSticker(name: name, colorHex: color.toHex(), isLeftPage: isLeftPage)
        case .emoji(let char):
            editorState.addEmojiSticker(emoji: char, isLeftPage: isLeftPage)
        }
    }
    
    // MARK: - Favorites Management
    
    private func toggleFavorite(_ item: StickerItem) {
        let stickerId = getStickerID(item)
        
        if stickerManager.isFavorite(stickerId) {
            stickerManager.removeFromFavorites(stickerId)
        } else {
            let favorite = FavoriteSticker(
                id: stickerId,
                type: getFavoriteType(item)
            )
            stickerManager.addToFavorites(favorite)
        }
    }
    
    private func removeFromFavorites(_ item: StickerItem) {
        let stickerId = getStickerID(item)
        stickerManager.removeFromFavorites(stickerId)
    }
    
    private func isFavorite(_ item: StickerItem) -> Bool {
        let stickerId = getStickerID(item)
        return stickerManager.isFavorite(stickerId)
    }
    
    private func getStickerID(_ item: StickerItem) -> String {
        switch item.kind {
        case .emoji(let char):
            return "emoji_\(char)"
        case .system(let name, let color):
            return "system_\(name)_\(color.toHex())"
        case .url(let url, _):
            return "url_\(url.absoluteString)"
        }
    }
    
    private func getFavoriteType(_ item: StickerItem) -> FavoriteSticker.StickerType {
        switch item.kind {
        case .emoji(let char):
            return .emoji(char)
        case .system(let name, let color):
            return .system(name, color.toHex())
        case .url(let url, _):
            return .url(url.absoluteString)
        }
    }
}


// MARK: - Sticker Picker Popover (Compact version for sidebar)

struct StickerPickerPopover: View {
    @Environment(EditorState.self) private var editorState
    @Environment(LocalizationManager.self) private var localization
    @State private var stickerManager = StickerManager()
    
    let isLeftPage: Bool
    
    @State private var selectedCategory: StickerCategory = .favorites
    @State private var isImporting = false
    
    enum StickerCategory: CaseIterable, Identifiable {
        case favorites
        case family
        case weather
        case holiday
        case seasons
        case fruits
        
        var id: String {
            switch self {
            case .favorites: return "favorites"
            case .family: return "family"
            case .weather: return "weather"
            case .holiday: return "holiday"
            case .seasons: return "seasons"
            case .fruits: return "fruits"
            }
        }
        
        func localizedName(_ localization: LocalizationManager) -> String {
            switch self {
            case .favorites: return localization.localized(.stickerFavorites)
            case .family: return localization.localized(.stickerFamily)
            case .weather: return localization.localized(.stickerWeather)
            case .holiday: return localization.localized(.stickerHoliday)
            case .seasons: return localization.localized(.stickerSeasons)
            case .fruits: return localization.localized(.stickerFruits)
            }
        }
        
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
            // Show user's favorite stickers
            return stickerManager.favoriteStickers.compactMap { favorite in
                switch favorite.type {
                case .emoji(let char):
                    return .emoji(char)
                case .system(let name, let colorHex):
                    return .system(name, Color(hex: colorHex))
                case .url(let urlString):
                    if let url = URL(string: urlString) {
                        return .url(url, url.lastPathComponent)
                    }
                    return nil
                }
            }
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
            case url(URL, String)
            case system(String, Color)
            case emoji(String)
        }
        let kind: Kind
        
        static func url(_ url: URL, _ name: String) -> StickerItem {
            .init(kind: .url(url, name))
        }
        
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
                HStack(spacing: 6) {
                    ForEach(StickerCategory.allCases) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 18))
                                Text(category.localizedName(localization))
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
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
                        ZStack(alignment: .topTrailing) {
                            // Main sticker button
                            Button {
                                addSticker(sticker)
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    
                                    switch sticker.kind {
                                    case .url(let url, _):
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 40, height: 40)
                                            case .failure(_):
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                            case .empty:
                                                ProgressView()
                                                    .scaleEffect(0.5)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
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
                            
                            // Favorite button (only show when not in favorites category)
                            if selectedCategory != .favorites {
                                Button {
                                    toggleFavorite(sticker)
                                } label: {
                                    Image(systemName: isFavorite(sticker) ? "star.fill" : "star")
                                        .font(.system(size: 10))
                                        .foregroundColor(isFavorite(sticker) ? .yellow : .gray)
                                        .padding(2)
                                        .background(Color.white.opacity(0.9))
                                        .clipShape(Circle())
                                        .shadow(radius: 1)
                                }
                                .buttonStyle(.plain)
                                .padding(2)
                            }
                            
                            // Remove from favorites button (only in favorites category)
                            if selectedCategory == .favorites {
                                Button {
                                    removeFromFavorites(sticker)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                        .padding(2)
                                }
                                .buttonStyle(.plain)
                                .padding(2)
                            }
                        }
                    }
                }
                .padding(8)
            }
            
            Divider()
            
            // Import button
            Button {
                isImporting = true
            } label: {
                Label(localization.localized(.importCustomSticker), systemImage: "plus.circle")
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
        .onAppear {
            // Reload favorites when view appears
            stickerManager.loadFavorites()
        }
    }

    func addSticker(_ item: StickerItem) {
        switch item.kind {
        case .url(let url, _):
            editorState.addStickerLayer(url: url, isLeftPage: isLeftPage)
        case .system(let name, let color):
            editorState.addSystemSticker(name: name, colorHex: color.toHex(), isLeftPage: isLeftPage)
        case .emoji(let char):
            editorState.addEmojiSticker(emoji: char, isLeftPage: isLeftPage)
        }
    }
    
    // MARK: - Favorites Management
    
    private func toggleFavorite(_ item: StickerItem) {
        let stickerId = getStickerID(item)
        
        if stickerManager.isFavorite(stickerId) {
            stickerManager.removeFromFavorites(stickerId)
        } else {
            let favorite = FavoriteSticker(
                id: stickerId,
                type: getFavoriteType(item)
            )
            stickerManager.addToFavorites(favorite)
        }
    }
    
    private func removeFromFavorites(_ item: StickerItem) {
        let stickerId = getStickerID(item)
        stickerManager.removeFromFavorites(stickerId)
    }
    
    private func isFavorite(_ item: StickerItem) -> Bool {
        let stickerId = getStickerID(item)
        return stickerManager.isFavorite(stickerId)
    }
    
    private func getStickerID(_ item: StickerItem) -> String {
        switch item.kind {
        case .emoji(let char):
            return "emoji_\(char)"
        case .system(let name, let color):
            return "system_\(name)_\(color.toHex())"
        case .url(let url, _):
            return "url_\(url.absoluteString)"
        }
    }
    
    private func getFavoriteType(_ item: StickerItem) -> FavoriteSticker.StickerType {
        switch item.kind {
        case .emoji(let char):
            return .emoji(char)
        case .system(let name, let color):
            return .system(name, color.toHex())
        case .url(let url, _):
            return .url(url.absoluteString)
        }
    }
}
