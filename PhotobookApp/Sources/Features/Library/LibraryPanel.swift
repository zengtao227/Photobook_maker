import SwiftUI

struct LibraryPanel: View {
    @Environment(ThemeManager.self) private var themeManager
    @EnvironmentObject var photoStore: PhotoStore // Connect to real data
    
    // Restored missing state variables
    @State private var searchText = ""
    @State private var expandedMonths: Set<String> = []
    
    var body: some View {
        photoLibraryContent
    }

    var photoLibraryContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Library")
                    .font(.headline)
                    .foregroundColor(themeManager.theme.textColor)
                Spacer()
                Button(action: { photoStore.showFolderPicker = true }) {
                    Image(systemName: "folder.badge.plus") // Changed icon to folder
                        .foregroundColor(themeManager.theme.accentColor)
                }
                .help("Import Folder") // Tooltip clarification
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.theme.secondaryTextColor)
                TextField("Search photos...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(themeManager.theme.textColor)
            }
            .padding(8)
            .background(themeManager.theme.searchFieldColor)
            .cornerRadius(themeManager.theme.cornerRadius)
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Content
            if photoStore.monthGroups.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(photoStore.monthGroups, id: \.month) { group in
                            MonthGroupView(group: group)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.largeTitle)
                .foregroundColor(themeManager.theme.secondaryTextColor)
            Text("No Photos")
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            Text("Click + to import a folder")
                .font(.caption)
                .foregroundColor(themeManager.theme.secondaryTextColor)
            Button("Import Photos") {
                photoStore.showFolderPicker = true
            }
            .buttonStyle(.borderedProminent)
            .tint(themeManager.theme.accentColor)
            .padding(.top)
            Spacer()
        }
    }
}

struct MonthGroupView: View {
    let group: MonthGroup
    @Environment(ThemeManager.self) private var themeManager
    @EnvironmentObject var photoStore: PhotoStore
    
    let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 8)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month Header
            HStack {
                Text(group.month)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.theme.textColor)
                Spacer()
                Text("\(group.photos.count)")
                    .font(.caption)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(themeManager.theme.secondaryAccentColor.opacity(0.2))
                    .cornerRadius(4)
            }
            
            // Photo Grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(group.photos) { photo in
                    PhotoThumnailView(photo: photo)
                }
            }
        }
    }
}

struct PhotoThumnailView: View {
    let photo: Photo
    @Environment(ThemeManager.self) private var themeManager
    @EnvironmentObject var photoStore: PhotoStore
    
    var isSelected: Bool {
        photoStore.selectedPhotos.contains(where: { $0.id == photo.id })
    }
    
    // Calculate aspect ratio from metadata
    var aspectRatio: CGFloat {
        if let w = photo.width, let h = photo.height, w > 0, h > 0 {
            return CGFloat(w) / CGFloat(h)
        }
        return 1.0
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Use thumbnail image if available, otherwise async load
            if let thumbnail = photo.thumbnailImage {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            } else {
                AsyncImage(url: photo.url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle().fill(themeManager.theme.searchFieldColor)
                    case .success(let image):
                        image.resizable().aspectRatio(aspectRatio, contentMode: .fit)
                    case .failure:
                        Rectangle().fill(Color.red.opacity(0.1))
                        Image(systemName: "exclamationmark.triangle")
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .frame(minHeight: 60) // Minimum height for very wide images
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? themeManager.theme.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            photoStore.toggleSelection(photo)
        }
        // Right-click context menu
        .contextMenu {
            Button(role: .destructive) {
                photoStore.deletePhoto(photo)
            } label: {
                Label("Delete from Library", systemImage: "trash")
            }
        }
        // Drag Support
        .draggable(photo.url) {
            Image(nsImage: photo.thumbnailImage ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}
