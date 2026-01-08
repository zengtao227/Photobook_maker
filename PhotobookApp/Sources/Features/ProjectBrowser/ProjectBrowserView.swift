import SwiftUI

/// 项目浏览器 - App 启动首页
struct ProjectBrowserView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LocalizationManager.self) private var localization
    @State private var projects: [ProjectMetadata] = []
    @State private var showNewProjectDialog = false
    @State private var newProjectName = ""
    
    // 重命名状态
    @State private var renamingProject: ProjectMetadata? = nil
    @State private var renameText = ""
    
    let onOpenProject: (ProjectMetadata) -> Void
    
    var body: some View {
        ZStack {
            themeManager.theme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localization.localized(.myProjects))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(themeManager.theme.textColor)
                        Text(localization.localized(.projectCount(projects.count)))
                            .font(.subheadline)
                            .foregroundColor(themeManager.theme.secondaryTextColor)
                    }
                    
                    Spacer()
                    
                    // Language Selector
                    Menu {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Button(action: {
                                localization.setLanguage(language)
                            }) {
                                HStack {
                                    Text(language.flag)
                                    Text(language.displayName)
                                    if localization.currentLanguage == language {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(localization.currentLanguage.flag)
                                .font(.title3)
                            Text(localization.currentLanguage.displayName)
                                .font(.subheadline)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(themeManager.theme.searchFieldColor)
                        .cornerRadius(8)
                        .foregroundColor(themeManager.theme.textColor)
                    }
                    .buttonStyle(.plain)
                    .help(localization.localized(.selectLanguage))
                    
                    // Open Projects Folder Button
                    Button(action: openProjectsFolder) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                            Text(localization.localized(.projectFolder))
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(themeManager.theme.searchFieldColor)
                        .cornerRadius(8)
                        .foregroundColor(themeManager.theme.textColor)
                    }
                    .buttonStyle(.plain)
                    .help(localization.localized(.projectFolderHelp))
                    
                    // Theme Toggle
                    Button(action: {
                        themeManager.toggleTheme()
                    }) {
                        Image(systemName: themeManager.currentMode == .studio ? "sun.max.fill" : "moon.stars.fill")
                            .font(.title3)
                            .padding(10)
                            .background(themeManager.theme.searchFieldColor)
                            .clipShape(Circle())
                            .foregroundColor(themeManager.theme.textColor)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                // Project Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 280, maximum: 320), spacing: 20)
                    ], spacing: 20) {
                        // New Project Card
                        NewProjectCard {
                            showNewProjectDialog = true
                        }
                        .environment(localization)
                        
                        // Existing Projects
                        ForEach(projects) { project in
                            ProjectCard(
                                project: project,
                                onOpen: {
                                    onOpenProject(project)
                                },
                                onDelete: {
                                    deleteProject(project)
                                },
                                onRename: {
                                    renamingProject = project
                                    renameText = project.name
                                }
                            )
                            .environment(localization)
                        }
                    }
                    .padding(40)
                }
            }
        }
        .onAppear {
            loadProjects()
        }
        
        // MARK: - Custom Modal Overlays
        
        // New Project Dialog Overlay
        if showNewProjectDialog {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { showNewProjectDialog = false }
                .overlay(
                NewProjectDialog(
                        projectName: $newProjectName,
                        onCreate: {
                            createNewProject()
                        },
                        onCancel: {
                            showNewProjectDialog = false
                        }
                    )
                    .environment(localization)
                )
                .zIndex(100)
        }
        
        // Rename Project Dialog Overlay
        if let project = renamingProject {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { renamingProject = nil }
                .overlay(
                    RenameProjectDialog(
                        projectName: $renameText,
                        onRename: {
                            renameProject(project, newName: renameText)
                        },
                        onCancel: {
                            renamingProject = nil
                        }
                    )
                    .environment(localization)
                )
                .zIndex(100)
        }
    }
    
    private func loadProjects() {
        projects = PersistenceManager.shared.loadProjectIndex()
            .sorted { $0.modifiedAt > $1.modifiedAt } // Most recent first
    }
    
    private func createNewProject() {
        let name = newProjectName.isEmpty ? localization.localized(.defaultProjectName) : newProjectName
        let meta = PersistenceManager.shared.createNewProject(name: name)
        projects.insert(meta, at: 0)
        newProjectName = ""
        showNewProjectDialog = false
        
        // Auto-open new project
        onOpenProject(meta)
    }
    
    private func deleteProject(_ project: ProjectMetadata) {
        PersistenceManager.shared.deleteProject(project)
        projects.removeAll { $0.id == project.id }
    }
    
    private func renameProject(_ project: ProjectMetadata, newName: String) {
        guard !newName.isEmpty else { return }
        PersistenceManager.shared.renameProject(project, newName: newName)
        
        // Update local list
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx].name = newName
        }
        renamingProject = nil
    }
    
    private func openProjectsFolder() {
        if let projectsDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("PhotobookPro")
            .appendingPathComponent("Projects") {
            NSWorkspace.shared.open(projectsDir)
        }
    }
}

// MARK: - Project Card

struct ProjectCard: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LocalizationManager.self) private var localization
    let project: ProjectMetadata
    let onOpen: () -> Void
    let onDelete: () -> Void
    let onRename: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail Preview
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.theme.searchFieldColor)
                    .aspectRatio(1.5, contentMode: .fit)
                
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 48))
                    .foregroundColor(themeManager.theme.secondaryTextColor.opacity(0.3))
            }
            
            // Project Info
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)
                    .foregroundColor(themeManager.theme.textColor)
                    .lineLimit(1)
                
                Text(formatDate(project.modifiedAt))
                    .font(.caption)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.theme.panelColor)
                .shadow(color: .black.opacity(isHovering ? 0.15 : 0.05), radius: 12, y: 4)
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            onOpen()
        }
        .contextMenu {
            Button(localization.localized(.open), systemImage: "arrow.right.square") {
                onOpen()
            }
            
            Button(localization.localized(.rename), systemImage: "pencil") {
                onRename()
            }
            
            Button(localization.localized(.showInFinder), systemImage: "folder") {
                showInFinder()
            }
            
            Divider()
            
            Button(localization.localized(.delete), systemImage: "trash", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private func showInFinder() {
        // Get project file path
        if let projectsDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("PhotobookPro")
            .appendingPathComponent("Projects") {
            let projectFile = projectsDir.appendingPathComponent(project.fileName)
            NSWorkspace.shared.selectFile(projectFile.path, inFileViewerRootedAtPath: projectsDir.path)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - New Project Card

struct NewProjectCard: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LocalizationManager.self) private var localization
    let onCreate: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(themeManager.theme.secondaryTextColor)
            
            Text(localization.localized(.newProject))
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundColor(themeManager.theme.secondaryTextColor.opacity(0.5))
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            onCreate()
        }
    }
}

// MARK: - New Project Dialog

// MARK: - New Project Dialog

struct NewProjectDialog: View {
    @Environment(LocalizationManager.self) private var localization
    @Binding var projectName: String
    let onCreate: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(localization.localized(.newProject))
                .font(.title2.bold())
                .foregroundColor(.black)
            
            MacTextField(
                placeholder: localization.localized(.projectName),
                text: $projectName,
                onCommit: {
                    onCreate()
                },
                onCancel: {
                    onCancel()
                }
            )
            .frame(width: 300, height: 24)
            
            HStack(spacing: 12) {
                Button(localization.localized(.cancel)) {
                    onCancel()
                }
                .keyboardShortcut(.escape)
                
                Button(localization.localized(.create)) {
                    onCreate()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 20)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

// MARK: - Rename Project Dialog

struct RenameProjectDialog: View {
    @Environment(LocalizationManager.self) private var localization
    @Binding var projectName: String
    let onRename: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(localization.localized(.rename))
                .font(.title2.bold())
                .foregroundColor(.black)
            
            MacTextField(
                placeholder: localization.localized(.projectName),
                text: $projectName,
                onCommit: {
                    onRename()
                },
                onCancel: {
                    onCancel()
                }
            )
            .frame(width: 300, height: 24)
            
            HStack(spacing: 12) {
                Button(localization.localized(.cancel)) {
                    onCancel()
                }
                .keyboardShortcut(.escape)
                
                Button(localization.localized(.save)) {
                    onRename()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(projectName.isEmpty)
            }
        }
        .padding(30)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 20)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

