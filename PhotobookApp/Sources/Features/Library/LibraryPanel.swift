import SwiftUI

struct LibraryPanel: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(EditorState.self) private var editorState
    @Environment(BookContext.self) private var bookContext
    @EnvironmentObject var photoStore: PhotoStore
    
    @State private var searchText = ""
    @State private var expandedMonths: Set<String> = []
    @State private var showSmartImport = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        photoLibraryContent
            .sheet(isPresented: $showSmartImport) {
                SmartImportView(isPresented: $showSmartImport)
                    .environment(editorState)
                    .environment(bookContext)
                    .environmentObject(photoStore)
            }
            .focused($isFocused)
            .onAppear { isFocused = true }
            .onKeyPress(keys: [.init("a")], phases: .down) { keyPress in
                if keyPress.modifiers.contains(.command) {
                    photoStore.selectAll()
                    return .handled
                }
                return .ignored
            }
    }

    var photoLibraryContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Library")
                    .font(.headline)
                    .foregroundColor(themeManager.theme.textColor)
                
                // Selection info
                if !photoStore.selectedPhotos.isEmpty {
                    Text("(\(photoStore.selectedPhotos.count) selected)")
                        .font(.caption)
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                    
                    Button("Clear") {
                        photoStore.clearSelection()
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(themeManager.theme.accentColor)
                }
                
                Spacer()
                
                // Smart Import Button
                Button(action: { showSmartImport = true }) {
                    Image(systemName: "brain")
                        .foregroundColor(themeManager.theme.accentColor)
                }
                .help("智能导入 / Smart Import")
                .buttonStyle(.plain)
                
                Button(action: { photoStore.showFolderPicker = true }) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(themeManager.theme.accentColor)
                }
                .help("Import Folder")
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
            
            HStack(spacing: 12) {
                Button("Import Photos") {
                    photoStore.showFolderPicker = true
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.theme.accentColor)
                
                Button {
                    showSmartImport = true
                } label: {
                    Label("智能导入", systemImage: "brain")
                }
                .buttonStyle(.bordered)
            }
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
    
    // Calculate aspect ratio from photo metadata
    private var photoAspectRatio: CGFloat {
        if let w = photo.width, let h = photo.height, w > 0, h > 0 {
            return CGFloat(w) / CGFloat(h)
        }
        return 1.0
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Use thumbnail image if available, otherwise async load
            if let thumbnail = photo.thumbnailImage {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 100, maxHeight: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            } else {
                AsyncImage(url: photo.url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(themeManager.theme.searchFieldColor)
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: 100, maxHeight: 100)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 100, maxHeight: 100)
                    case .failure:
                        ZStack {
                            Rectangle().fill(Color.red.opacity(0.1))
                            Image(systemName: "exclamationmark.triangle")
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: 100, maxHeight: 100)
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(themeManager.theme.accentColor)
                    .background(Circle().fill(Color.white))
                    .padding(4)
            }
        }
        .frame(minWidth: 60, minHeight: 60)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? themeManager.theme.accentColor : Color.clear, lineWidth: 3)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
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
            if let thumbnail = photo.thumbnailImage {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 60, maxHeight: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
            }
        }
    }
    
    private func handleTap() {
        let event = NSApp.currentEvent
        let modifiers = event?.modifierFlags ?? []
        
        var eventModifiers: EventModifiers = []
        if modifiers.contains(.command) {
            eventModifiers.insert(.command)
        }
        if modifiers.contains(.shift) {
            eventModifiers.insert(.shift)
        }
        
        photoStore.handlePhotoSelection(photo, modifiers: eventModifiers)
    }
}
