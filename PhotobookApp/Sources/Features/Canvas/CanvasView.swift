import SwiftUI

// MARK: - Main Canvas View
// This file has been refactored - components are now in Components/ folder

struct CanvasView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(BookContext.self) private var bookContext
    @Environment(EditorState.self) private var editorState
    @Environment(LocalizationManager.self) private var localization
    @FocusState private var isCanvasFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                canvasBackground
                
                VStack(spacing: 20) {
                    headerInfo
                    spreadContent
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .focused($isCanvasFocused)
        .onAppear { isCanvasFocused = true }
        .onTapGesture { isCanvasFocused = true }
    }
    
    @ViewBuilder
    private var canvasBackground: some View {
        if themeManager.currentMode == .studio {
            Color(white: 0.95)
        } else {
            Color.clear
        }
    }
    
    private var headerInfo: some View {
        VStack(spacing: 4) {
            Text("Current Spread")
                .font(.headline)
                .foregroundColor(themeManager.theme.secondaryTextColor)
            Text("\(bookContext.pageSize.rawValue) • \(bookContext.dimensionString)")
                .font(.caption)
                .padding(6)
                .background(themeManager.theme.searchFieldColor)
                .cornerRadius(4)
                .foregroundColor(themeManager.theme.textColor)
        }
    }
    
    @ViewBuilder
    private var spreadContent: some View {
        let singlePageSize = bookContext.currentSize
        let spreadAspectRatio = calculateSpreadAspectRatio(singlePageSize: singlePageSize)
        
        ZStack {
            Color.clear
                .aspectRatio(spreadAspectRatio, contentMode: .fit)
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            
            spreadLayout(singlePageSize: singlePageSize, spreadAspectRatio: spreadAspectRatio)
        }
        .padding(40)
    }
    
    private func calculateSpreadAspectRatio(singlePageSize: CGSize) -> CGFloat {
        switch editorState.currentTarget {
        case .frontCover, .backCover:
            return singlePageSize.width / singlePageSize.height
        case .innerSpread, .fullCoverWrap:
            return (singlePageSize.width * 2) / singlePageSize.height
        }
    }
    
    @ViewBuilder
    private func spreadLayout(singlePageSize: CGSize, spreadAspectRatio: CGFloat) -> some View {
        switch editorState.currentTarget {
        case .innerSpread(let index):
            innerSpreadLayout(index: index, singlePageSize: singlePageSize, spreadAspectRatio: spreadAspectRatio)
        case .frontCover:
            BookPage(isLeft: true, size: singlePageSize)
                .aspectRatio(spreadAspectRatio, contentMode: .fit)
        case .backCover:
            BookPage(isLeft: false, size: singlePageSize)
                .aspectRatio(spreadAspectRatio, contentMode: .fit)
        case .fullCoverWrap:
            fullCoverWrapLayout(singlePageSize: singlePageSize, spreadAspectRatio: spreadAspectRatio)
        }
    }
    
    @ViewBuilder
    private func innerSpreadLayout(index: Int, singlePageSize: CGSize, spreadAspectRatio: CGFloat) -> some View {
        let isFirstSpread = (index == 0)
        let isLastSpread = (index == editorState.spreadCount - 1)
        
        if isFirstSpread {
            firstSpreadLayout(singlePageSize: singlePageSize)
        } else if isLastSpread {
            lastSpreadLayout(singlePageSize: singlePageSize)
        } else {
            normalSpreadLayout(singlePageSize: singlePageSize, spreadAspectRatio: spreadAspectRatio)
        }
    }
    
    private func firstSpreadLayout(singlePageSize: CGSize) -> some View {
        HStack(spacing: 0) {
            placeholderPage(title: localization.currentLanguage == .chinese ? "封面背面" : "Cover Back", singlePageSize: singlePageSize)
            spineView
            BookPage(isLeft: false, size: singlePageSize)
                .aspectRatio(singlePageSize.width / singlePageSize.height, contentMode: .fit)
        }
    }
    
    private func lastSpreadLayout(singlePageSize: CGSize) -> some View {
        HStack(spacing: 0) {
            BookPage(isLeft: true, size: singlePageSize)
                .aspectRatio(singlePageSize.width / singlePageSize.height, contentMode: .fit)
            spineView
            placeholderPage(title: localization.currentLanguage == .chinese ? "封底背面" : "Back Cover Back", singlePageSize: singlePageSize)
        }
    }
    
    private func normalSpreadLayout(singlePageSize: CGSize, spreadAspectRatio: CGFloat) -> some View {
        HStack(spacing: 0) {
            BookPage(isLeft: true, size: singlePageSize)
            spineView
            BookPage(isLeft: false, size: singlePageSize)
        }
        .aspectRatio(spreadAspectRatio, contentMode: .fit)
    }
    
    private func fullCoverWrapLayout(singlePageSize: CGSize, spreadAspectRatio: CGFloat) -> some View {
        HStack(spacing: 0) {
            BookPage(isLeft: true, size: singlePageSize)
            spineView
            BookPage(isLeft: false, size: singlePageSize)
        }
        .aspectRatio(spreadAspectRatio, contentMode: .fit)
    }
    
    private var spineView: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [.black.opacity(0.2), .black.opacity(0.05), .black.opacity(0.2)],
                startPoint: .leading,
                endPoint: .trailing
            ))
            .frame(width: 3)
            .zIndex(1000)
    }
    
    private func placeholderPage(title: String, singlePageSize: CGSize) -> some View {
        ZStack {
            Rectangle().fill(Color.white)
            VStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .font(.system(size: 48))
                    .foregroundColor(Color.gray.opacity(0.2))
                Text(title)
                    .font(.title3)
                    .foregroundColor(Color.gray.opacity(0.3))
                Text(localization.currentLanguage == .chinese ? "(不可编辑)" : "(Non-editable)")
                    .font(.caption)
                    .foregroundColor(Color.gray.opacity(0.3))
            }
        }
        .aspectRatio(singlePageSize.width / singlePageSize.height, contentMode: .fit)
    }
}

// MARK: - Book Page View

struct BookPage: View {
    let isLeft: Bool
    let size: CGSize
    @Environment(ThemeManager.self) private var themeManager
    @Environment(EditorState.self) private var editorState
    @Environment(BookContext.self) private var bookContext
    @EnvironmentObject var photoStore: PhotoStore
    
    var pageModel: PageModel {
        isLeft ? editorState.leftPage : editorState.rightPage
    }
    
    var body: some View {
        GeometryReader { geometry in
            let logicalSize = bookContext.logicalPageSizeInPoints
            let displaySize = geometry.size
            let scale = displaySize.width / logicalSize.width
            
            ZStack(alignment: .topLeading) {
                backgroundLayer
                layersView(scale: scale, logicalSize: logicalSize)
                tapToDeselectLayer
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay(bleedOverlay(scale: scale))
            .contextMenu {
                pageContextMenu
            }
            .focusable()
            .onKeyPress(.delete) { handleDelete() }
            .onKeyPress(.deleteForward) { handleDelete() }
            .sheet(item: cropBinding) { wrapper in cropSheet(wrapper: wrapper) }
            .sheet(item: filterBinding) { wrapper in filterSheet(wrapper: wrapper) }
            .dropDestination(for: URL.self) { items, location in
                handleDrop(items: items, location: location, scale: scale)
            }
        }
    }
    
    // MARK: - Background
    @ViewBuilder
    private var backgroundLayer: some View {
        ZStack {
            backgroundView
            
            if pageModel.pageNumber == -98 || pageModel.pageNumber == -99 {
                placeholderView
            } else {
                GridPattern()
                    .stroke(Color.blue.opacity(0.1), lineWidth: 0.5)
            }
            
            bindingShadow
        }
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch pageModel.backgroundType {
        case .solid:
            Rectangle().fill(Color(hex: pageModel.backgroundColorHex))
        case .gradient:
            if let colors = pageModel.gradientColors, !colors.isEmpty {
                LinearGradient(colors: colors.map { Color(hex: $0) }, startPoint: .topLeading, endPoint: .bottomTrailing)
            } else {
                Rectangle().fill(Color(hex: pageModel.backgroundColorHex))
            }
        case .pattern:
            ZStack {
                Rectangle().fill(Color(hex: pageModel.backgroundColorHex))
                if let patternType = pageModel.patternType { patternView(for: patternType) }
            }
        case .texture:
            ZStack {
                Rectangle().fill(Color(hex: pageModel.backgroundColorHex))
                if let textureType = pageModel.textureType { textureView(for: textureType) }
            }
        }
    }
    
    @ViewBuilder
    private func patternView(for type: String) -> some View {
        switch type {
        case "dots": DotsPattern()
        case "stripes": StripesPattern()
        case "grid": GridPattern().stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        case "diagonal": DiagonalPattern()
        case "hearts": HeartsPattern()
        case "stars": StarsPattern()
        default: EmptyView()
        }
    }
    
    @ViewBuilder
    private func textureView(for type: String) -> some View {
        switch type {
        case "paper": DotsPattern().opacity(0.1)
        case "fabric": DiagonalPattern().opacity(0.15)
        case "wood": StripesPattern().opacity(0.2)
        case "marble": GridPattern().stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        default: EmptyView()
        }
    }
    
    private var placeholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(Color.gray.opacity(0.2))
            Text("内页")
                .font(.title3)
                .foregroundColor(Color.gray.opacity(0.3))
            Text("(不可编辑)")
                .font(.caption)
                .foregroundColor(Color.gray.opacity(0.3))
        }
    }
    
    private var bindingShadow: some View {
        HStack {
            if pageModel.pageNumber == 0 {
                LinearGradient(colors: [.black.opacity(0.15), .clear], startPoint: .leading, endPoint: .trailing).frame(width: 20)
                Spacer()
            } else if pageModel.pageNumber == -1 {
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.15)], startPoint: .leading, endPoint: .trailing).frame(width: 20)
            } else if !isLeft {
                LinearGradient(colors: [.black.opacity(0.15), .clear], startPoint: .leading, endPoint: .trailing).frame(width: 20)
                Spacer()
            } else {
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.15)], startPoint: .leading, endPoint: .trailing).frame(width: 20)
            }
        }
    }
    
    // MARK: - Layers
    @ViewBuilder
    private func layersView(scale: CGFloat, logicalSize: CGSize) -> some View {
        ForEach(pageModel.layers) { wrapper in
            InteractiveLayer(wrapper: wrapper, isLeftPage: isLeft, scale: scale, logicalPageSize: logicalSize)
                .zIndex(1000)
        }
    }
    
    // MARK: - Bleed Overlay
    @ViewBuilder
    private func bleedOverlay(scale: CGFloat) -> some View {
        if editorState.showBleedGuide && pageModel.pageNumber >= -1 {
            let bleedInset = editorState.bleedPoints * scale
            
            Rectangle()
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .foregroundColor(.red.opacity(0.6))
                .padding(bleedInset)
            
            VStack {
                HStack {
                    Text("BLEED: \(String(format: "%.1f", editorState.bleedMM))mm")
                        .font(.system(size: 8))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(2)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(2)
                    Spacer()
                }
                Spacer()
            }
            .padding(bleedInset + 4)
        }
    }
    
    // MARK: - Tap to Deselect
    private var tapToDeselectLayer: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture { editorState.deselect() }
            .allowsHitTesting(true)
            .zIndex(-1)
    }
    
    // MARK: - Bindings
    private var cropBinding: Binding<AnyLayer?> {
        Binding(
            get: {
                guard let id = editorState.croppingLayerId else { return nil }
                if let found = editorState.leftPage.layers.first(where: { $0.id == id }) { return found }
                if let found = editorState.rightPage.layers.first(where: { $0.id == id }) { return found }
                return nil
            },
            set: { if $0 == nil { editorState.endCropping() } }
        )
    }
    
    private var filterBinding: Binding<AnyLayer?> {
        Binding(
            get: {
                guard let id = editorState.filteringLayerId else { return nil }
                if let found = editorState.leftPage.layers.first(where: { $0.id == id }) { return found }
                if let found = editorState.rightPage.layers.first(where: { $0.id == id }) { return found }
                return nil
            },
            set: { if $0 == nil { editorState.endFiltering() } }
        )
    }
    
    // MARK: - Sheets
    @ViewBuilder
    private func cropSheet(wrapper: AnyLayer) -> some View {
        if let photoLayer = wrapper.layer as? PhotoLayer {
            CropEditor(
                layer: photoLayer,
                onSave: { scale, offset, newFrame, cropRotation, newNormalizedRect in
                    if let frame = newFrame { editorState.updateLayerFrame(photoLayer.id, newFrame: frame) }
                    editorState.updateLayerCrop(id: photoLayer.id, scale: scale, offset: offset, normalizedRect: newNormalizedRect, cropRotation: cropRotation)
                    editorState.endCropping()
                },
                onCancel: { editorState.endCropping() }
            )
        }
    }
    
    @ViewBuilder
    private func filterSheet(wrapper: AnyLayer) -> some View {
        if let photoLayer = wrapper.layer as? PhotoLayer {
            FilterEditor(
                layer: photoLayer,
                onSave: { filterType, brightness, contrast, saturation, vignette, sharpen, temperature in
                    editorState.updateLayerFilter(id: photoLayer.id, filterType: filterType, brightness: brightness, contrast: contrast, saturation: saturation, vignette: vignette, sharpen: sharpen, temperature: temperature)
                    editorState.endFiltering()
                },
                onCancel: { editorState.endFiltering() }
            )
        }
    }
    
    // MARK: - Handlers
    private func handleDelete() -> KeyPress.Result {
        if editorState.selectedLayerId != nil {
            editorState.deleteSelectedLayer()
            return .handled
        }
        return .ignored
    }
    
    // MARK: - Context Menu
    @ViewBuilder
    private var pageContextMenu: some View {
        // Only show delete option for inner pages (not covers)
        if pageModel.pageNumber >= 1 {
            Button(role: .destructive) {
                deleteSinglePage()
            } label: {
                Label("删除此页", systemImage: "trash")
            }
            .disabled(!canDeletePage)
            
            if !canDeletePage && !pageModel.layers.isEmpty {
                Text("只能删除空白页")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    /// Check if this page can be deleted
    private var canDeletePage: Bool {
        // Can only delete if:
        // 1. It's an inner page (not cover)
        // 2. The page is empty (no layers)
        // 3. There's more than one spread
        guard pageModel.pageNumber >= 1 else { return false }
        guard pageModel.layers.isEmpty else { return false }
        guard editorState.spreadCount > 1 else { return false }
        return true
    }
    
    /// Delete this single page by removing the entire spread if both pages are empty,
    /// or by merging with adjacent pages
    private func deleteSinglePage() {
        guard case .innerSpread(let currentIndex) = editorState.currentTarget else { return }
        guard canDeletePage else { return }
        
        // Save current state first
        editorState.saveCurrentState()
        
        let currentSpread = editorState.bookStructure.innerSpreads[currentIndex]
        
        // Check if the other page in this spread is also empty
        let otherPageEmpty = isLeft ? currentSpread.right.layers.isEmpty : currentSpread.left.layers.isEmpty
        
        if otherPageEmpty {
            // Both pages are empty - delete the entire spread
            editorState.deleteSpread(at: currentIndex)
        } else {
            // Only one page is empty - we need to reorganize
            // Strategy: Remove this page and shift subsequent pages
            var newSpreads: [(left: PageModel, right: PageModel)] = []
            var pagesToReorganize: [PageModel] = []
            
            // Collect all pages except the one being deleted
            for (index, spread) in editorState.bookStructure.innerSpreads.enumerated() {
                if index == currentIndex {
                    // Skip the page being deleted
                    if isLeft {
                        pagesToReorganize.append(spread.right)
                    } else {
                        pagesToReorganize.append(spread.left)
                    }
                } else {
                    pagesToReorganize.append(spread.left)
                    pagesToReorganize.append(spread.right)
                }
            }
            
            // Reorganize into spreads
            var i = 0
            while i < pagesToReorganize.count {
                if i + 1 < pagesToReorganize.count {
                    newSpreads.append((left: pagesToReorganize[i], right: pagesToReorganize[i + 1]))
                    i += 2
                } else {
                    // Odd page left - create a spread with empty right page
                    newSpreads.append((left: pagesToReorganize[i], right: PageModel(pageNumber: -99)))
                    i += 1
                }
            }
            
            // Update book structure
            editorState.bookStructure.innerSpreads = newSpreads
            
            // Navigate to appropriate spread
            let targetIndex = min(currentIndex, newSpreads.count - 1)
            editorState.navigateToSpread(targetIndex)
        }
    }
    
    private func handleDrop(items: [URL], location: CGPoint, scale: CGFloat) -> Bool {
        guard pageModel.pageNumber != -98 && pageModel.pageNumber != -99 else { return false }
        if pageModel.pageNumber == 0 && !isLeft { return false }
        if pageModel.pageNumber == -1 && isLeft { return false }
        guard let url = items.first else { return false }
        
        if let photo = photoStore.allPhotos.first(where: { $0.url == url }) {
            editorState.addPhotoLayer(photo: photo, isLeftPage: isLeft, center: location, scale: scale)
            return true
        }
        return false
    }
}
