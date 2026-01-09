import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Critical: Tell the OS we are a regular GUI app with an icon in the Dock
        // This is strictly required for process launched via 'swift run' or binary to receive keyboard focus
        NSApp.setActivationPolicy(.regular)
        
        // Force activation
        NSApp.activate(ignoringOtherApps: true)
        
        // Restore window frame after a longer delay to ensure window is fully created
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let window = NSApp.windows.first {
                self.restoreWindowFrame(window)
                window.makeKeyAndOrderFront(nil)
            } else {
                // Try again if window not ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let window = NSApp.windows.first {
                        self.restoreWindowFrame(window)
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Save window frame before closing
        if let window = NSApp.windows.first {
            saveWindowFrame(window)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Save window frame when last window closes
        if let window = NSApp.windows.first {
            saveWindowFrame(window)
        }
        return true
    }
    
    private func saveWindowFrame(_ window: NSWindow) {
        let frame = window.frame
        let frameString = NSStringFromRect(frame)
        
        // 使用固定的suite name确保数据持久化
        let defaults = UserDefaults.standard
        defaults.set(frameString, forKey: "PhotobookPro.MainWindowFrame")
        defaults.synchronize()
        
        print("💾 Saved window frame: \(frameString)")
        print("   Width: \(frame.width), Height: \(frame.height)")
        print("   Origin: x=\(frame.origin.x), y=\(frame.origin.y)")
        
        // 验证保存
        if let saved = defaults.string(forKey: "PhotobookPro.MainWindowFrame") {
            print("✅ Verified saved: \(saved)")
        } else {
            print("❌ Failed to save!")
        }
    }
    
    private func restoreWindowFrame(_ window: NSWindow) {
        let defaults = UserDefaults.standard
        
        if let frameString = defaults.string(forKey: "PhotobookPro.MainWindowFrame") {
            let frame = NSRectFromString(frameString)
            if frame != .zero && frame.width > 100 && frame.height > 100 {
                window.setFrame(frame, display: true, animate: false)
                print("📐 Restored window frame: \(frameString)")
                print("   Width: \(frame.width), Height: \(frame.height)")
            } else {
                print("⚠️ Invalid saved frame: \(frameString)")
            }
        } else {
            print("ℹ️ No saved window frame found")
            // 设置一个合理的默认大小
            let defaultFrame = NSRect(x: 100, y: 100, width: 1400, height: 900)
            window.setFrame(defaultFrame, display: true, animate: false)
            print("📐 Using default frame: \(NSStringFromRect(defaultFrame))")
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
    @State private var windowFrameObserver: NSObjectProtocol?
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
                            // Save window frame when app goes to background
                            if let window = NSApp.windows.first {
                                saveWindowFrame(window)
                            }
                        }
                    }
                    .onAppear {
                        // Setup window frame observer
                        setupWindowFrameObserver()
                        // 不再在这里恢复窗口大小，只在app启动时恢复一次
                    }
                    .onDisappear {
                        // Cleanup observer
                        if let observer = windowFrameObserver {
                            NotificationCenter.default.removeObserver(observer)
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
            
            // Restore complete book structure
            editorState.bookStructure = data.bookStructure
            
            print("📂 DEBUG: Loaded project bookStructure:")
            print("   - frontCover layers: \(data.bookStructure.frontCover.layers.count)")
            print("   - backCover layers: \(data.bookStructure.backCover.layers.count)")
            for (index, spread) in data.bookStructure.innerSpreads.enumerated() {
                print("   - innerSpread[\(index)] left:\(spread.left.layers.count) right:\(spread.right.layers.count)")
            }
            
            // Navigate to first spread WITHOUT saving current state (since we just loaded)
            if !data.bookStructure.innerSpreads.isEmpty {
                editorState.currentTarget = .innerSpread(index: 0)
                editorState.loadStateWithoutSaving()  // Load without saving
            } else {
                editorState.currentTarget = .frontCover
                editorState.loadStateWithoutSaving()  // Load without saving
            }
            
            photoStore.allPhotos = data.photos
            photoStore.recalculateMonthGroups()
            
            // Refresh thumbnails and dimensions (they are not persisted)
            Task {
                await photoStore.refreshAllPhotos()
            }
            
            print("✅ Opened project: \(project.name) with \(data.bookStructure.innerSpreads.count) spreads")
        } else {
            // New project - initialize with defaults
            editorState.bookStructure = BookStructure()
            editorState.currentTarget = .frontCover
            editorState.loadStateWithoutSaving()
            photoStore.allPhotos = []
            photoStore.recalculateMonthGroups()
            
            print("✅ Created new project: \(project.name)")
        }
    }
    
    private func closeProject() {
        guard let project = currentProject else { return }
        
        // Save current editing state before closing
        editorState.saveCurrentState()
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
        
        // Throttle: Save every 2 seconds (reduced from 60 for better UX)
        let now = Date()
        if saveThrottle == nil || now.timeIntervalSince(saveThrottle!) > 2.0 {
            saveCurrentProject()
            saveThrottle = now
            print("🔄 Auto-saved project at \(now)")
        }
    }
    
    private func saveCurrentProject() {
        guard let project = currentProject else { return }
        
        // CRITICAL: Save current editing state to bookStructure before persisting
        print("💾 DEBUG: About to save project, calling saveCurrentState()...")
        editorState.saveCurrentState()
        
        print("💾 DEBUG: BookStructure state before save:")
        print("   - frontCover layers: \(editorState.bookStructure.frontCover.layers.count)")
        print("   - backCover layers: \(editorState.bookStructure.backCover.layers.count)")
        for (index, spread) in editorState.bookStructure.innerSpreads.enumerated() {
            print("   - innerSpread[\(index)] left:\(spread.left.layers.count) right:\(spread.right.layers.count)")
        }
        
        PersistenceManager.shared.save(
            project: project,
            bookContext: bookContext,
            editorState: editorState,
            photoStore: photoStore
        )
    }
    
    // MARK: - Window Frame Persistence
    
    private func setupWindowFrameObserver() {
        // Observe window frame changes and save periodically
        windowFrameObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: nil,
            queue: .main
        ) { [self] notification in
            if let window = notification.object as? NSWindow {
                // Debounce: only save after user stops resizing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.saveWindowFrame(window)
                }
            }
        }
        
        // Also observe window move
        _ = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: nil,
            queue: .main
        ) { [self] notification in
            if let window = notification.object as? NSWindow {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.saveWindowFrame(window)
                }
            }
        }
    }
    
    private func saveWindowFrame(_ window: NSWindow) {
        let frame = window.frame
        let frameString = NSStringFromRect(frame)
        
        let defaults = UserDefaults.standard
        defaults.set(frameString, forKey: "PhotobookPro.MainWindowFrame")
        defaults.synchronize()
        
        print("💾 Saved window frame (from observer): \(frameString)")
    }
    
    private func restoreWindowFrameIfNeeded(_ window: NSWindow) {
        let defaults = UserDefaults.standard
        
        if let frameString = defaults.string(forKey: "PhotobookPro.MainWindowFrame") {
            let frame = NSRectFromString(frameString)
            if frame != .zero && frame.width > 100 && frame.height > 100 {
                // 总是恢复保存的窗口大小
                window.setFrame(frame, display: true, animate: false)
                print("📐 Restored window frame (from MainLayoutView): \(frameString)")
            }
        }
    }
}
