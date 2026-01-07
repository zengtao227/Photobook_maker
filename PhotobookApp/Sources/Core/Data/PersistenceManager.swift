import Foundation

/// The root object for the entire project state
public struct ProjectData: Codable {
    var pageSize: BookPageSize
    var customWidth: Double
    var customHeight: Double
    var leftPage: PageModel
    var rightPage: PageModel
    var photos: [Photo] // We persist the library list too
}

/// Metadata for a project (for list display)
public struct ProjectMetadata: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var createdAt: Date
    public var modifiedAt: Date
    public var fileName: String // e.g. "project-uuid.json"
    
    public init(id: UUID = UUID(), name: String, fileName: String) {
        self.id = id
        self.name = name
        self.fileName = fileName
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

public class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let fileManager = FileManager.default
    
    // Projects directory
    private var projectsDirectory: URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("PhotobookPro")
            .appendingPathComponent("Projects")
    }
    
    // Project index file (stores list of all projects)
    private var projectIndexURL: URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("PhotobookPro")
            .appendingPathComponent("project-index.json")
    }
    
    private init() {
        createDirectoryIfNeeded()
        migrateOldAutosaveIfNeeded()
    }
    
    private func createDirectoryIfNeeded() {
        guard let url = projectsDirectory else { return }
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
    
    // Migrate old autosave.json to new project system
    private func migrateOldAutosaveIfNeeded() {
        let oldURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("PhotobookPro")
            .appendingPathComponent("autosave.json")
        
        guard let oldURL = oldURL, fileManager.fileExists(atPath: oldURL.path) else { return }
        
        // If index is empty, migrate
        if loadProjectIndex().isEmpty {
            print("Migrating old autosave.json to new project system...")
            if let data = try? Data(contentsOf: oldURL),
               let _ = try? JSONDecoder().decode(ProjectData.self, from: data) {
                let meta = ProjectMetadata(name: "我的项目", fileName: "project-\(UUID().uuidString).json")
                let index = [meta]
                saveProjectIndex(index)
                
                // Copy file
                if let newURL = projectsDirectory?.appendingPathComponent(meta.fileName) {
                    try? fileManager.copyItem(at: oldURL, to: newURL)
                    try? fileManager.removeItem(at: oldURL) // Clean up
                    print("Migration complete: \(meta.name)")
                }
            }
        }
    }
    
    // MARK: - Project Index Management
    
    public func loadProjectIndex() -> [ProjectMetadata] {
        guard let url = projectIndexURL, fileManager.fileExists(atPath: url.path) else {
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([ProjectMetadata].self, from: data)
        } catch {
            print("Failed to load project index: \(error)")
            return []
        }
    }
    
    private func saveProjectIndex(_ index: [ProjectMetadata]) {
        guard let url = projectIndexURL else { return }
        do {
            let data = try JSONEncoder().encode(index)
            try data.write(to: url)
        } catch {
            print("Failed to save project index: \(error)")
        }
    }
    
    // MARK: - Project CRUD
    
    public func createNewProject(name: String) -> ProjectMetadata {
        let meta = ProjectMetadata(name: name, fileName: "project-\(UUID().uuidString).json")
        var index = loadProjectIndex()
        index.append(meta)
        saveProjectIndex(index)
        return meta
    }
    
    public func deleteProject(_ meta: ProjectMetadata) {
        // Remove from index
        var index = loadProjectIndex()
        index.removeAll { $0.id == meta.id }
        saveProjectIndex(index)
        
        // Delete file
        if let url = projectsDirectory?.appendingPathComponent(meta.fileName) {
            try? fileManager.removeItem(at: url)
        }
    }
    
    public func renameProject(_ meta: ProjectMetadata, newName: String) {
        var index = loadProjectIndex()
        if let idx = index.firstIndex(where: { $0.id == meta.id }) {
            index[idx].name = newName
            index[idx].modifiedAt = Date()
            saveProjectIndex(index)
        }
    }
    
    // MARK: - Load/Save Project Data
    
    @MainActor
    func save(project: ProjectMetadata, bookContext: BookContext, editorState: EditorState, photoStore: PhotoStore) {
        let data = ProjectData(
            pageSize: bookContext.pageSize,
            customWidth: bookContext.customWidth,
            customHeight: bookContext.customHeight,
            leftPage: editorState.leftPage,
            rightPage: editorState.rightPage,
            photos: photoStore.allPhotos
        )
        
        guard let url = projectsDirectory?.appendingPathComponent(project.fileName) else { return }
        
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: url)
            
            // Update modified time in index
            var index = loadProjectIndex()
            if let idx = index.firstIndex(where: { $0.id == project.id }) {
                index[idx].modifiedAt = Date()
                saveProjectIndex(index)
            }
            
            print("Saved project: \(project.name)")
        } catch {
            print("Failed to save project: \(error)")
        }
    }
    
    func load(project: ProjectMetadata) -> ProjectData? {
        guard let url = projectsDirectory?.appendingPathComponent(project.fileName),
              fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let projectData = try JSONDecoder().decode(ProjectData.self, from: data)
            print("Loaded project: \(project.name)")
            return projectData
        } catch {
            print("Failed to load project: \(error)")
            return nil
        }
    }
    
    // MARK: - Legacy API (for backward compatibility)
    
    @MainActor
    func save(bookContext: BookContext, editorState: EditorState, photoStore: PhotoStore) {
        // This is called by the toolbar save button
        // We need to know which project is currently open
        // For now, we'll skip this or use a "current project" reference
        print("Warning: Legacy save called without project context")
    }
}
