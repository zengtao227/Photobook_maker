import SwiftUI
import PhotosUI

struct StickerPickerView: View {
    @ObservedObject var stickerService: StickerService
    var onSelect: (Sticker) -> Void
    
    @State private var selectedCategory: String = "family"
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var categories: [StickerCategory] {
        stickerService.systemCategories + 
        [.init(id: "custom", name: "My Uploads", icon: "📤", type: .user)]
    }
    
    var displayStickers: [Sticker] {
        if selectedCategory == "custom" {
            return stickerService.userStickers
        }
        return stickerService.stickers.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.id) { cat in
                        Button(action: { selectedCategory = cat.id }) {
                            HStack(spacing: 4) {
                                Text(cat.icon)
                                Text(cat.name).font(.subheadline).fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedCategory == cat.id ? Color.blue : Color.gray.opacity(0.1))
                            .foregroundColor(selectedCategory == cat.id ? .white : .primary)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding()
            }
            .background(.regularMaterial)
            
            // Upload Button (Custom Tab Only)
            if selectedCategory == "custom" {
                Button(action: { showingImagePicker = true }) {
                    Label("Upload New Sticker", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .photosPicker(isPresented: $showingImagePicker, selection: $selectedItem, matching: .images)
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let image = PlatformImage(data: data) {
                            stickerService.addUserSticker(image: image)
                        }
                    }
                }
            }
            
            // Stickers Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                    ForEach(displayStickers) { sticker in
                        Button(action: { onSelect(sticker) }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.05))
                                    .aspectRatio(1, contentMode: .fit)
                                
                                if sticker.isEmoji {
                                    Text(sticker.content)
                                        .font(.system(size: 40))
                                } else {
                                    Image(systemName: "photo") // Placeholder for user image
                                        .resizable()
                                        .scaledToFit()
                                        .padding(8)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.white.opacity(0.8))
        .cornerRadius(20)
    }
}
