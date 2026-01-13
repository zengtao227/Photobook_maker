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
    @Environment(ThemeManager.self) var themeManager
    @Environment(LocalizationManager.self) var localization
    
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
    @State private var selectedTemplateStyle: TemplateStyle = .family
    
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
                Text(localization.localized(.smartImportWizard))
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
                    Button(localization.localized(.previousStep)) {
                        goBack()
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                }
                
                Spacer()
                
                if importStep == .groupingReview {
                    Button(localization.localized(.nextStepLayout)) {
                        importStep = .layoutConfiguration
                    }
                    .buttonStyle(.borderedProminent)
                } else if importStep == .layoutConfiguration {
                    Button(localization.localized(.startGenerating)) {
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
            Text(localization.localized(.selectPhotoSource))
                .font(.title)
            
            HStack(spacing: 40) {
                ImportSourceButton(icon: "folder", title: localization.localized(.folder)) {
                    selectFolder()
                }
                
                ImportSourceButton(icon: "photo", title: localization.localized(.selectPhotos)) {
                    selectPhotos()
                }
                
                ImportSourceButton(icon: "photo.on.rectangle", title: localization.localized(.photoLibrary)) {
                    showPhotoLibraryPicker = true
                }
                
                ImportSourceButton(icon: "icloud", title: localization.localized(.icloud)) {
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
            
            Text(localization.localized(.analyzingFeatures))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(localization.localized(.cancel)) {
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
                    Text(localization.localized(.smartGroupingSuggestions))
                        .font(.headline)
                    
                    Spacer()
                    
                    if selectedGroupForEdit != nil {
                        Button(localization.localized(.finishEditing)) {
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
                Text(localization.localized(.statistics))
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 10) {
                    StatRow(icon: "photo", label: localization.localized(.analyzedPhotosCount(0)).components(separatedBy: ":").first ?? "Photos", value: "\(classifier.classifiedPhotos.count)")
                    StatRow(icon: "person.2", label: localization.localized(.detectedFacesCount(0)).components(separatedBy: ":").first ?? "Faces", value: "\(classifier.faceClust.count)")
                    StatRow(icon: "mappin.and.ellipse", label: localization.localized(.locationGroupsCount(0)).components(separatedBy: ":").first ?? "Locations", value: "\(classifier.locationGroups.count)")
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
                        Label(localization.localized(.deleteSelectedCount(selectedPhotosInGroup.count)), systemImage: "trash")
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
            Text(localization.localized(.chooseDesignStyle))
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
            
            Toggle(localization.localized(.prioritySmartTemplate), isOn: .constant(true))
                .toggleStyle(.switch)
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text(localization.localized(.generatingLayout))
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
    
    private func selectPhotos() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.image]
        
        if panel.runModal() == .OK {
            self.importedURLs = panel.urls
            if !panel.urls.isEmpty {
                importStep = ImportStep.analyzing
            }
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
        // 智能事件分组：时间优先，场景辅助
        // 核心原则：首先按时间顺序，然后在时间线上按场景/活动分组
        
        var groups: [PhotoGroup] = []
        let allPhotos = classifier.classifiedPhotos.map { $0.photo }
        
        // 0. 首先按时间排序所有照片
        let sortedClassifiedPhotos = classifier.classifiedPhotos.sorted {
            ($0.photo.dateTaken ?? Date.distantPast) < ($1.photo.dateTaken ?? Date.distantPast)
        }
        
        print("📅 按时间排序后的照片数量: \(sortedClassifiedPhotos.count)")
        if let first = sortedClassifiedPhotos.first?.photo.dateTaken,
           let last = sortedClassifiedPhotos.last?.photo.dateTaken {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            print("📅 时间范围: \(formatter.string(from: first)) 至 \(formatter.string(from: last))")
        }
        
        // 1. 基于时间线的活动分组
        // 在时间顺序的基础上，识别连续的活动/事件
        let activityGroups = groupByTimelineActivity(sortedClassifiedPhotos, classifier: classifier)
        groups.append(contentsOf: activityGroups)
        
        // 2. 对于未被分组的照片，按时间事件分组
        let groupedIds = Set(groups.flatMap { $0.photos.map { $0.id } })
        let ungrouped = sortedClassifiedPhotos.filter { !groupedIds.contains($0.photo.id) }
        
        if !ungrouped.isEmpty {
            let timeGroups = classifier.groupByTimeEvent(ungrouped.map { $0.photo }, gap: 14400) // 4 hours
            for timeGroup in timeGroups where timeGroup.photos.count >= 2 {
                groups.append(timeGroup)
            }
        }
        
        // 3. 收集所有剩余未分组的照片
        let allGroupedIds = Set(groups.flatMap { $0.photos.map { $0.id } })
        let remaining = allPhotos.filter { !allGroupedIds.contains($0.id) }
        if !remaining.isEmpty {
            // 按时间排序剩余照片
            let sortedRemaining = remaining.sorted {
                ($0.dateTaken ?? Date.distantPast) < ($1.dateTaken ?? Date.distantPast)
            }
            groups.append(PhotoGroup(
                id: UUID(),
                name: "其他照片",
                icon: "photo.stack",
                photos: sortedRemaining,
                groupType: .custom
            ))
        }
        
        // 4. 关键：按照每个分组中最早照片的时间排序（时间优先）
        groups.sort { group1, group2 in
            let date1 = group1.photos.compactMap { $0.dateTaken }.min() ?? Date.distantPast
            let date2 = group2.photos.compactMap { $0.dateTaken }.min() ?? Date.distantPast
            return date1 < date2
        }
        
        // 5. 如果完全没有分组，创建一个包含所有照片的分组（按时间排序）
        if groups.isEmpty && !allPhotos.isEmpty {
            let sortedAll = allPhotos.sorted {
                ($0.dateTaken ?? Date.distantPast) < ($1.dateTaken ?? Date.distantPast)
            }
            groups.append(PhotoGroup(
                id: UUID(),
                name: "所有照片",
                icon: "photo.stack",
                photos: sortedAll,
                groupType: .custom
            ))
        }
        
        self.detectedEvents = groups
        
        // 打印分组结果用于调试
        print("📊 智能分组结果（按时间排序）:")
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        for (index, group) in groups.enumerated() {
            let firstDate = group.photos.compactMap { $0.dateTaken }.min()
            let dateStr = firstDate.map { formatter.string(from: $0) } ?? "无日期"
            print("  \(index + 1). [\(dateStr)] \(group.name) - \(group.photoCount)张照片")
        }
    }
    
    /// 基于时间线的活动分组
    /// 在时间顺序的基础上，识别连续的活动/事件
    private func groupByTimelineActivity(_ sortedPhotos: [ClassifiedPhoto], classifier: PhotoClassifier) -> [PhotoGroup] {
        guard !sortedPhotos.isEmpty else { return [] }
        
        var groups: [PhotoGroup] = []
        var currentGroup: [ClassifiedPhoto] = []
        var currentScene: SceneCategory?
        var currentActivityType: ActivityType?
        
        // 时间间隔阈值（4小时）
        let timeGap: TimeInterval = 14400
        
        for photo in sortedPhotos {
            let scene = photo.sceneCategory ?? .other
            
            if currentGroup.isEmpty {
                // 开始新分组
                currentGroup = [photo]
                currentScene = scene
                currentActivityType = detectActivityTypeForPhoto(photo, scene: scene)
            } else {
                // 检查是否应该继续当前分组
                let lastPhoto = currentGroup.last!
                let lastDate = lastPhoto.photo.dateTaken ?? Date.distantPast
                let currDate = photo.photo.dateTaken ?? Date.distantPast
                let timeDiff = currDate.timeIntervalSince(lastDate)
                
                // 判断是否是同一活动：
                // 1. 时间间隔在阈值内
                // 2. 场景类型相同或兼容
                let isSameActivity = timeDiff <= timeGap && isCompatibleScene(currentScene, scene)
                
                if isSameActivity {
                    currentGroup.append(photo)
                } else {
                    // 保存当前分组，开始新分组
                    if currentGroup.count >= 2 {
                        let group = createGroupFromPhotos(currentGroup, scene: currentScene!, activityType: currentActivityType!)
                        groups.append(group)
                    }
                    currentGroup = [photo]
                    currentScene = scene
                    currentActivityType = detectActivityTypeForPhoto(photo, scene: scene)
                }
            }
        }
        
        // 保存最后一个分组
        if currentGroup.count >= 2, let scene = currentScene, let activityType = currentActivityType {
            let group = createGroupFromPhotos(currentGroup, scene: scene, activityType: activityType)
            groups.append(group)
        }
        
        return groups
    }
    
    /// 检查两个场景是否兼容（可以归为同一活动）
    private func isCompatibleScene(_ scene1: SceneCategory?, _ scene2: SceneCategory) -> Bool {
        guard let s1 = scene1 else { return true }
        
        // 相同场景
        if s1 == scene2 { return true }
        
        // 兼容的场景组合
        let compatibleGroups: [[SceneCategory]] = [
            [.landscape, .nature, .travel],  // 户外/旅行
            [.portrait, .event],              // 人物/活动
            [.food, .urban],                  // 城市生活
            [.architecture, .travel, .urban], // 城市/旅行
        ]
        
        for group in compatibleGroups {
            if group.contains(s1) && group.contains(scene2) {
                return true
            }
        }
        
        return false
    }
    
    /// 为单张照片检测活动类型
    private func detectActivityTypeForPhoto(_ photo: ClassifiedPhoto, scene: SceneCategory) -> ActivityType {
        switch scene {
        case .landscape, .nature: return .outdoor
        case .portrait: return photo.faceCount > 2 ? .party : .family
        case .food: return .dining
        case .architecture, .travel, .urban: return .travel
        case .event: return .party
        case .animal: return .outdoor
        default: return .unknown
        }
    }
    
    /// 从照片列表创建分组
    private func createGroupFromPhotos(_ photos: [ClassifiedPhoto], scene: SceneCategory, activityType: ActivityType) -> PhotoGroup {
        guard let firstDate = photos.first?.photo.dateTaken,
              let lastDate = photos.last?.photo.dateTaken else {
            return PhotoGroup(
                id: UUID(),
                name: activityType.displayName,
                icon: activityType.icon,
                photos: photos.map { $0.photo },
                groupType: .scene(scene)
            )
        }
        
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        
        let isSameDay = calendar.isDate(firstDate, inSameDayAs: lastDate)
        let eventName: String
        
        if isSameDay {
            formatter.dateFormat = "M月d日"
            let dateStr = formatter.string(from: firstDate)
            let hour = calendar.component(.hour, from: firstDate)
            let timeHint = hour < 6 ? "凌晨" : hour < 12 ? "上午" : hour < 18 ? "下午" : "晚上"
            eventName = "\(activityType.displayName) - \(dateStr) \(timeHint)"
        } else {
            formatter.dateFormat = "M月d日"
            let startStr = formatter.string(from: firstDate)
            let endStr = formatter.string(from: lastDate)
            eventName = "\(activityType.displayName) - \(startStr)至\(endStr)"
        }
        
        return PhotoGroup(
            id: UUID(),
            name: eventName,
            icon: activityType.icon,
            photos: photos.map { $0.photo },
            groupType: .scene(scene)
        )
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
            
            // Start by adding the first spread
            editorState.bookStructure.addInnerSpread()
            var currentSpreadIndex = 0
            var nextIsLeft = false // IMPORTANT: Page 1 is Reserved (Cover Back), so we start on Page 2 (Right)
            
            for suggestion in suggestions {
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
                
                // Assign to book and advance sequentially
                if nextIsLeft {
                    editorState.bookStructure.innerSpreads[currentSpreadIndex].left.layers = newLayers
                    nextIsLeft = false
                } else {
                    editorState.bookStructure.innerSpreads[currentSpreadIndex].right.layers = newLayers
                    // After filling a right page, we always prepare the next spread
                    editorState.bookStructure.addInnerSpread()
                    currentSpreadIndex = editorState.bookStructure.innerSpreads.count - 1
                    nextIsLeft = true
                }
            }
            
            // Cleanup: remove the very last spread if completely empty
            // BUT only if the spread before it has an empty right page (to preserve empty inside-back-cover)
            if editorState.bookStructure.innerSpreads.count > 1 {
                let lastIdx = editorState.bookStructure.innerSpreads.count - 1
                let last = editorState.bookStructure.innerSpreads[lastIdx]
                
                if last.left.layers.isEmpty && last.right.layers.isEmpty {
                    // Check if the spread before it has an empty right page
                    // If the spread before it has a photo on the right, we MUST keep the empty spread
                    // to satisfy the "inside back cover must be empty" rule.
                    let prev = editorState.bookStructure.innerSpreads[lastIdx - 1]
                    if prev.right.layers.isEmpty {
                        editorState.bookStructure.innerSpreads.removeLast()
                    }
                }
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
