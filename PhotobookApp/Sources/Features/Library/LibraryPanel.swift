import SwiftUI

struct LibraryPanel: View {
    @Environment(\.undoManager) private var undoManager
    @Environment(LocalizationManager.self) private var localization
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
                    .environment(localization)
                    .environment(themeManager)
                    .environmentObject(photoStore)
            }
            .sheet(item: $previewPhoto) { photo in
                PhotoPreviewSheet(photo: photo, isPresented: Binding(
                    get: { previewPhoto != nil },
                    set: { if !$0 { previewPhoto = nil } }
                ))
                .environmentObject(photoStore)
                .environment(editorState)
                .environment(localization)
                .environment(themeManager)
            }
            .focused($isFocused)
            .focusable()
            .onAppear { isFocused = true }
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
            .overlay(
                ZStack {
                    Button("") {
                        photoStore.selectAll()
                    }
                    .keyboardShortcut("a", modifiers: .command)
                    
                    Button("") {
                        if !photoStore.selectedPhotos.isEmpty {
                            photoStore.deleteSelected(undoManager: undoManager)
                        }
                    }
                    .keyboardShortcut(.delete, modifiers: .command)
                }
                .opacity(0)
                .allowsHitTesting(false)
            )
        .environment(localization)


    }

    var photoLibraryContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(localization.localized(.library))
                    .font(.headline)
                    .foregroundColor(themeManager.theme.textColor)
                
                // Selection info
                if !photoStore.selectedPhotos.isEmpty {
                    Text(localization.localized(.selectedCount(photoStore.selectedPhotos.count)))
                        .font(.caption)
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                    
                    Button(localization.localized(.clearSelection)) {
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
                .help(localization.localized(.smartImport))
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.theme.secondaryTextColor)
                TextField(localization.localized(.searchPhotos), text: $searchText)
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
            Text(localization.localized(.noPhotos))
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            Text(localization.localized(.clickImportHelp))
                .font(.caption)
                .foregroundColor(themeManager.theme.secondaryTextColor)
            
            Button {
                showSmartImport = true
            } label: {
                HStack {
                    Image(systemName: "brain")
                    Text(localization.localized(.smartImport))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
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
    @Environment(\.undoManager) private var undoManager
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
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            thumbnailContent
            selectionOverlay
            statusIndicators
        }
        .frame(minWidth: 60, minHeight: 60)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { handleDoubleTap() }
        .onTapGesture { handleTap() }
        .focused($isFocused)
        .focusable()
        .onKeyPress(.space) {
            handleDoubleTap()
            return .handled
        }
        .contextMenu { contextMenuContent }
        .help(photo.filename)
        .draggable(photo.url) { dragPreview }
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let thumbnail = photo.thumbnailImage {
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 100, maxHeight: 100)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        } else {
            asyncImagePlaceholder
        }
    }

    private var asyncImagePlaceholder: some View {
        AsyncImage(url: photo.url) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(themeManager.theme.searchFieldColor)
                    .aspectRatio(1, contentMode: .fit)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            case .failure:
                ZStack {
                    Rectangle().fill(Color.red.opacity(0.1))
                    Image(systemName: "exclamationmark.triangle")
                }
                .aspectRatio(1, contentMode: .fit)
            @unknown default:
                EmptyView()
            }
        }
        .frame(maxWidth: 100, maxHeight: 100)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var selectionOverlay: some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(isSelected ? themeManager.theme.accentColor : (isUsed ? Color.green.opacity(0.5) : Color.clear), lineWidth: isSelected ? 3 : 2)
    }

    private var statusIndicators: some View {
        VStack(spacing: 4) {
            if isUsed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .background(Circle().fill(Color.white))
                    .padding(4)
            }
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(themeManager.theme.accentColor)
                    .background(Circle().fill(Color.white))
                    .padding(4)
            }
        }
        .padding(4)
    }

    @ViewBuilder
    private var dragPreview: some View {
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

    @ViewBuilder
    private var contextMenuContent: some View {
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
            photoStore.deleteSelected(undoManager: undoManager)
        } label: {
            Label(localization.localized(.delete), systemImage: "trash")
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
        previewPhoto = photo
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
            Color.black.opacity(0.95).ignoresSafeArea()
            
            VStack(spacing: 0) {
                previewHeader
                imageViewer
                previewFooter
            }
        }
        .frame(width: 900, height: 700)
        .overlay(scrollWheelOverlay)
        .focusable()
        .onKeyPress(.space) { isPresented = false; return .handled }
        .onKeyPress(keys: [.init("+"), .init("=")], phases: .down) { _ in zoom(delta: 0.25); return .handled }
        .onKeyPress(keys: [.init("-"), .init("_")], phases: .down) { _ in zoom(delta: -0.25); return .handled }
        .onKeyPress(keys: [.init("0")], phases: .down) { _ in resetZoom(); return .handled }
    }

    private var previewHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(photo.filename).font(.headline).foregroundColor(.white)
                
                HStack(spacing: 12) {
                    if let width = photo.width, let height = photo.height {
                        Text("\(width) × \(height)").font(.caption).foregroundColor(.white.opacity(0.7))
                    }
                    if let date = photo.dateTaken {
                        Text(date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundColor(.white.opacity(0.7))
                    }
                    if isUsed {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text(localization.localized(.used)).font(.caption).foregroundColor(.green)
                        }
                    }
                }
            }
            Spacer()
            zoomControls
            if isUsed, let usageIndex = photoStore.findPhotoUsage(photo, in: editorState) {
                usageButton(index: usageIndex)
            }
            closeButton
        }
        .padding()
        .background(Color.black.opacity(0.5))
    }

    private var zoomControls: some View {
        HStack(spacing: 16) {
            Button { zoom(delta: -0.25) } label: { Image(systemName: "minus.magnifyingglass").font(.title3).foregroundColor(.white) }.buttonStyle(.plain)
            Text("\(Int(imageScale * 100))%").font(.caption).foregroundColor(.white.opacity(0.7)).frame(width: 50)
            Button { zoom(delta: 0.25) } label: { Image(systemName: "plus.magnifyingglass").font(.title3).foregroundColor(.white) }.buttonStyle(.plain)
            Button { resetZoom() } label: { Image(systemName: "arrow.counterclockwise").font(.title3).foregroundColor(.white) }.buttonStyle(.plain)
        }
    }

    private func usageButton(index: Int) -> some View {
        Button { navigateToPhotoUsage(index); isPresented = false } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.right.circle.fill")
                if index == -1 { Text(localization.localized(.navigateToFrontCover)) }
                else if index == -2 { Text(localization.localized(.navigateToBackCover)) }
                else { Text(localization.localized(.navigateToSpread(index + 1))) }
            }
            .font(.caption).padding(.horizontal, 12).padding(.vertical, 6).background(Color.blue).foregroundColor(.white).cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var closeButton: some View {
        Button { isPresented = false } label: { Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.white.opacity(0.7)) }
        .buttonStyle(.plain).keyboardShortcut(.escape)
    }

    private var imageViewer: some View {
        GeometryReader { geometry in
            ZStack {
                if let thumbnail = photo.thumbnailImage {
                    Image(nsImage: thumbnail).resizable().aspectRatio(contentMode: .fit).scaleEffect(imageScale).offset(imageOffset)
                } else {
                    asyncImageArea
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var asyncImageArea: some View {
        AsyncImage(url: photo.url) { phase in
            switch phase {
            case .empty: ProgressView().tint(.white)
            case .success(let image): image.resizable().aspectRatio(contentMode: .fit).scaleEffect(imageScale).offset(imageOffset)
            case .failure: failureView
            @unknown default: EmptyView()
            }
        }
    }

    private var failureView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundColor(.white.opacity(0.5))
            Text("无法加载图片 / Failed to load image").foregroundColor(.white.opacity(0.7))
        }
    }

    private var previewFooter: some View {
        HStack {
            Text("提示 / Tips:").font(.caption).foregroundColor(.white.opacity(0.5))
            Text("空格键关闭 / Space to close").font(.caption).foregroundColor(.white.opacity(0.5))
            Text("•").foregroundColor(.white.opacity(0.3))
            Text("+/- 缩放 / +/- to zoom").font(.caption).foregroundColor(.white.opacity(0.5))
            Spacer()
        }
        .padding().background(Color.black.opacity(0.5))
    }

    private var scrollWheelOverlay: some View {
        ScrollWheelHandler { delta in
            withAnimation(.spring(response: 0.2)) {
                if delta.height > 0 { imageScale = min(4.0, imageScale + 0.1) }
                else if delta.height < 0 { imageScale = max(0.5, imageScale - 0.1) }
            }
        }.allowsHitTesting(true)
    }

    private func zoom(delta: CGFloat) { withAnimation(.spring(response: 0.3)) { imageScale = max(0.5, min(4.0, imageScale + delta)) } }
    private func resetZoom() { withAnimation(.spring(response: 0.3)) { imageScale = 1.0; imageOffset = .zero } }
    
    private func navigateToPhotoUsage(_ usageIndex: Int) {
        if usageIndex == -1 { editorState.navigateToFrontCover() }
        else if usageIndex == -2 { editorState.navigateToBackCover() }
        else { editorState.navigateToSpread(usageIndex) }
    }
}



// MARK: - Scroll Wheel Handler

struct ScrollWheelHandler: NSViewRepresentable {
    let onScroll: (CGSize) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = ScrollWheelView()
        view.onScroll = onScroll
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let scrollView = nsView as? ScrollWheelView {
            scrollView.onScroll = onScroll
        }
    }
    
    class ScrollWheelView: NSView {
        var onScroll: ((CGSize) -> Void)?
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            // Make sure the view can receive events
            self.wantsLayer = true
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func scrollWheel(with event: NSEvent) {
            // Handle scroll wheel events
            let delta = CGSize(width: event.scrollingDeltaX, height: event.scrollingDeltaY)
            onScroll?(delta)
            
            // Don't call super to prevent default scrolling behavior
        }
        
        override var acceptsFirstResponder: Bool { 
            return true 
        }
        
        override func becomeFirstResponder() -> Bool {
            return true
        }
        
        override func mouseDown(with event: NSEvent) {
            // Accept mouse events to become first responder
            window?.makeFirstResponder(self)
        }
    }
}
