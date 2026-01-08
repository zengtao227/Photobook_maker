import SwiftUI

struct MainLayoutView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(BookContext.self) private var bookContext
    @Environment(EditorState.self) private var editorState
    @EnvironmentObject var photoStore: PhotoStore
    
    // Localization
    @State private var localization = LocalizationManager()
    
    // Page Management State
    @State private var pages: [PhotoPage] = [PhotoPage(id: UUID(), order: 0)]
    @State private var activePageId: UUID? = nil
    
    // Export Modal State
    @State private var showExportSettings = false
    
    let currentProject: ProjectMetadata
    let onCloseProject: () -> Void
    
    var body: some View {
        NavigationSplitView {
            // MARK: - Left Sidebar (Library)
            LibraryPanel()
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
                .background(themeManager.theme.panelColor)
        } content: {
            // MARK: - Center Stage (Canvas & Timeline)
            VStack(spacing: 0) {
                // Toolbar Area
                HStack {
                    // Close Project Button
                    Button(action: onCloseProject) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(localization.localized(.project))
                        }
                        .padding(8)
                        .background(themeManager.theme.searchFieldColor)
                        .cornerRadius(8)
                        .foregroundColor(themeManager.theme.textColor)
                    }
                    .buttonStyle(.plain)
                    .help(localization.localized(.backToProjects))
                    
                    Spacer()
                    
                    // Center: Current Page Indicator
                    HStack(spacing: 8) {
                        Image(systemName: editorState.isEditingCover ? "book.closed" : "book.pages")
                            .foregroundColor(themeManager.theme.accentColor)
                        Text(localization.displayName(for: editorState.currentTarget))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.theme.textColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(themeManager.theme.searchFieldColor)
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    // Save Button
                    Button(action: saveProject) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down")
                            Text(localization.currentLanguage == .chinese ? "保存" : "Save")
                        }
                        .padding(8)
                        .background(themeManager.theme.searchFieldColor)
                        .cornerRadius(8)
                        .foregroundColor(themeManager.theme.textColor)
                    }
                    .buttonStyle(.plain)
                    .help(localization.currentLanguage == .chinese ? "保存项目 (⌘S)" : "Save Project (⌘S)")
                    .keyboardShortcut("s", modifiers: .command)
                    
                    // Language Toggle Button
                    Menu {
                        Button(action: { localization.setLanguage(.chinese) }) {
                            HStack {
                                Text("🇨🇳 中文 / Chinese")
                                if localization.currentLanguage == .chinese {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        Button(action: { localization.setLanguage(.english) }) {
                            HStack {
                                Text("🇬🇧 English / 英文")
                                if localization.currentLanguage == .english {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                            Text(localization.currentLanguage == .chinese ? "中/EN" : "EN/中")
                                .font(.caption)
                        }
                        .padding(8)
                        .background(themeManager.theme.searchFieldColor)
                        .cornerRadius(8)
                        .foregroundColor(themeManager.theme.textColor)
                    }
                    .menuStyle(.borderlessButton)
                    .help("Switch Language / 切换语言")
                    
                    // Export Button
                    Button(action: { showExportSettings = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text(localization.localized(.exportPDF))
                        }
                        .padding(8)
                        .background(themeManager.theme.accentColor)
                        .cornerRadius(8)
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .help(localization.localized(.exportPDF))
                    
                    ThemeToggle()
                }
                .padding()
                .background(themeManager.theme.panelColor.opacity(0.5))
                
                // Canvas Area
                // Pass active page info to canvas if needed - For now we keep generic CanvasView
                CanvasView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom Page Navigator (Filmstrip)
                PageNavigatorView(pages: $pages, activePageId: $activePageId)
                    .frame(height: 120)
                    .background(themeManager.theme.panelColor)
                    .onAppear {
                        if let first = pages.first {
                            activePageId = first.id
                        }
                    }
            }
            .background(themeManager.theme.backgroundColor) // Main Background
            // Export Settings Modal
            .sheet(isPresented: $showExportSettings) {
                ExportSettingsView()
                    .environment(localization)
            }
        } detail: {
            // MARK: - Right Sidebar (Inspector)
            InspectorPanel()
                .navigationSplitViewColumnWidth(min: 240, ideal: 280)
                .background(themeManager.theme.panelColor)
                .environment(localization)
        }
        .navigationSplitViewStyle(.balanced)
        .environment(localization)
        // Global Theme Transition
        .animation(.easeInOut(duration: 0.3), value: themeManager.currentMode)
        // Auto-save on changes
        .onChange(of: editorState.lastModified) { _, _ in
            autoSaveProject()
        }
        // MARK: - File Import Handler
        .fileImporter(
            isPresented: $photoStore.showFolderPicker,
            allowedContentTypes: [.folder, .image], // Allow images too
            allowsMultipleSelection: true // Allow selecting multiple files
        ) { result in
            switch result {
            case .success(let urls):
                Task {
                    await photoStore.importFiles(urls)
                }
            case .failure(let error):
                print("Error selecting folder: \(error)")
            }
        }
        // Export Settings Modal
        .sheet(isPresented: $showExportSettings) {
            ExportSettingsView()
                .environment(localization)
        }
    }
    
    // MARK: - Save Functions
    
    private func saveProject() {
        PersistenceManager.shared.save(
            project: currentProject,
            bookContext: bookContext,
            editorState: editorState,
            photoStore: photoStore
        )
        print("✅ Project saved: \(currentProject.name)")
    }
    
    private func autoSaveProject() {
        // Debounce auto-save to avoid too frequent saves
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await MainActor.run {
                saveProject()
            }
        }
    }
}

// MARK: - Component Placeholders

struct ThemeToggle: View {
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        Button(action: {
            themeManager.toggleTheme()
        }) {
            HStack {
                Image(systemName: themeManager.currentMode == .studio ? "sun.max.fill" : "moon.stars.fill")
                Text(themeManager.currentMode == .studio ? "Studio" : "Glass")
            }
            .padding(8)
            .background(themeManager.theme.searchFieldColor)
            .cornerRadius(8)
            .foregroundColor(themeManager.theme.textColor)
        }
        .buttonStyle(.plain)
    }
}
