import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowObserver: NSObjectProtocol?
    private let windowAutosaveName = "PhotobookProMainWindow"
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Critical: Tell the OS we are a regular GUI app with an icon in the Dock
        // This is strictly required for process launched via 'swift run' or binary to receive keyboard focus
        NSApp.setActivationPolicy(.regular)
        
        // Force activation
        NSApp.activate(ignoringOtherApps: true)
        
        // Setup window after a short delay to ensure it's created
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupMainWindow()
        }
        
        // Also observe for new windows in case the first attempt fails
        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let window = notification.object as? NSWindow,
                  window.frameAutosaveName.isEmpty else { return }
            
            self.configureWindow(window)
        }
    }
    
    private func setupMainWindow() {
        if let window = NSApp.windows.first(where: { $0.isKeyWindow || $0.isMainWindow }) ?? NSApp.windows.first {
            configureWindow(window)
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    private func configureWindow(_ window: NSWindow) {
        // 使用 NSWindow 原生的 frameAutosaveName 实现自动保存/恢复
        // 这是 macOS 推荐的方式，会自动持久化窗口位置和大小
        if !window.setFrameAutosaveName(windowAutosaveName) {
            // If autosave name already set, manually restore
            print("ℹ️ Window autosave name already in use")
        }
        
        // 恢复之前手动保存的 frame（作为备份）
        let defaults = UserDefaults.standard
        if let frameString = defaults.string(forKey: "PhotobookPro.MainWindowFrame") {
            let frame = NSRectFromString(frameString)
            if frame != .zero && frame.width > 200 && frame.height > 200 {
                // 检查 frame 是否在屏幕范围内
                if let screen = NSScreen.main, screen.visibleFrame.intersects(frame) {
                    window.setFrame(frame, display: true, animate: false)
                    print("📐 Restored window frame from UserDefaults: \(Int(frame.width))x\(Int(frame.height))")
                }
            }
        } else {
            // 设置合理的默认大小（居中显示）
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let defaultWidth: CGFloat = min(1400, screenFrame.width * 0.9)
                let defaultHeight: CGFloat = min(900, screenFrame.height * 0.9)
                let originX = screenFrame.origin.x + (screenFrame.width - defaultWidth) / 2
                let originY = screenFrame.origin.y + (screenFrame.height - defaultHeight) / 2
                let defaultFrame = NSRect(x: originX, y: originY, width: defaultWidth, height: defaultHeight)
                window.setFrame(defaultFrame, display: true, animate: false)
                print("📐 Using default frame: \(Int(defaultWidth))x\(Int(defaultHeight))")
            }
        }
        
        // 注册窗口大小/位置变化监听器
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize(_:)),
            name: NSWindow.didResizeNotification,
            object: window
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove(_:)),
            name: NSWindow.didMoveNotification,
            object: window
        )
    }
    
    @objc private func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        saveWindowFrame(window)
    }
    
    @objc private func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        saveWindowFrame(window)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Save window frame before closing
        if let window = NSApp.windows.first {
            saveWindowFrame(window)
        }
        if let observer = windowObserver {
            NotificationCenter.default.removeObserver(observer)
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
        // 忽略太小的窗口（可能是最小化状态）
        guard frame.width > 200 && frame.height > 200 else { return }
        
        let frameString = NSStringFromRect(frame)
        
        let defaults = UserDefaults.standard
        defaults.set(frameString, forKey: "PhotobookPro.MainWindowFrame")
        defaults.synchronize()
        
        // 只在调试时输出日志
        #if DEBUG
        print("💾 Saved window frame: \(Int(frame.width))x\(Int(frame.height))")
        #endif
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
            // Ensure the window content fills available space and is resizable
            .frame(minWidth: 1000, minHeight: 700)
            .onAppear {
                // Secondary check to force focus when view appears
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
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
    
    // Window frame persistence is now handled by AppDelegate
}
