import SwiftUI

struct PageNavigatorView: View {
    @Binding var pages: [PhotoPage]
    @Binding var activePageId: UUID?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(pages) { page in
                    PageThumbnailItem(
                        page: page,
                        isActive: activePageId == page.id,
                        action: { activePageId = page.id }
                    )
                    // Drag and Drop is complex in SwiftUI 
                    // Use .onDrag and .onDrop in a full implementation
                }
                
                // Add Page Button
                Button(action: {
                    let newPage = PhotoPage(id: UUID(), order: pages.count)
                    pages.append(newPage)
                    activePageId = newPage.id
                }) {
                    VStack {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                    .frame(width: 80, height: 60)
                    .background(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundColor(.gray)
                    )
                }
            }
            .padding()
        }
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .top
        )
    }
}

struct PageThumbnailItem: View {
    let page: PhotoPage
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 80, height: 60)
                    .shadow(color: isActive ? .blue.opacity(0.5) : .black.opacity(0.1), radius: isActive ? 8 : 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isActive ? Color.blue : Color.clear, lineWidth: 2)
                    )
                
                Text(String(page.order + 1))
                    .font(.caption2)
                    .bold()
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(4)
            }
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.spring(), value: isActive)
        }
    }
}
