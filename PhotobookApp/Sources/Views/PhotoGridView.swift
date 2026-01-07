import SwiftUI

/// Grid view for displaying photos
struct PhotoGridView: View {
    let photos: [Photo]
    @EnvironmentObject var photoStore: PhotoStore

    private let columns = [
        GridItem(.adaptive(minimum: 120, maximum: 200), spacing: 8)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(photos) { photo in
                    PhotoThumbnailView(photo: photo)
                        .onTapGesture {
                            photoStore.toggleSelection(photo)
                        }
                }
            }
            .padding()
        }
    }
}

/// Single photo thumbnail with selection state
struct PhotoThumbnailView: View {
    let photo: Photo
    @EnvironmentObject var photoStore: PhotoStore

    private var isSelected: Bool {
        photoStore.selectedPhotos.contains(photo)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Photo thumbnail
            Group {
                if let thumbnail = photo.thumbnailImage {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        }
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            }

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .background(Circle().fill(.white))
                    .padding(4)
            }
        }
        .contentShape(Rectangle())
    }
}

/*
#Preview {
    PhotoGridView(photos: [])
        .environmentObject(PhotoStore())
}
*/
