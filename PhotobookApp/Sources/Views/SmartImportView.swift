// SmartImportView.swift
// V2 智能导入向导界面

import SwiftUI
import Vision
import PhotosUI

struct SmartImportView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var photoStore: PhotoStore
    @Environment(EditorState.self) var editorState
    @Environment(BookContext.self) var bookContext
    
    @StateObject private var classifier: PhotoClassifier
    @StateObject private var layoutEngine: AutoLayoutEngine
    
    @Binding var isPresented: Bool
    
    // 状态管理
    @State private var importStep: ImportStep = .sourceSelection
    @State private var analysisTask: Task<Void, Never>?
    @State private var selectedPhotos: [Photo] = [] // Temporarily holds photos before committing
    @State private var importedURLs: [URL] = []
    
    // Pickers
    @State private var showPhotoLibraryPicker = false
    
    // 智能分组结果
    @State private var sceneDistribution: [SceneCategory: Int] = [:]
    @State private var detectedEvents: [PhotoGroup] = []
    
    // 选项
    @State private var enableSmartGrouping = true
    @State private var selectedTemplateStyle: TemplateStyle = .minimal
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        let classifier = PhotoClassifier()
        self._classifier = StateObject(wrappedValue: classifier)
        self._layoutEngine = StateObject(wrappedValue: AutoLayoutEngine(classifier: classifier))
    }
    
    enum ImportStep {
        case sourceSelection
        case analyzing
        case groupingReview
        case layoutConfiguration
        case processing
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("智能导入向导")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            ZStack {
                switch importStep {
                case .sourceSelection:
                    sourceSelectionView
                case .analyzing:
                    analyzingView
                case .groupingReview:
                    groupingReviewView
                case .layoutConfiguration:
                    layoutConfigurationView
                case .processing:
                    processingView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Footer Navigation
            HStack {
                if importStep != .sourceSelection && importStep != .analyzing && importStep != .processing {
                    Button("上一步") {
                        goBack()
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                }
                
                Spacer()
                
                if importStep == .groupingReview {
                    Button("下一步: 布局风格") {
                        importStep = .layoutConfiguration
                    }
                    .buttonStyle(.borderedProminent)
                } else if importStep == .layoutConfiguration {
                    Button("开始生成") {
                        importStep = .processing
                        Task {
                            await finalizeGeneration()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 900, height: 650) // Slightly larger for better grid view
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showPhotoLibraryPicker) {
            PhotoLibraryPicker(isPresented: $showPhotoLibraryPicker, selectedPhotos: $selectedPhotos)
        }
        .onChange(of: selectedPhotos) { _, newPhotos in
            if !newPhotos.isEmpty {
                // If photos came from picker, transition to analysis
                self.importedURLs = newPhotos.map { $0.url }
                
                // Add to classifier directly if we have Photo objects? 
                // Classifier usually takes URLs.
                // Let's just set the step, and analyzingView will handle it.
                // Wait, if we already have [Photo] objects with Images, we might skip file loading?
                // Our classifier likely needs URLs to use Vision efficiently or reload them.
                // But let's proceed to analyzing.
                importStep = .analyzing
            }
        }
    }
    
    // MARK: - Step Views
    
    private var sourceSelectionView: some View {
        VStack(spacing: 30) {
            Text("选择照片来源")
                .font(.title)
            
            HStack(spacing: 40) {
                ImportSourceButton(icon: "folder", title: "文件夹") {
                    selectFolder()
                }
                
                ImportSourceButton(icon: "photo.on.rectangle", title: "照片库") {
                    showPhotoLibraryPicker = true
                }
                
                ImportSourceButton(icon: "icloud", title: "iCloud") {
                    // Reuse folder picker but guide user? 
                    // Or just open an open panel that defaults to iCloud Drive
                    selectFolder(defaultDirectory: FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents"))
                }
            }
        }
    }
    
    private var analyzingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: classifier.progress, total: 1.0)
                .progressViewStyle(.linear)
                .frame(width: 300)
            
            Text(classifier.currentStatus)
                .font(.headline)
            
            // Thumbnails Grid Preview
            if !importedURLs.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 5) {
                        ForEach(importedURLs.prefix(50), id: \.self) { url in
                           AsyncImage(url: url) { image in
                               image.resizable().aspectRatio(contentMode: .fill)
                           } placeholder: {
                               Color.gray.opacity(0.3)
                           }
                           .frame(width: 60, height: 60)
                           .clipped()
                           .cornerRadius(4)
                        }
                    }
                    .padding()
                }
                .frame(height: 200)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            Text("正在本地分析照片特征...\n(场景识别 / 人脸检测 / 质量评估)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("取消") {
                analysisTask?.cancel()
                importStep = ImportStep.sourceSelection
            }
        }
        .onAppear {
            analysisTask = Task {
                await classifier.analyzePhotos(importedURLs)
                if !classifier.classifiedPhotos.isEmpty {
                    generateGroups(classifier: classifier)
                    importStep = ImportStep.groupingReview
                }
            }
        }

    }
    
    private var groupingReviewView: some View {
        HStack(spacing: 0) {
            // Left: Validated Groups
            VStack(alignment: .leading) {
                HStack {
                    Text("智能分组建议")
                        .font(.headline)
                    
                    Spacer()
                    
                    if selectedGroupForEdit != nil {
                        Button("完成编辑") {
                            selectedGroupForEdit = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding(.bottom, 10)
                
                if let selectedGroup = selectedGroupForEdit {
                    // Edit mode - show photo grid for selected group
                    groupEditView(group: selectedGroup)
                } else {
                    // Normal mode - show all groups
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(detectedEvents) { group in
                                GroupCard(group: group, onEdit: {
                                    selectedGroupForEdit = group
                                })
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .frame(width: 550)
            
            Divider()
            
            // Right: Settings
            VStack(alignment: .leading, spacing: 20) {
                Text("统计信息")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 10) {
                    StatRow(icon: "photo", label: "已分析照片", value: "\(classifier.classifiedPhotos.count) 张")
                    StatRow(icon: "person.2", label: "识别人脸", value: "\(classifier.faceClust.count) 组")
                    StatRow(icon: "mappin.and.ellipse", label: "地点分组", value: "\(classifier.locationGroups.count) 个")
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .focusable()
        .contentShape(Rectangle())
        .onTapGesture {
            // Take focus
        }
        .onKeyPress(keys: [.init("a")], phases: .down) { keyPress in
            if keyPress.modifiers.contains(.command), let group = selectedGroupForEdit {
                selectedPhotosInGroup = Set(group.photos.map { $0.id })
                return .handled
            }
            return .ignored
        }
    }
    
    // MARK: - Group Edit View
    
    @State private var selectedGroupForEdit: PhotoGroup?
    @State private var selectedPhotosInGroup: Set<UUID> = []
    
    private func groupEditView(group: PhotoGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Group info
            HStack {
                Text(group.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("(\(group.photoCount) 张)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !selectedPhotosInGroup.isEmpty {
                    Button(role: .destructive) {
                        removeSelectedPhotos(from: group)
                    } label: {
                        Label("删除选中 (\(selectedPhotosInGroup.count))", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal)
            
            // Photo grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(group.photos) { photo in
                        photoThumbnailInGroup(photo: photo, group: group)
                    }
                }
                .padding()
            }
        }
    }
    
    private func photoThumbnailInGroup(photo: Photo, group: PhotoGroup) -> some View {
        let isSelected = selectedPhotosInGroup.contains(photo.id)
        
        return ZStack(alignment: .topTrailing) {
            AsyncImage(url: photo.url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .background(Circle().fill(Color.white))
                    .padding(4)
            }
        }
        .onTapGesture {
            if isSelected {
                selectedPhotosInGroup.remove(photo.id)
            } else {
                selectedPhotosInGroup.insert(photo.id)
            }
        }
    }
    
    private func removeSelectedPhotos(from group: PhotoGroup) {
        guard let groupIndex = detectedEvents.firstIndex(where: { $0.id == group.id }) else { return }
        
        // Remove photos from group
        var updatedGroup = group
        updatedGroup.photos.removeAll { selectedPhotosInGroup.contains($0.id) }
        
        // Update the group
        if updatedGroup.photos.isEmpty {
            // Remove empty group
            detectedEvents.remove(at: groupIndex)
            selectedGroupForEdit = nil
        } else {
            detectedEvents[groupIndex] = updatedGroup
            selectedGroupForEdit = updatedGroup
        }
        
        selectedPhotosInGroup.removeAll()
    }
    
    private var layoutConfigurationView: some View {
        VStack(spacing: 30) {
            Text("选择整书设计风格")
                .font(.title2)
            
            HStack(spacing: 20) {
                ForEach(TemplateStyle.allCases.prefix(4)) { style in
                    StyleSelectionCard(
                        style: style,
                        isSelected: selectedTemplateStyle == style
                    ) {
                        selectedTemplateStyle = style
                    }
                }
            }
            .padding()
            
            Toggle("优先使用智能推荐模板", isOn: .constant(true))
                .toggleStyle(.switch)
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在生成相册排版...")
                .font(.headline)
        }
    }
    
    // MARK: - Logic
    
    private func selectFolder(defaultDirectory: URL? = nil) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if let defaultDirectory = defaultDirectory {
            panel.directoryURL = defaultDirectory
        }
        
        if panel.runModal() == .OK, let url = panel.url {
            loadPhotosFromFolder(url)
        }
    }
    
    private func loadPhotosFromFolder(_ folderURL: URL) {
        // 简单的文件扫描逻辑
        if let enumerator = FileManager.default.enumerator(at: folderURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
            var urls: [URL] = []
            for case let fileURL as URL in enumerator {
                if ["jpg", "jpeg", "png", "heic"].contains(fileURL.pathExtension.lowercased()) {
                    urls.append(fileURL)
                }
            }
            self.importedURLs = urls
            
            if !urls.isEmpty {
                importStep = ImportStep.analyzing
            }
        }
    }
    
    private func generateGroups(classifier: PhotoClassifier) {
        // 智能事件分组：优先识别有意义的活动/事件
        // 分组优先级：活动事件 > 场景类型 > 时间分组 > 地点分组
        
        var groups: [PhotoGroup] = []
        let allPhotos = classifier.classifiedPhotos.map { $0.photo }
        
        // 1. 最高优先级：基于活动/事件的智能分组
        // 这能识别出"打篮球"、"滑雪之旅"、"埃及旅行"等有意义的事件
        let activityGroups = classifier.groupByActivity(classifier.classifiedPhotos)
        groups.append(contentsOf: activityGroups)
        
        // 2. 对于未被活动分组的照片，尝试按场景类型分组
        let activityGroupedIds = Set(groups.flatMap { $0.photos.map { $0.id } })
        let ungroupedByActivity = classifier.classifiedPhotos.filter { !activityGroupedIds.contains($0.photo.id) }
        
        if !ungroupedByActivity.isEmpty {
            let sceneDict = Dictionary(grouping: ungroupedByActivity, by: { $0.sceneCategory ?? SceneCategory.other })
            for (scene, classifiedList) in sceneDict {
                if classifiedList.count >= 2 && scene != .other {
                    let group = PhotoGroup(
                        id: UUID(),
                        name: scene.displayName,
                        icon: scene.icon,
                        photos: classifiedList.map { $0.photo },
                        groupType: .scene(scene)
                    )
                    groups.append(group)
                }
            }
        }
        
        // 3. 对于仍未分组的照片，尝试按时间事件分组
        let groupedIds = Set(groups.flatMap { $0.photos.map { $0.id } })
        let stillUngrouped = allPhotos.filter { !groupedIds.contains($0.id) }
        
        if !stillUngrouped.isEmpty {
            let timeGroups = classifier.groupByTimeEvent(stillUngrouped, gap: 14400) // 4 hours
            for timeGroup in timeGroups where timeGroup.photos.count >= 2 {
                groups.append(timeGroup)
            }
        }
        
        // 4. 对于仍未分组的照片，尝试按地点分组
        let finalGroupedIds = Set(groups.flatMap { $0.photos.map { $0.id } })
        let remainingUngrouped = allPhotos.filter { !finalGroupedIds.contains($0.id) }
        
        if !remainingUngrouped.isEmpty {
            for locGroup in classifier.locationGroups {
                let locPhotos = remainingUngrouped.filter { locGroup.photoIds.contains($0.id) }
                if locPhotos.count >= 2 {
                    let group = PhotoGroup(
                        id: UUID(),
                        name: locGroup.placeName,
                        icon: "mappin.and.ellipse",
                        photos: locPhotos,
                        groupType: .location(locGroup)
                    )
                    groups.append(group)
                }
            }
        }
        
        // 5. 最后，收集所有剩余未分组的照片
        let allGroupedIds = Set(groups.flatMap { $0.photos.map { $0.id } })
        let remaining = allPhotos.filter { !allGroupedIds.contains($0.id) }
        if !remaining.isEmpty {
            groups.append(PhotoGroup(
                id: UUID(),
                name: "其他照片",
                icon: "photo.stack",
                photos: remaining,
                groupType: .custom
            ))
        }
        
        // 6. 按照片数量排序（最多的在前）
        groups.sort { $0.photoCount > $1.photoCount }
        
        // 7. 如果完全没有分组，创建一个包含所有照片的分组
        if groups.isEmpty && !allPhotos.isEmpty {
            groups.append(PhotoGroup(
                id: UUID(),
                name: "所有照片",
                icon: "photo.stack",
                photos: allPhotos,
                groupType: .custom
            ))
        }
        
        self.detectedEvents = groups
        
        // 打印分组结果用于调试
        print("📊 智能分组结果:")
        for (index, group) in groups.enumerated() {
            print("  \(index + 1). \(group.name) - \(group.photoCount)张照片")
        }
    }
    
    private func finalizeGeneration() async {
        guard !classifier.classifiedPhotos.isEmpty else {
            dismiss()
            return
        }
        
        // 1. Add photos to PhotoStore
        let uniquePhotos = classifier.classifiedPhotos.map { $0.photo }
        
        await MainActor.run {
            // Append only new ones
            let existingIds = Set(photoStore.allPhotos.map { $0.id })
            let newPhotos = uniquePhotos.filter { !existingIds.contains($0.id) }
            photoStore.allPhotos.append(contentsOf: newPhotos)
            photoStore.recalculateMonthGroups()
            
            // 2. Generate Layout Suggestions with Event Isolation
            let suggestions = layoutEngine.generateBookLayout(groups: detectedEvents, classifiedPhotos: classifier.classifiedPhotos)
            
            // 3. CRITICAL: Clear existing default pages before adding new ones
            editorState.bookStructure.innerSpreads = []
            
            let pageWidth = bookContext.pageSize.dimensionsInPoints.width
            let pageHeight = bookContext.pageSize.dimensionsInPoints.height
            
            // Track current group to enforce event isolation
            var currentGroupIndex = -1
            var currentSpreadIndex = -1
            var isLeft = true
            
            for suggestion in suggestions {
                // Find which group this suggestion belongs to
                let suggestionGroupIndex = findGroupIndex(for: suggestion.photos, in: detectedEvents)
                
                // EVENT ISOLATION: If group changed, start on a new spread
                if suggestionGroupIndex != currentGroupIndex {
                    // Start new spread for new group
                    editorState.bookStructure.addInnerSpread()
                    currentSpreadIndex = editorState.bookStructure.innerSpreads.count - 1
                    isLeft = true
                    currentGroupIndex = suggestionGroupIndex
                }
                
                // Ensure we have a spread to work with
                if currentSpreadIndex < 0 {
                    editorState.bookStructure.addInnerSpread()
                    currentSpreadIndex = editorState.bookStructure.innerSpreads.count - 1
                    isLeft = true
                }
                
                // Get classified photos for this page
                let pageClassifiedPhotos = suggestion.photos.compactMap { photo in
                    classifier.classifiedPhotos.first(where: { $0.photo.id == photo.id })
                }
                
                guard !pageClassifiedPhotos.isEmpty else { continue }
                
                let filledResult = layoutEngine.autoFillTemplate(suggestion.template, with: pageClassifiedPhotos)
                
                // Convert to Layers - PRESERVE PHOTO ASPECT RATIO
                var newLayers: [AnyLayer] = []
                for (photo, slotIndex, _) in filledResult {
                    if slotIndex < suggestion.template.slots.count {
                        let slot = suggestion.template.slots[slotIndex]
                        
                        // Calculate slot frame in absolute coordinates
                        let slotX = slot.rect.origin.x * pageWidth
                        let slotY = slot.rect.origin.y * pageHeight
                        let slotWidth = slot.rect.width * pageWidth
                        let slotHeight = slot.rect.height * pageHeight
                        
                        // Get photo's actual aspect ratio
                        var photoAspectRatio: CGFloat = 1.0
                        if let w = photo.width, let h = photo.height, w > 0, h > 0 {
                            photoAspectRatio = CGFloat(w) / CGFloat(h)
                        }
                        
                        // Calculate frame that fits within slot while preserving aspect ratio
                        let slotAspectRatio = slotWidth / slotHeight
                        var finalWidth: CGFloat
                        var finalHeight: CGFloat
                        
                        if photoAspectRatio > slotAspectRatio {
                            // Photo is wider than slot - fit to width
                            finalWidth = slotWidth
                            finalHeight = slotWidth / photoAspectRatio
                        } else {
                            // Photo is taller than slot - fit to height
                            finalHeight = slotHeight
                            finalWidth = slotHeight * photoAspectRatio
                        }
                        
                        // Center the photo within the slot
                        let finalX = slotX + (slotWidth - finalWidth) / 2
                        let finalY = slotY + (slotHeight - finalHeight) / 2
                        
                        let absFrame = CGRect(x: finalX, y: finalY, width: finalWidth, height: finalHeight)
                        
                        let layer = PhotoLayer(photoId: photo.id, photoUrl: photo.url, frame: absFrame)
                        newLayers.append(AnyLayer(layer))
                    }
                }
                
                // Assign to book
                if isLeft {
                    editorState.bookStructure.innerSpreads[currentSpreadIndex].left.layers = newLayers
                    isLeft = false
                } else {
                    editorState.bookStructure.innerSpreads[currentSpreadIndex].right.layers = newLayers
                    // Mark that we need a new spread for next page
                    isLeft = true
                    currentSpreadIndex = -1
                }
            }
            
            // Cleanup: Remove last spread if it's completely empty
            if let lastSpread = editorState.bookStructure.innerSpreads.last,
               lastSpread.left.layers.isEmpty && lastSpread.right.layers.isEmpty,
               editorState.bookStructure.innerSpreads.count > 1 {
                editorState.bookStructure.innerSpreads.removeLast()
            }
            
            // Force UI refresh - navigate to first spread
            if !editorState.bookStructure.innerSpreads.isEmpty {
                editorState.navigateToSpread(0)
                editorState.loadStateWithoutSaving()
            }
            
            dismiss()
        }
    }
    
    /// Find which group index a set of photos belongs to
    private func findGroupIndex(for photos: [Photo], in groups: [PhotoGroup]) -> Int {
        guard let firstPhoto = photos.first else { return -1 }
        
        for (index, group) in groups.enumerated() {
            if group.photos.contains(where: { $0.id == firstPhoto.id }) {
                return index
            }
        }
        return -1
    }
    private func goBack() {
        switch importStep {
        case .analyzing: importStep = ImportStep.sourceSelection
        case .groupingReview: importStep = ImportStep.sourceSelection // Re-scan? or just back to blank
        case .layoutConfiguration: importStep = ImportStep.groupingReview
        default: break
        }
    }
}

// MARK: - Components

struct ImportSourceButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .padding(.bottom, 10)
                Text(title)
                    .font(.headline)
            }
            .frame(width: 140, height: 140)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }
}

struct GroupCard: View {
    let group: PhotoGroup
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            // Preview Icon/Image
            if group.photos.isEmpty {
                Text(group.icon)
                    .font(.largeTitle)
                    .frame(width: 60, height: 60)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            } else {
                previewGrid
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .clipped()
            }
            
            VStack(alignment: .leading) {
                Text(group.name)
                    .font(.headline)
                Text("\(group.photoCount) 张照片")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .help("编辑此分组")
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var previewGrid: some View {
        let previewPhotos = group.photos.prefix(4)
        return GeometryReader { geometry in
            let w = geometry.size.width / 2
            let h = geometry.size.height / 2
            
            ZStack(alignment: .topLeading) {
                if previewPhotos.count >= 1 {
                    thumbnail(for: previewPhotos[0], size: CGSize(width: w, height: h))
                }
                if previewPhotos.count >= 2 {
                    thumbnail(for: previewPhotos[1], size: CGSize(width: w, height: h))
                        .offset(x: w)
                }
                if previewPhotos.count >= 3 {
                    thumbnail(for: previewPhotos[2], size: CGSize(width: w, height: h))
                        .offset(y: h)
                }
                if previewPhotos.count >= 4 {
                    thumbnail(for: previewPhotos[3], size: CGSize(width: w, height: h))
                        .offset(x: w, y: h)
                }
            }
        }
    }
    
    private func thumbnail(for photo: Photo, size: CGSize) -> some View {
        AsyncImage(url: photo.url) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Color.gray.opacity(0.1)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct StyleSelectionCard: View {
    let style: TemplateStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Preview Area
                ZStack {
                    Color.white
                    stylePreview
                }
                .frame(height: 120)
                .clipped()
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(isSelected ? 0 : 0.05))
                )
                
                // Title Area
                HStack {
                    Text(style.displayName)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .white : .primary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(NSColor.controlBackgroundColor))
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(isSelected ? 0.2 : 0.1), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
        .frame(width: 140, height: 160)
    }
    
    @ViewBuilder
    private var stylePreview: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            switch style {
            case .minimal:
                // Minimal: Clean white, small text, centered photo
                ZStack {
                    Color.white
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: w * 0.7, height: h * 0.5)
                        .shadow(radius: 2)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: w * 0.4, height: 4)
                        .offset(y: h * 0.35)
                }
                
            case .magazine:
                // Magazine: Full bleed image, large overlapping text
                ZStack {
                    Color.black.opacity(0.8)
                    Rectangle() // Image placeholder
                        .fill(LinearGradient(colors: [.gray, .black], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Spacer()
                        Text("LIFE")
                            .font(.system(size: 24, weight: .black, design: .serif))
                            .foregroundColor(.white)
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: w * 0.6, height: 6)
                    }
                    .padding(10)
                }
                
            case .classic:
                // Classic: Border, serif text, beige background
                ZStack {
                    Color(red: 0.98, green: 0.97, blue: 0.95) // Beige
                    
                    Rectangle()
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                        .padding(8)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: w * 0.7, height: h * 0.6)
                        .overlay(
                            Rectangle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .shadow(radius: 3)
                }
                
            case .family:
                // Family: Warm, collage like
                ZStack {
                    Color(red: 1.0, green: 0.98, blue: 0.9) // Warm yellow
                    
                    // Collage
                    Rectangle()
                        .fill(Color.orange.opacity(0.3))
                        .frame(width: w * 0.5, height: h * 0.5)
                        .rotationEffect(.degrees(-5))
                        .offset(x: -10, y: -10)
                        .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                    
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: w * 0.5, height: h * 0.5)
                        .rotationEffect(.degrees(5))
                        .offset(x: 10, y: 10)
                        .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                    
                    Circle()
                        .fill(Color.pink.opacity(0.2))
                        .frame(width: 30, height: 30)
                        .offset(x: -30, y: 30)
                }
                
            default:
                // Fallback
                VStack {
                    Text(style.displayName.prefix(1))
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
