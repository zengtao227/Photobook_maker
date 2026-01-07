import SwiftUI

/// View showing selected photos and layout preview
struct SelectedPhotosView: View {
    @EnvironmentObject var photoStore: PhotoStore
    @State private var selectedPageSize: PageSize = .a6Landscape

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Selected: \(photoStore.selectedPhotos.count) photos")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    photoStore.clearSelection()
                }
                .buttonStyle(.borderless)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Page size picker
            HStack {
                Text("Page Size:")
                Picker("", selection: $selectedPageSize) {
                    Text("A6 Landscape").tag(PageSize.a6Landscape)
                    Text("A5 Landscape").tag(PageSize.a5Landscape)
                    Text("A4 Landscape").tag(PageSize.a4Landscape)
                    Text("Square (21cm)").tag(PageSize.squareMedium)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Selected photos list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(photoStore.selectedPhotos.enumerated()), id: \.element.id) { index, photo in
                        HStack {
                            Text("\(index + 1)")
                                .foregroundColor(.secondary)
                                .frame(width: 30)

                            if let thumbnail = photo.thumbnailImage {
                                Image(nsImage: thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }

                            VStack(alignment: .leading) {
                                Text(photo.filename)
                                    .lineLimit(1)
                                if let date = photo.dateTaken {
                                    Text(date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Button {
                                photoStore.toggleSelection(photo)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical)
            }

            Divider()

            // Export info
            VStack(spacing: 4) {
                let pageCount = estimatePageCount(photoStore.selectedPhotos.count)
                Text("Estimated pages: \(pageCount)")
                    .font(.caption)
                Text("Size: \(selectedPageSize.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .frame(minWidth: 300)
    }

    private func estimatePageCount(_ photoCount: Int) -> Int {
        // Average 3 photos per page
        return max(1, (photoCount + 2) / 3)
    }
}

// Make PageSize conform to Hashable for Picker
extension PageSize: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(displayName)
    }

    static func == (lhs: PageSize, rhs: PageSize) -> Bool {
        lhs.displayName == rhs.displayName
    }
}

/*
#Preview {
    SelectedPhotosView()
        .environmentObject(PhotoStore())
}
*/
