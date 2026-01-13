import SwiftUI
import UniformTypeIdentifiers

/// A filmstrip-style page navigator with Cover/Inner page separation (Phase 4)
struct PageNavigatorView: View {
    @Environment(EditorState.self) private var editorState
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LocalizationManager.self) private var localization
    
    @State private var showMoveDialog = false
    @State private var moveFromPage = ""
    @State private var moveToPage = ""
    @State private var targetJumpPage: Int = 1
    
    var body: some View {
        VStack(spacing: 0) {
            // Move spread toolbar
            moveSpreadToolbar
            
            // Move Page Dialog (if shown)
            if showMoveDialog {
                movePageDialog
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Main navigator
            mainNavigator
        }
        .frame(height: showMoveDialog ? 280 : 140)
        .animation(.spring(response: 0.3), value: showMoveDialog)
        .onKeyPress(keys: [.init("z")], phases: .down) { keyPress in
            if keyPress.modifiers.contains(.command) {
                if keyPress.modifiers.contains(.shift) {
                    // Cmd+Shift+Z = Redo
                    if editorState.canRedo {
                        editorState.redo()
                        return .handled
                    }
                } else {
                    // Cmd+Z = Undo
                    if editorState.canUndo {
                        editorState.undo()
                        return .handled
                    }
                }
            }
            return .ignored
        }
    }
    
    // MARK: - Move Spread Toolbar
    
    private var moveSpreadToolbar: some View {
        HStack(spacing: 12) {
            Text(localization.localized(.pageManagement))
                .font(.caption)
                .foregroundColor(themeManager.theme.secondaryTextColor)
            
            // Undo/Redo buttons
            HStack(spacing: 4) {
                Button {
                    editorState.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!editorState.canUndo)
                .help("\(localization.localized(.undo)) (⌘Z)")
                
                Button {
                    editorState.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!editorState.canRedo)
                .help("\(localization.localized(.redo)) (⌘⇧Z)")
            }

            // Go to Page
            HStack(spacing: 8) {
                TextField("", value: $targetJumpPage, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 45)
                    .onSubmit {
                        let totalPages = editorState.spreadCount * 2
                        if targetJumpPage >= 1 && targetJumpPage <= totalPages {
                            let spreadIndex = (targetJumpPage - 1) / 2
                            editorState.navigateToSpread(spreadIndex)
                        }
                    }
                
                Button("Go") {
                    let totalPages = editorState.spreadCount * 2
                    if targetJumpPage >= 1 && targetJumpPage <= totalPages {
                        let spreadIndex = (targetJumpPage - 1) / 2
                        editorState.navigateToSpread(spreadIndex)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(targetJumpPage < 1 || targetJumpPage > editorState.spreadCount * 2)
            }
            .padding(.horizontal, 4)
            
            Spacer()
            
            Button {
                showMoveDialog = true
            } label: {
                Label(localization.localized(.movePage), systemImage: "arrow.left.arrow.right")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(themeManager.theme.panelColor.opacity(0.5))
    }
    
    // MARK: - Move Spread Dialog
    
    private var moveSpreadDialog: some View {
        VStack(spacing: 20) {
            Text(localization.localized(.movePageTitle))
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(localization.localized(.movePageDescription))
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.localized(.fromPage))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField(localization.localized(.enterPageNumber), text: $moveFromPage)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.localized(.toPageBefore))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField(localization.localized(.enterPageNumber), text: $moveToPage)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
            }
            
            let totalPages = editorState.spreadCount * 2
            Text(localization.localized(.pageNumberHint(totalPages, editorState.spreadCount)))
                .font(.caption2)
                .foregroundColor(.orange)
            
            HStack(spacing: 12) {
                Button(localization.localized(.cancel)) {
                    showMoveDialog = false
                    moveFromPage = ""
                    moveToPage = ""
                }
                .keyboardShortcut(.escape)
                
                Button(localization.localized(.move)) {
                    performMove()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 500)
    }
    
    // MARK: - Move Page Dialog (Inline in Toolbar)
    
    private var movePageDialog: some View {
        HStack(spacing: 20) {
            // Close button
            Button {
                withAnimation {
                    showMoveDialog = false
                    moveFromPage = ""
                    moveToPage = ""
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.localized(.movePageTitle))
                    .font(.headline)
                Text(localization.localized(.movePageDescription))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // From Page
            VStack(spacing: 4) {
                Text(localization.localized(.fromPage))
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("", text: $moveFromPage)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
            }
            
            Image(systemName: "arrow.right")
                .foregroundColor(themeManager.theme.accentColor)
            
            // To Page
            VStack(spacing: 4) {
                Text(localization.localized(.toPageBefore))
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("", text: $moveToPage)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
            }
            
            Spacer()
            
            // Info
            let totalPages = editorState.spreadCount * 2
            Text("共 \(totalPages) 页")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.1))
                )
            
            // Buttons
            Button(localization.localized(.cancel)) {
                withAnimation {
                    showMoveDialog = false
                    moveFromPage = ""
                    moveToPage = ""
                }
            }
            .keyboardShortcut(.escape)
            
            Button(localization.localized(.move)) {
                performMove()
            }
            .keyboardShortcut(.return)
            .buttonStyle(.borderedProminent)
            .disabled(moveFromPage.isEmpty || moveToPage.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.theme.searchFieldColor)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    private func performMove() {
        guard let fromPageNum = Int(moveFromPage), let toPageNum = Int(moveToPage) else {
            return
        }
        
        let totalPages = editorState.spreadCount * 2
        
        // Validate page numbers
        guard fromPageNum >= 1 && fromPageNum <= totalPages else {
            return
        }
        guard toPageNum >= 1 && toPageNum <= totalPages + 1 else {
            return
        }
        
        if fromPageNum == toPageNum {
            showMoveDialog = false
            moveFromPage = ""
            moveToPage = ""
            return
        }
        
        // Save undo state before making changes
        editorState.saveUndoState()
        
        // Extract all pages as a flat array
        var allPages: [PageModel] = []
        for spread in editorState.bookStructure.innerSpreads {
            allPages.append(spread.left)
            allPages.append(spread.right)
        }
        
        // Remove the source page
        let pageToMove = allPages.remove(at: fromPageNum - 1)
        
        // Calculate insertion index (adjust if moving forward)
        var insertIndex = toPageNum - 1
        if fromPageNum < toPageNum {
            insertIndex -= 1
        }
        
        // Insert at new position
        allPages.insert(pageToMove, at: insertIndex)
        
        // Rebuild spreads from flat array
        var newSpreads: [(left: PageModel, right: PageModel)] = []
        for i in stride(from: 0, to: allPages.count, by: 2) {
            if i + 1 < allPages.count {
                newSpreads.append((left: allPages[i], right: allPages[i + 1]))
            } else {
                // Odd number of pages - add empty right page
                newSpreads.append((left: allPages[i], right: PageModel(pageNumber: -99)))
            }
        }
        
        // Update book structure
        withAnimation(.spring(response: 0.3)) {
            editorState.bookStructure.innerSpreads = newSpreads
            
            // Navigate to the spread containing the moved page
            let newSpreadIndex = insertIndex / 2
            if newSpreadIndex < editorState.spreadCount {
                editorState.navigateToSpread(newSpreadIndex)
            }
        }
        
        showMoveDialog = false
        moveFromPage = ""
        moveToPage = ""
    }
    
    // MARK: - Main Navigator
    
    private var mainNavigator: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // MARK: - Cover Section
                    coverSection
                    
                    // Divider between covers and inner pages
                    Rectangle()
                        .fill(themeManager.theme.accentColor.opacity(0.3))
                        .frame(width: 2, height: 60)
                        .padding(.horizontal, 8)
                    
                    // MARK: - Inner Pages Section
                    innerPagesSection
                    
                    // Add New Spread Button
                    addSpreadButton(proxy: proxy)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(
                themeManager.currentMode == .studio
                    ? Color(white: 0.12)
                    : themeManager.theme.panelColor
            )
            .overlay(
                // Page count info bar
                HStack {
                    Spacer()
                    pageCountInfo
                        .padding(.trailing, 20)
                }
                .padding(.top, 4),
                alignment: .top
            )
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.white.opacity(0.1)),
                alignment: .top
            )
        }
        .frame(height: 100)
    }
    
    // MARK: - Page Count Info
    
    private var pageCountInfo: some View {
        let totalPages = editorState.bookStructure.totalInnerPages + 2 // +2 for covers
        let isValid = totalPages % 4 == 0
        let bindingType = editorState.bookStructure.bindingType
        
        return HStack(spacing: 8) {
            // Total page count
            Text(localization.localized(.totalPages(totalPages)))
                .font(.caption2)
                .foregroundColor(themeManager.theme.secondaryTextColor)
            
            // Validation indicator for saddle stitch
            if bindingType == .saddleStitch {
                if isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(localization.localized(.needMorePages(4 - (totalPages % 4))))
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(themeManager.theme.searchFieldColor.opacity(0.8))
        .cornerRadius(4)
    }
    
    // MARK: - Cover Section
    
    private var coverSection: some View {
        HStack(spacing: 8) {
            // Section Label
            VStack(spacing: 4) {
                Image(systemName: "book.closed.fill")
                    .font(.caption)
                Text(localization.localized(.cover))
                    .font(.caption2)
            }
            .foregroundColor(themeManager.theme.secondaryTextColor)
            .frame(width: 40)
            
            // Front Cover (左边)
            CoverThumbnailItem(
                title: localization.localized(.frontCover),
                page: editorState.bookStructure.frontCover,
                isActive: editorState.currentTarget == .frontCover,
                icon: "rectangle.portrait.lefthalf.filled"
            ) {
                withAnimation(.spring(response: 0.3)) {
                    editorState.navigateToFrontCover()
                }
            }
            
            // Spine indicator (for hardcover)
            if editorState.bookStructure.bindingType.supportsFullWrap {
                SpineIndicator(widthMM: editorState.bookStructure.spineWidthMM)
            }
            
            // Back Cover (右边)
            CoverThumbnailItem(
                title: localization.localized(.backCover),
                page: editorState.bookStructure.backCover,
                isActive: editorState.currentTarget == .backCover,
                icon: "rectangle.portrait.righthalf.filled"
            ) {
                withAnimation(.spring(response: 0.3)) {
                    editorState.navigateToBackCover()
                }
            }
        }
    }
    
    // MARK: - Inner Pages Section
    
    private var innerPagesSection: some View {
        HStack(spacing: 8) {
            // Section Label
            VStack(spacing: 4) {
                Image(systemName: "book.pages")
                    .font(.caption)
                Text(localization.localized(.innerPages))
                    .font(.caption2)
            }
            .foregroundColor(themeManager.theme.secondaryTextColor)
            .frame(width: 40)
            
            // Inner Spreads with drag reordering
            ForEach(Array(editorState.bookStructure.innerSpreads.enumerated()), id: \.element.left.id) { index, spread in
                SpreadThumbnailItem(
                    spreadIndex: index,
                    leftPage: spread.left,
                    rightPage: spread.right,
                    isActive: editorState.currentTarget == .innerSpread(index: index),
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            editorState.navigateToSpread(index)
                        }
                    },
                    onDelete: editorState.spreadCount > 1 ? {
                        withAnimation {
                            editorState.deleteSpread(at: index)
                        }
                    } : nil
                )
                .id("spread_\(index)")
                .onDrag {
                    // 创建拖拽数据，使用JSON格式
                    let dragData = SpreadDragData(index: index)
                    guard let data = try? JSONEncoder().encode(dragData) else {
                        return NSItemProvider()
                    }
                    let provider = NSItemProvider()
                    provider.registerDataRepresentation(forTypeIdentifier: UTType.json.identifier, visibility: .all) { completion in
                        completion(data, nil)
                        return nil
                    }
                    print("🚀 Started dragging spread \(index)")
                    return provider
                }
                .onDrop(of: [.json], delegate: SpreadDropDelegate(
                    destinationIndex: index,
                    editorState: editorState
                ))
            }
        }
    }
    
    // MARK: - Add Spread Button
    
    private func addSpreadButton(proxy: ScrollViewProxy) -> some View {
        // 骑马钉需要总页数是4的倍数，每个跨页是2页，所以新建1个跨页即可
        let addCount = 1
        let buttonText = localization.localized(.newPage)
        
        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                // Add spreads based on binding type
                for _ in 0..<addCount {
                    editorState.addNewSpread()
                }
            }
            // Scroll to the new spread
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    proxy.scrollTo("spread_\(editorState.spreadCount - 1)", anchor: .trailing)
                }
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(themeManager.theme.accentColor)
                Text(buttonText)
                    .font(.caption2)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
            }
            .frame(width: 100, height: 70)
            .background(themeManager.theme.searchFieldColor.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .foregroundColor(themeManager.theme.accentColor.opacity(0.5))
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

/// Miniature representation of a single page
struct CoverThumbnailMiniature: View {
    let page: PageModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(hex: page.backgroundColorHex)
                
                // Layer indicators - 使用逻辑坐标系统
                ForEach(page.layers.prefix(3)) { wrapper in
                    if let photoLayer = wrapper.layer as? PhotoLayer {
                        // 使用逻辑坐标：假设页面逻辑尺寸为400x300点
                        let logicalPageWidth: CGFloat = 400
                        
                        // 计算缩略图缩放比例
                        let thumbnailScale = geometry.size.width / logicalPageWidth
                        
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(
                                width: max(8, photoLayer.frame.width * thumbnailScale),
                                height: max(6, photoLayer.frame.height * thumbnailScale)
                            )
                            .position(
                                x: photoLayer.frame.midX * thumbnailScale,
                                y: photoLayer.frame.midY * thumbnailScale
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Cover Thumbnail Item

struct CoverThumbnailItem: View {
    let title: String
    let page: PageModel
    let isActive: Bool
    let icon: String
    let action: () -> Void
    
    @State private var isHovering = false
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottom) {
                // Cover preview (single page)
                ZStack {
                    // Use the new miniature view with logical coordinates
                    CoverThumbnailMiniature(page: page)
                    
                    // Cover icon overlay
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(themeManager.theme.secondaryTextColor.opacity(0.3))
                }
                .frame(width: 50, height: 70)
                .background(Color.white)
                .cornerRadius(4)
                .shadow(
                    color: isActive ? themeManager.theme.accentColor.opacity(0.4) : .black.opacity(0.15),
                    radius: isActive ? 6 : 3,
                    y: isActive ? 2 : 1
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isActive ? themeManager.theme.accentColor : Color.clear, lineWidth: 2)
                )
                
                // Title badge
                Text(title)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(isActive ? themeManager.theme.accentColor : Color.black.opacity(0.6))
                    .cornerRadius(3)
                    .offset(y: 8)
            }
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isActive)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Spine Indicator

struct SpineIndicator: View {
    let widthMM: Double
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.black.opacity(0.3), .black.opacity(0.1), .black.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(8, CGFloat(widthMM) * 2), height: 70)
                .cornerRadius(2)
            
            Text(String(format: "%.1fmm", widthMM))
                .font(.system(size: 7))
                .foregroundColor(themeManager.theme.secondaryTextColor)
        }
    }
}

// MARK: - Spread Thumbnail Item

struct SpreadThumbnailItem: View {
    let spreadIndex: Int
    let leftPage: PageModel
    let rightPage: PageModel
    let isActive: Bool
    let action: () -> Void
    let onDelete: (() -> Void)?
    
    @State private var isHovering = false
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LocalizationManager.self) private var localization
    
    // Calculate actual page numbers (1-based, after covers)
    private var leftPageNumber: Int {
        spreadIndex * 2 + 1
    }
    
    private var rightPageNumber: Int {
        spreadIndex * 2 + 2
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Spread preview (two-page layout)
            VStack(spacing: 2) {
                HStack(spacing: 1) {
                    // Left page
                    SpreadPageMiniature(page: leftPage)
                    
                    // Spine indicator
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 2)
                    
                    // Right page
                    SpreadPageMiniature(page: rightPage)
                }
                .frame(width: 100, height: 60)
                .background(Color.white)
                .cornerRadius(6)
                .shadow(
                    color: isActive ? themeManager.theme.accentColor.opacity(0.4) : .black.opacity(0.15),
                    radius: isActive ? 6 : 3,
                    y: isActive ? 2 : 1
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isActive ? themeManager.theme.accentColor : Color.clear, lineWidth: 2)
                )
                
                // Page numbers below thumbnail
                HStack(spacing: 0) {
                    Text("\(leftPageNumber)")
                        .frame(maxWidth: .infinity)
                    Text("-")
                    Text("\(rightPageNumber)")
                        .frame(maxWidth: .infinity)
                }
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(isActive ? themeManager.theme.accentColor : themeManager.theme.secondaryTextColor)
            }
            
            // Spread index badge (top right)
            Text(localization.localized(.innerSpreadLabel(spreadIndex + 1)))
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(isActive ? themeManager.theme.accentColor : Color.black.opacity(0.6))
                .cornerRadius(4)
                .offset(x: -2, y: 2)
            
            // Delete button (on hover)
            if let onDelete = onDelete, isHovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .background(Color.white.clipShape(Circle()))
                }
                .buttonStyle(.plain)
                .offset(x: 8, y: -8)
            }
        }
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isActive)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

/// Miniature representation of a single page
struct SpreadPageMiniature: View {
    let page: PageModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(hex: page.backgroundColorHex)
                
                // Layer indicators (simplified) - 使用逻辑坐标系统
                ForEach(page.layers.prefix(3)) { wrapper in
                    if let photoLayer = wrapper.layer as? PhotoLayer {
                        // 使用逻辑坐标：假设页面逻辑尺寸为400x300点
                        let logicalPageWidth: CGFloat = 400
                        
                        // 计算缩略图缩放比例
                        let thumbnailScale = geometry.size.width / logicalPageWidth
                        
                        // Show tiny colored rectangles to represent layers
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(
                                width: max(8, photoLayer.frame.width * thumbnailScale),
                                height: max(6, photoLayer.frame.height * thumbnailScale)
                            )
                            .position(
                                x: photoLayer.frame.midX * thumbnailScale,
                                y: photoLayer.frame.midY * thumbnailScale
                            )
                    } else if let textLayer = wrapper.layer as? TextLayer {
                        let logicalPageWidth: CGFloat = 400
                        let thumbnailScale = geometry.size.width / logicalPageWidth
                        
                        Rectangle()
                            .fill(Color.orange.opacity(0.4))
                            .frame(width: 15, height: 4)
                            .position(
                                x: textLayer.frame.midX * thumbnailScale,
                                y: textLayer.frame.midY * thumbnailScale
                            )
                    }
                }
                
                // Layer count badge
                if page.layers.count > 0 {
                    Text("\(page.layers.count)")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.7))
                        .cornerRadius(2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(2)
                }
            }
        }
    }
}

// MARK: - Legacy Support (for backward compatibility)

/// Legacy PhotoPage support - converts to/from spread model
extension PageNavigatorView {
    /// Create a standalone navigator with PhotoPage array (legacy mode)
    init(pages: Binding<[PhotoPage]>, activePageId: Binding<UUID?>) {
        // This initializer is for legacy support only
        // New code should use the EditorState-based version
        self.init()
    }
}


// MARK: - Spread Drag Data

/// Data for drag and drop reordering of spreads
struct SpreadDragData: Codable {
    let index: Int
}

// MARK: - Spread Drop Delegate

struct SpreadDropDelegate: DropDelegate {
    let destinationIndex: Int
    let editorState: EditorState
    
    func performDrop(info: DropInfo) -> Bool {
        guard let item = info.itemProviders(for: [.json]).first else {
            print("❌ No item provider found")
            return false
        }
        
        item.loadDataRepresentation(forTypeIdentifier: UTType.json.identifier) { data, error in
            if let error = error {
                print("❌ Error loading data: \(error)")
                return
            }
            
            guard let data = data,
                  let dragData = try? JSONDecoder().decode(SpreadDragData.self, from: data) else {
                print("❌ Failed to decode drag data")
                return
            }
            
            let fromIndex = dragData.index
            let toIndex = destinationIndex
            
            print("✅ Moving spread from \(fromIndex) to \(toIndex)")
            
            if fromIndex != toIndex {
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.3)) {
                        editorState.moveSpread(from: fromIndex, to: toIndex)
                    }
                }
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        print("📍 Drop entered at index \(destinationIndex)")
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
