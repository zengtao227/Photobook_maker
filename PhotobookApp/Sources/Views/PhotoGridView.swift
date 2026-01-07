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
        VStack(spacing: 6) {
            // Calculate true aspect ratio from metadata if available
            let aspectRatio: CGFloat = {
                if let w = photo.width, let h = photo.height, w > 0, h > 0 {
                    let ratio = CGFloat(w) / CGFloat(h)
                    print("DEBUG THUMBNAIL: \(photo.filename) - \(w)x\(h), ratio: \(ratio)")
                    return ratio
                }
                print("DEBUG THUMBNAIL: \(photo.filename) - NO DIMENSIONS, using 1.0")
                return 1.0 // Fallback
            }()
            
            if let thumbnail = photo.thumbnailImage {
                Image(nsImage: thumbnail)
                    .resizable()
                    // CRITICAL: Force the View to respect the Metadata Aspect Ratio
                    // This overrides any potential square-cropping in the thumbnail data itself
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.accentColor, lineWidth: 3)
                        }
                    }
                    .frame(minHeight: 100) // Ensure it's not too small
            } else {
                // Placeholder matches the ratio too
                Color.gray.opacity(0.1)
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .frame(minHeight: 100)
            }
            
            // Minimalist Label
            Text(photo.filename)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .padding(.horizontal, 4)
        }
        .padding(4)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                withAnimation {
                    photoStore.deletePhoto(photo)
                }
            } label: {
                Label("Delete from Library", systemImage: "trash")
            }
        }
    }
}

/*
#Preview {
    PhotoGridView(photos: [])
        .environmentObject(PhotoStore())
}
*/
