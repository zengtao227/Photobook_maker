import SwiftUI

struct LibraryPanel: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(EditorState.self) private var editorState
    @Environment(BookContext.self) private var bookContext
    @EnvironmentObject var photoStore: PhotoStore
    
    @State private var searchText = ""
    @State private var expandedMonths: Set<String> = []
    @State private var showSmartImport = false
    @State private var previewPhoto: Photo? = nil // For photo preview
    @FocusState private var isFocused: Bool
    
    var body: some View {
        photoLibraryContent
            .sheet(isPresented: $showSmartImport) {
                SmartImportView(isPresented: $showSmartImport)
                    .environment(editorState)
                    .environment(bookContext)
                    .environmentObject(photoStore)
            }
            .sheet(item: $previewPhoto) { photo in
                PhotoPreviewSheet(photo: photo, isPresented: Binding(
                    get: { previewPhoto != nil },
                    set: { if !$0 { previewPhoto = nil } }
                ))
                .environmentObject(photoStore)
                .environment(editorState)
            }
            .focused($isFocused)
            .focusable()
            .onAppear { isFocused = true }
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
            .background(
                Button("") {
                    photoStore.selectAll()
                }
                .keyboardShortcut("a", modifiers: .command)
                .opacity(0)
            )
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
                
                // Smart Import Button (replaces both folder and library import)
                Button(action: { showSmartImport = true }) {
                    Image(systemName: "brain")
                        .foregroundColor(themeManager.theme.accentColor)
                }
                .help("智能导入 / Smart Import")
                .buttonStyle(.plain)
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
                            MonthGroupView(group: group, previewPhoto: $previewPhoto)
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
    @Binding var previewPhoto: Photo?
    
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
                    PhotoThumnailView(photo: photo, previewPhoto: $previewPhoto)
                }
            }
        }
    }
}

struct PhotoThumnailView: View {
    let photo: Photo
    @Binding var previewPhoto: Photo?
    @Environment(ThemeManager.self) private var themeManager
    @Environment(EditorState.self) private var editorState
    @Environment(LocalizationManager.self) private var localization
    @EnvironmentObject var photoStore: PhotoStore
    @FocusState private var isFocused: Bool
    
    var isSelected: Bool {
        photoStore.selectedPhotos.contains(where: { $0.id == photo.id })
    }
    
    var isUsed: Bool {
        photoStore.isPhotoUsed(photo, in: editorState)
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
            
            // Used indicator (top-right corner)
            if isUsed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .background(Circle().fill(Color.white))
                    .padding(4)
            }
            
            // Selection indicator (top-right, below used indicator if both present)
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(themeManager.theme.accentColor)
                    .background(Circle().fill(Color.white))
                    .padding(4)
                    .offset(y: isUsed ? 20 : 0)
            }
        }
        .frame(minWidth: 60, minHeight: 60)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? themeManager.theme.accentColor : (isUsed ? Color.green.opacity(0.5) : Color.clear), lineWidth: isSelected ? 3 : 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
        // Double-click to navigate and edit
        .onTapGesture(count: 2) {
            handleDoubleTap()
        }
        .focused($isFocused)
        .focusable()
        .onKeyPress(.space) {
            handleDoubleTap()
            return .handled
        }
        // Right-click context menu
        .contextMenu {
            // Navigate to photo usage (if photo is used)
            if isUsed, let usageIndex = photoStore.findPhotoUsage(photo, in: editorState) {
                Button {
                    navigateToPhotoUsage(usageIndex)
                } label: {
                    if usageIndex == -1 {
                        Label(localization.localized(.navigateToFrontCover), systemImage: "arrow.right.circle")
                    } else if usageIndex == -2 {
                        Label(localization.localized(.navigateToBackCover), systemImage: "arrow.right.circle")
                    } else {
                        Label(localization.localized(.navigateToSpread(usageIndex + 1)), systemImage: "arrow.right.circle")
                    }
                }
                
                Divider()
            }
            
            Button(role: .destructive) {
                photoStore.deletePhoto(photo)
            } label: {
                Label(localization.localized(.delete), systemImage: "trash")
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
    
    private func handleDoubleTap() {
        // Show photo preview
        previewPhoto = photo
    }
    
    private func navigateToPhotoUsage(_ usageIndex: Int) {
        if usageIndex == -1 {
            // Navigate to front cover
            editorState.navigateToFrontCover()
        } else if usageIndex == -2 {
            // Navigate to back cover
            editorState.navigateToBackCover()
        } else {
            // Navigate to inner spread
            editorState.navigateToSpread(usageIndex)
        }
    }
}


// MARK: - Photo Preview Sheet

struct PhotoPreviewSheet: View {
    let photo: Photo
    @Binding var isPresented: Bool
    @EnvironmentObject var photoStore: PhotoStore
    @Environment(EditorState.self) private var editorState
    @Environment(LocalizationManager.self) private var localization
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var lastDragValue: CGSize = .zero
    
    var isUsed: Bool {
        photoStore.isPhotoUsed(photo, in: editorState)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(photo.filename)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            if let width = photo.width, let height = photo.height {
                                Text("\(width) × \(height)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            if let date = photo.dateTaken {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            if isUsed {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("已使用 / Used")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Zoom controls
                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                imageScale = max(0.5, imageScale - 0.25)
                            }
                        } label: {
                            Image(systemName: "minus.magnifyingglass")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .help("缩小 / Zoom Out")
                        
                        Text("\(Int(imageScale * 100))%")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 50)
                        
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                imageScale = min(4.0, imageScale + 0.25)
                            }
                        } label: {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .help("放大 / Zoom In")
                        
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                imageScale = 1.0
                                imageOffset = .zero
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .help("重置 / Reset")
                    }
                    
                    // Navigate to usage button (if used)
                    if isUsed, let usageIndex = photoStore.findPhotoUsage(photo, in: editorState) {
                        Button {
                            navigateToPhotoUsage(usageIndex)
                            isPresented = false
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.right.circle.fill")
                                if usageIndex == -1 {
                                    Text(localization.localized(.navigateToFrontCover))
                                } else if usageIndex == -2 {
                                    Text(localization.localized(.navigateToBackCover))
                                } else {
                                    Text(localization.localized(.navigateToSpread(usageIndex + 1)))
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Close button
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape)
                }
                .padding()
                .background(Color.black.opacity(0.5))
                
                // Image viewer
                GeometryReader { geometry in
                    ZStack {
                        if let thumbnail = photo.thumbnailImage {
                            Image(nsImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(imageScale)
                                .offset(imageOffset)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            imageOffset = CGSize(
                                                width: lastDragValue.width + value.translation.width,
                                                height: lastDragValue.height + value.translation.height
                                            )
                                        }
                                        .onEnded { _ in
                                            lastDragValue = imageOffset
                                        }
                                )
                        } else {
                            AsyncImage(url: photo.url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .tint(.white)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .scaleEffect(imageScale)
                                        .offset(imageOffset)
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    imageOffset = CGSize(
                                                        width: lastDragValue.width + value.translation.width,
                                                        height: lastDragValue.height + value.translation.height
                                                    )
                                                }
                                                .onEnded { _ in
                                                    lastDragValue = imageOffset
                                                }
                                        )
                                case .failure:
                                    VStack(spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.largeTitle)
                                            .foregroundColor(.white.opacity(0.5))
                                        Text("无法加载图片 / Failed to load image")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Footer with hints
                HStack {
                    Text("提示 / Tips:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("双击或空格键预览 / Double-click or Space to preview")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("拖动移动 / Drag to pan")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("ESC 关闭 / ESC to close")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(0.5))
            }
        }
        .frame(width: 900, height: 700)
        .onKeyPress(.space) {
            isPresented = false
            return .handled
        }
        .onKeyPress(keys: [.init("+"), .init("=")], phases: .down) { _ in
            withAnimation(.spring(response: 0.3)) {
                imageScale = min(4.0, imageScale + 0.25)
            }
            return .handled
        }
        .onKeyPress(keys: [.init("-"), .init("_")], phases: .down) { _ in
            withAnimation(.spring(response: 0.3)) {
                imageScale = max(0.5, imageScale - 0.25)
            }
            return .handled
        }
        .onKeyPress(keys: [.init("0")], phases: .down) { _ in
            withAnimation(.spring(response: 0.3)) {
                imageScale = 1.0
                imageOffset = .zero
            }
            return .handled
        }
    }
    
    private func navigateToPhotoUsage(_ usageIndex: Int) {
        if usageIndex == -1 {
            editorState.navigateToFrontCover()
        } else if usageIndex == -2 {
            editorState.navigateToBackCover()
        } else {
            editorState.navigateToSpread(usageIndex)
        }
    }
}
