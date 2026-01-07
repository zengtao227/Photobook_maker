import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Critical: Tell the OS we are a regular GUI app with an icon in the Dock
        // This is strictly required for process launched via 'swift run' or binary to receive keyboard focus
        NSApp.setActivationPolicy(.regular)
        
        // Force activation
        NSApp.activate(ignoringOtherApps: true)
        
        // Ensure the window is key
        DispatchQueue.main.async {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}

@main
struct PhotobookApp: App {
    // Inject the delegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var photoStore = PhotoStore()
    @State private var bookContext = BookContext()
    @State private var editorState = EditorState()
    @State private var saveThrottle: Date?
    @Environment(\.scenePhase) private var scenePhase
    
    // Project routing state
    @State private var currentProject: ProjectMetadata? = nil
    @State private var showProjectBrowser = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showProjectBrowser {
                    ProjectBrowserView { project in
                        openProject(project)
                    }
                    .withTheme()
                } else if let project = currentProject {
                    MainLayoutView(
                        currentProject: project,
                        onCloseProject: {
                            closeProject()
                        }
                    )
                    .environmentObject(photoStore)
                    .environment(bookContext)
                    .environment(editorState)
                    .withTheme()
                    .onChange(of: editorState.lastModified) { _, _ in
                        autoSaveCurrentProject()
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .background || newPhase == .inactive {
                            saveCurrentProject()
                        }
                    }
                }
            }
            .onAppear {
                // Secondary check to force focus when view appears
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("新建项目") {
                    createNewProject()
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("导入文件夹...") {
                    photoStore.showFolderPicker = true
                }
                .keyboardShortcut("o", modifiers: .command)
                .disabled(currentProject == nil)
                
                Button("立即保存") {
                    saveCurrentProject()
                }
                .keyboardShortcut("s", modifiers: .command)
                .disabled(currentProject == nil)
                
                Divider()
                
                Button("关闭项目") {
                    closeProject()
                }
                .keyboardShortcut("w", modifiers: .command)
                .disabled(currentProject == nil)
            }
        }
    }
    
    // MARK: - Project Management
    
    private func createNewProject() {
        let meta = PersistenceManager.shared.createNewProject(name: "新项目 \(Date().formatted(date: .numeric, time: .omitted))")
        openProject(meta)
    }
    
    private func openProject(_ project: ProjectMetadata) {
        // Save current project before switching
        if currentProject != nil {
            saveCurrentProject()
        }
        
        // Load new project
        currentProject = project
        showProjectBrowser = false
        
        if let data = PersistenceManager.shared.load(project: project) {
            // Restore State
            bookContext.pageSize = data.pageSize
            bookContext.customWidth = data.customWidth
            bookContext.customHeight = data.customHeight
            
            editorState.leftPage = data.leftPage
            editorState.rightPage = data.rightPage
            
            photoStore.allPhotos = data.photos
            photoStore.recalculateMonthGroups()
            
            print("Opened project: \(project.name)")
        } else {
            // New project - initialize with defaults
            editorState.leftPage = PageModel(pageNumber: 0)
            editorState.rightPage = PageModel(pageNumber: 1)
            photoStore.allPhotos = []
            photoStore.recalculateMonthGroups()
            
            print("Created new project: \(project.name)")
        }
    }
    
    private func closeProject() {
        guard let project = currentProject else { return }
        saveCurrentProject()
        
        currentProject = nil
        showProjectBrowser = true
        
        // Clear state
        editorState.leftPage = PageModel(pageNumber: 0)
        editorState.rightPage = PageModel(pageNumber: 1)
        photoStore.allPhotos = []
        
        print("Closed project: \(project.name)")
    }
    
    private func autoSaveCurrentProject() {
        guard currentProject != nil else { return }
        
        // Throttle: Only save once per minute
        let now = Date()
        if saveThrottle == nil || now.timeIntervalSince(saveThrottle!) > 60.0 {
            saveCurrentProject()
            saveThrottle = now
        }
    }
    
    private func saveCurrentProject() {
        guard let project = currentProject else { return }
        PersistenceManager.shared.save(
            project: project,
            bookContext: bookContext,
            editorState: editorState,
            photoStore: photoStore
        )
    }
}
