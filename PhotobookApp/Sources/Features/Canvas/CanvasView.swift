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
                    
                    HStack(spacing: 20) {
                        // Left arrow button
                        navigationButton(direction: .previous)
                        
                        spreadContent
                        
                        // Right arrow button
                        navigationButton(direction: .next)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .focused($isCanvasFocused)
        .onAppear { isCanvasFocused = true }
        .onTapGesture { isCanvasFocused = true }
        .onKeyPress(.leftArrow) {
            navigatePrevious()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            navigateNext()
            return .handled
        }
        .onKeyPress(.delete) {
            handleDelete()
        }
        .onKeyPress(.deleteForward) {
            handleDelete()
        }
    }
    
    // MARK: - Delete Handler
    
    private func handleDelete() -> KeyPress.Result {
        if editorState.selectedLayerId != nil {
            editorState.deleteSelectedLayer()
            return .handled
        }
        return .ignored
    }
    
    // MARK: - Navigation
    
    enum NavigationDirection {
        case previous, next
    }
    
    @ViewBuilder
    private func navigationButton(direction: NavigationDirection) -> some View {
        let canNavigate = direction == .previous ? canNavigatePrevious : canNavigateNext
        let icon = direction == .previous ? "chevron.left" : "chevron.right"
        
        Button {
            if direction == .previous {
                navigatePrevious()
            } else {
                navigateNext()
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(canNavigate ? themeManager.theme.accentColor : Color.gray.opacity(0.3))
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(canNavigate ? Color.white : Color.clear)
                        .shadow(color: .black.opacity(canNavigate ? 0.1 : 0), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(.plain)
        .disabled(!canNavigate)
        .help(direction == .previous ? "Previous Spread (←)" : "Next Spread (→)")
    }
    
    private var canNavigatePrevious: Bool {
        if case .innerSpread(let index) = editorState.currentTarget {
            return index > 0
        }
        return false
    }
    
    private var canNavigateNext: Bool {
        if case .innerSpread(let index) = editorState.currentTarget {
            return index < editorState.spreadCount - 1
        }
        return false
    }
    
    private func navigatePrevious() {
        if case .innerSpread(let index) = editorState.currentTarget, index > 0 {
            editorState.navigateToSpread(index - 1)
        }
    }
    
    private func navigateNext() {
        if case .innerSpread(let index) = editorState.currentTarget, index < editorState.spreadCount - 1 {
            editorState.navigateToSpread(index + 1)
        }
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
    @Environment(LocalizationManager.self) private var localization
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
            .onKeyPress(keys: [.init("x")], phases: .down) { keyPress in
                if keyPress.modifiers.contains(.command) {
                    editorState.cutSelectedLayer()
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(keys: [.init("c")], phases: .down) { keyPress in
                if keyPress.modifiers.contains(.command) {
                    editorState.copySelectedLayer()
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(keys: [.init("v")], phases: .down) { keyPress in
                if keyPress.modifiers.contains(.command) {
                    editorState.pasteLayer(toLeftPage: isLeft)
                    return .handled
                }
                return .ignored
            }
            .onKeyPress(keys: [.init("d")], phases: .down) { keyPress in
                if keyPress.modifiers.contains(.command) {
                    editorState.duplicateSelectedLayer()
                    return .handled
                }
                return .ignored
            }
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
                if let patternType = pageModel.patternType { 
                    patternView(for: patternType)
                        .opacity(pageModel.backgroundOpacity)
                }
            }
        case .texture:
            ZStack {
                Rectangle().fill(Color(hex: pageModel.backgroundColorHex))
                if let textureType = pageModel.textureType { 
                    textureView(for: textureType) 
                        .opacity(pageModel.backgroundOpacity)
                }
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
        case "waves": WavesPattern()
        case "checks": ChecksPattern()
        case "zigzag": ZigzagPattern()
        default: EmptyView()
        }
    }
    
    @ViewBuilder
    private func textureView(for type: String) -> some View {
        switch type {
        case "paper": DotsPattern().opacity(0.4)
        case "fabric": DiagonalPattern().opacity(0.5)
        case "wood": StripesPattern().opacity(0.6)
        case "marble": GridPattern().stroke(Color.gray.opacity(0.3), lineWidth: 1.0)
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
            .onTapGesture { 
                editorState.deselect()
                editorState.activePageSide = isLeft ? .left : .right
            }
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
        // Paste option (if clipboard has content)
        if editorState.hasClipboard {
            Button {
                editorState.pasteLayer(toLeftPage: isLeft)
            } label: {
                Label(localization.localized(.paste), systemImage: "doc.on.clipboard")
            }
            .keyboardShortcut("v", modifiers: .command)
            
            Divider()
        }
        
        // Only show delete option for inner pages (not covers)
        if pageModel.pageNumber >= 1 {
            Button(role: .destructive) {
                deleteSinglePage()
            } label: {
                Label(localization.localized(.delete), systemImage: "trash")
            }
            .disabled(!canDeletePage)
        }
    }
    
    /// Check if this page can be deleted
    private var canDeletePage: Bool {
        // Can only delete if:
        // 1. It's an inner page (not cover)
        // 2. There's more than one spread
        guard pageModel.pageNumber >= 1 else { return false }
        guard editorState.spreadCount > 1 else { return false }
        return true
    }
    
    /// Delete this single page by removing it and shifting all subsequent pages forward
    /// Uses ceil() for spread count to ensure odd pages have a home
    /// Merges last spread only when BOTH its left and right pages are empty
    private func deleteSinglePage() {
        guard case .innerSpread(let currentIndex) = editorState.currentTarget else { return }
        guard canDeletePage else { return }
        
        print("🗑️ 开始删除单页 - 当前跨页索引: \(currentIndex), 是左页: \(isLeft)")
        
        // Save to undo stack BEFORE making changes
        editorState.saveUndoState()
        
        // Step 1: Flatten all contents into a stream
        var allContents: [(layers: [AnyLayer], bgColor: String, bgType: PageModel.BackgroundType, gradientColors: [String]?, patternType: String?, textureType: String?)] = []
        
        for spread in editorState.bookStructure.innerSpreads {
            let pages = [spread.left, spread.right]
            for page in pages {
                allContents.append((
                    layers: page.layers,
                    bgColor: page.backgroundColorHex,
                    bgType: page.backgroundType,
                    gradientColors: page.gradientColors,
                    patternType: page.patternType,
                    textureType: page.textureType
                ))
            }
        }
        
        // Step 1.5: Vacuum - If the last spread has our specific "Left-Blank" placeholder,
        // remove it from the content stream so it doesn't count as a real page in the next deletion.
        if editorState.bookStructure.innerSpreads.last?.left.layers.isEmpty == true && 
           editorState.bookStructure.innerSpreads.count > 1 {
            let placeholderIndex = allContents.count - 2 // Left page of last spread
            if placeholderIndex >= 0 {
                print("🧹 检测到预览占位符，从内容流中移除")
                allContents.remove(at: placeholderIndex)
            }
        }
        
        // Step 2: Identify the slot we are deleting and remove it
        let indexToDelete = currentIndex * 2 + (isLeft ? 0 : 1)
        
        // Safety: If we just removed a placeholder at (count-2), our index might need adjustment 
        // if we were trying to delete the very last page which just shifted. 
        // But the user clicked a specific UI element.
        guard indexToDelete < allContents.count else { 
            print("⚠️ 索引超出内容流范围，操作取消")
            return 
        }
        
        print("✂️ 正在从 \(allContents.count) 个真实内容槽位中删除索引 \(indexToDelete)")
        allContents.remove(at: indexToDelete)
        
        // Step 3: Rebuild spreads with the "Left-Blank for Odd" rule
        let N = allContents.count
        var newSpreads: [(left: PageModel, right: PageModel)] = []
        
        if N % 2 == 0 {
            // Even number of contents: Fill spreads normally (e.g., 6 contents -> 3 spreads)
            for i in stride(from: 0, to: N, by: 2) {
                var left = PageModel(pageNumber: i + 1)
                left.layers = allContents[i].layers
                left.backgroundColorHex = allContents[i].bgColor
                left.backgroundType = allContents[i].bgType
                left.gradientColors = allContents[i].gradientColors
                left.patternType = allContents[i].patternType
                left.textureType = allContents[i].textureType
                
                var right = PageModel(pageNumber: i + 2)
                right.layers = allContents[i+1].layers
                right.backgroundColorHex = allContents[i+1].bgColor
                right.backgroundType = allContents[i+1].bgType
                right.gradientColors = allContents[i+1].gradientColors
                right.patternType = allContents[i+1].patternType
                right.textureType = allContents[i+1].textureType
                
                newSpreads.append((left: left, right: right))
            }
        } else {
            // Odd number of contents: Last spread's LEFT is empty (e.g., 7 contents -> 4 spreads)
            // Fill first (N-1) contents into full spreads normally
            for i in stride(from: 0, to: N - 1, by: 2) {
                var left = PageModel(pageNumber: i + 1)
                left.layers = allContents[i].layers
                left.backgroundColorHex = allContents[i].bgColor
                left.backgroundType = allContents[i].bgType
                left.gradientColors = allContents[i].gradientColors
                left.patternType = allContents[i].patternType
                left.textureType = allContents[i].textureType
                
                var right = PageModel(pageNumber: i + 2)
                right.layers = allContents[i+1].layers
                right.backgroundColorHex = allContents[i+1].bgColor
                right.backgroundType = allContents[i+1].bgType
                right.gradientColors = allContents[i+1].gradientColors
                right.patternType = allContents[i+1].patternType
                right.textureType = allContents[i+1].textureType
                
                newSpreads.append((left: left, right: right))
            }
            
            // Add the special last spread: [Empty, LastContent]
            let lastContent = allContents[N - 1]
            let leftPage = PageModel(pageNumber: N) // Empty
            var rightPage = PageModel(pageNumber: N + 1)
            rightPage.layers = lastContent.layers
            rightPage.backgroundColorHex = lastContent.bgColor
            rightPage.backgroundType = lastContent.bgType
            rightPage.gradientColors = lastContent.gradientColors
            rightPage.patternType = lastContent.patternType
            rightPage.textureType = lastContent.textureType
            
            newSpreads.append((left: leftPage, right: rightPage))
        }
        
        // Ensure at least one spread exists
        if newSpreads.isEmpty {
            newSpreads.append((left: PageModel(pageNumber: 1), right: PageModel(pageNumber: 2)))
        }
        
        print("📖 重组完成: 内容数 \(N), 跨页数 \(newSpreads.count)")
        editorState.bookStructure.innerSpreads = newSpreads
        
        // Step 4: Navigate
        let targetIdx = min(currentIndex, newSpreads.count - 1)
        editorState.currentTarget = .innerSpread(index: targetIdx)
        editorState.loadStateWithoutSaving()
        
        print("✅ 删除成功，当前总页数: \(editorState.bookStructure.totalInnerPages)")
    }
    
    private func handleDrop(items: [URL], location: CGPoint, scale: CGFloat) -> Bool {
        guard pageModel.pageNumber != -98 && pageModel.pageNumber != -99 else { return false }
        
        let totalInnerPages = editorState.bookStructure.totalInnerPages
        if pageModel.pageNumber == 1 || pageModel.pageNumber == totalInnerPages {
            return false // Reserved: Cover Back and Back Cover Back
        }
        
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
