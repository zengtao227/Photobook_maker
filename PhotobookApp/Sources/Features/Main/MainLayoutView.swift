import SwiftUI

struct MainLayoutView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(BookContext.self) private var bookContext
    @Environment(EditorState.self) private var editorState
    @EnvironmentObject var photoStore: PhotoStore
    
    // Page Management State
    @State private var pages: [PhotoPage] = [PhotoPage(id: UUID(), order: 0)]
    @State private var activePageId: UUID? = nil
    
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
                            Text("项目")
                        }
                        .padding(8)
                        .background(themeManager.theme.searchFieldColor)
                        .cornerRadius(8)
                        .foregroundColor(themeManager.theme.textColor)
                    }
                    .buttonStyle(.plain)
                    .help("返回项目列表")
                    
                    Spacer()
                    
                    // Theme Toggle (moved here or keep in Inspector?)
                    // Actually, let's keep the spacer so Close is on left
                    // We can add the Theme Toggle here if needed or leave it in Inspector.
                    
                    // Save Button Removed: Auto-save handles everything.
                    
                    Spacer()
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
        } detail: {
            // MARK: - Right Sidebar (Inspector)
            InspectorPanel()
                .navigationSplitViewColumnWidth(min: 240, ideal: 280)
                .background(themeManager.theme.panelColor)
        }
        .navigationSplitViewStyle(.balanced)
        // Global Theme Transition
        .animation(.easeInOut(duration: 0.3), value: themeManager.currentMode)
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
