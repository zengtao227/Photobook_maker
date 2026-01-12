import SwiftUI
import PhotosUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Photo Library Picker (macOS - Native Style)

/// A macOS-native photo library picker
struct PhotoLibraryPicker: View {
    @Binding var isPresented: Bool
    @Binding var selectedPhotos: [Photo]
    @State private var isLoading = false
    @State private var loadingProgress: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("选择照片")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Spacer()
            
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(loadingProgress)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    Text("从照片库或文件夹选择照片")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        // Photos Library Button
                        Button {
                            openPhotosPicker()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.stack")
                                    .font(.largeTitle)
                                Text("照片库")
                                    .font(.subheadline)
                            }
                            .frame(width: 120, height: 100)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        
                        // Folder Button
                        Button {
                            openFolderPicker()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "folder")
                                    .font(.largeTitle)
                                Text("文件夹")
                                    .font(.subheadline)
                            }
                            .frame(width: 120, height: 100)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        
                        // Individual Files Button
                        Button {
                            openFilePicker()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "doc.badge.plus")
                                    .font(.largeTitle)
                                Text("选择文件")
                                    .font(.subheadline)
                            }
                            .frame(width: 120, height: 100)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Spacer()
            
            // Footer
            HStack {
                Spacer()
                Button("取消") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func openPhotosPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0
        config.filter = .images
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        
        // Create window for picker
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "选择照片"
        window.contentViewController = picker
        window.center()
        
        // Create coordinator
        let coordinator = PhotoPickerCoordinator { photos in
            window.close()
            if !photos.isEmpty {
                self.selectedPhotos = photos
                self.isPresented = false
            }
        }
        picker.delegate = coordinator
        
        // Keep coordinator alive by associating with window
        objc_setAssociatedObject(window, "coordinator", coordinator, .OBJC_ASSOCIATION_RETAIN)
        
        // Show as sheet or window
        if let parentWindow = NSApp.keyWindow {
            parentWindow.beginSheet(window) { _ in }
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "选择包含照片的文件夹"
        panel.prompt = "选择"
        
        if panel.runModal() == .OK, let url = panel.url {
            isLoading = true
            loadingProgress = "正在扫描文件夹..."
            
            Task.detached {
                let photos = await self.loadPhotosFromFolder(url)
                await MainActor.run {
                    if !photos.isEmpty {
                        self.selectedPhotos = photos
                    }
                    self.isLoading = false
                    self.isPresented = false
                }
            }
        }
    }
    
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.image, .jpeg, .png, .heic]
        panel.message = "选择照片文件"
        panel.prompt = "选择"
        
        if panel.runModal() == .OK {
            let urls = panel.urls
            var photos: [Photo] = []
            for url in urls {
                let photo = Photo(url: url)
                photos.append(photo)
            }
            
            if !photos.isEmpty {
                self.selectedPhotos = photos
            }
            self.isPresented = false
        }
    }
    
    private func loadPhotosFromFolder(_ folderURL: URL) async -> [Photo] {
        var photos: [Photo] = []
        let imageExtensions = ["jpg", "jpeg", "png", "heic", "heif", "tiff", "tif"]
        
        // Use synchronous enumeration in a detached context
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        
        var urls: [URL] = []
        while let fileURL = enumerator.nextObject() as? URL {
            if imageExtensions.contains(fileURL.pathExtension.lowercased()) {
                urls.append(fileURL)
            }
        }
        
        for url in urls {
            let photo = Photo(url: url)
            photos.append(photo)
            
            await MainActor.run {
                self.loadingProgress = "已找到 \(photos.count) 张照片..."
            }
        }
        
        return photos
    }
}

// Coordinator for PHPickerViewController
private class PhotoPickerCoordinator: NSObject, PHPickerViewControllerDelegate {
    let completion: ([Photo]) -> Void
    
    init(completion: @escaping ([Photo]) -> Void) {
        self.completion = completion
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !results.isEmpty else {
            completion([])
            return
        }
        
        let group = DispatchGroup()
        var loadedPhotos: [Photo] = []
        let lock = NSLock()
        
        for result in results {
            if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                    defer { group.leave() }
                    
                    guard let sourceURL = url else { return }
                    
                    let fileName = UUID().uuidString + "." + sourceURL.pathExtension
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                    
                    do {
                        try FileManager.default.copyItem(at: sourceURL, to: tempURL)
                        let photo = Photo(url: tempURL)
                        
                        lock.lock()
                        loadedPhotos.append(photo)
                        lock.unlock()
                    } catch {
                        print("Error copying file: \(error)")
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            self.completion(loadedPhotos)
        }
    }
}
