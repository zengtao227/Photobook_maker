import SwiftUI

struct ContentView: View {
    @EnvironmentObject var photoStore: PhotoStore
    @State private var selectedMonth: String?

    var body: some View {
        NavigationSplitView {
            // Left sidebar: Month list
            List(selection: $selectedMonth) {
                ForEach(photoStore.monthGroups, id: \.month) { group in
                    HStack {
                        Text(group.month)
                            .font(.headline)
                        Spacer()
                        Text("\(group.photos.count)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .tag(group.month)
                }
            }
            .navigationTitle("Timeline")
            .frame(minWidth: 200)
        } content: {
            // Middle: Photo grid
            if let month = selectedMonth,
               let group = photoStore.monthGroups.first(where: { $0.month == month }) {
                PhotoGridView(photos: group.photos)
                    .navigationTitle(month)
            } else {
                ContentUnavailableView(
                    "Select a Month",
                    systemImage: "calendar",
                    description: Text("Choose a month from the sidebar to view photos")
                )
            }
        } detail: {
            // Right: Selected photos / Layout preview
            if photoStore.selectedPhotos.isEmpty {
                ContentUnavailableView(
                    "No Photos Selected",
                    systemImage: "photo.on.rectangle",
                    description: Text("Select photos to add to your photobook")
                )
            } else {
                SelectedPhotosView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { photoStore.showFolderPicker = true }) {
                    Label("Import", systemImage: "folder.badge.plus")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: exportPDF) {
                    Label("Export PDF", systemImage: "arrow.down.doc")
                }
                .disabled(photoStore.selectedPhotos.isEmpty)
            }
        }
        .fileImporter(
            isPresented: $photoStore.showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        await photoStore.importFiles([url])
                    }
                }
            case .failure(let error):
                print("Error selecting folder: \(error)")
            }
        }
    }

    private func exportPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "Photobook.pdf"

        if panel.runModal() == .OK, let url = panel.url {
            Task {
                await PDFExporter.export(
                    photos: photoStore.selectedPhotos,
                    to: url,
                    pageSize: .a6Landscape
                )
            }
        }
    }
}

/*
#Preview {
    ContentView()
        .environmentObject(PhotoStore())
}
*/
