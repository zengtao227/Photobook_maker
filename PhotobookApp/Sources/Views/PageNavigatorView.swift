import SwiftUI

/// A filmstrip-style page navigator that integrates with EditorState
/// for multi-spread management (Phase 3)
struct PageNavigatorView: View {
    @Environment(EditorState.self) private var editorState
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Spread thumbnails
                    ForEach(Array(editorState.allSpreads.enumerated()), id: \.offset) { index, spread in
                        SpreadThumbnailItem(
                            spreadIndex: index,
                            leftPage: spread.left,
                            rightPage: spread.right,
                            isActive: editorState.currentSpreadIndex == index,
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    editorState.navigateToSpread(index)
                                }
                            },
                            onDelete: editorState.spreadCount > 1 ? {
                                withAnimation {
                                    editorState.deleteSpread(at: index)
                                }
                            } : nil
                        )
                        .id(index)
                    }
                    
                    // Add New Spread Button
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            editorState.addNewSpread()
                        }
                        // Scroll to the new spread
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(editorState.spreadCount - 1, anchor: .trailing)
                            }
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(themeManager.theme.accentColor)
                            Text("新建页面")
                                .font(.caption2)
                                .foregroundColor(themeManager.theme.secondaryTextColor)
                        }
                        .frame(width: 100, height: 70)
                        .background(themeManager.theme.searchFieldColor.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundColor(themeManager.theme.accentColor.opacity(0.5))
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(
                themeManager.currentMode == .studio
                    ? Color(white: 0.12)
                    : themeManager.theme.panelColor
            )
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.white.opacity(0.1)),
                alignment: .top
            )
            // Scroll to active spread on appear
            .onAppear {
                proxy.scrollTo(editorState.currentSpreadIndex, anchor: .center)
            }
        }
        .frame(height: 100)
    }
}

/// Thumbnail item showing a spread (left + right page)
struct SpreadThumbnailItem: View {
    let spreadIndex: Int
    let leftPage: PageModel
    let rightPage: PageModel
    let isActive: Bool
    let action: () -> Void
    let onDelete: (() -> Void)?
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                // Spread preview (two-page layout)
                HStack(spacing: 1) {
                    // Left page
                    SpreadPageMiniature(page: leftPage)
                    
                    // Spine indicator
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 2)
                    
                    // Right page
                    SpreadPageMiniature(page: rightPage)
                }
                .frame(width: 100, height: 70)
                .background(Color.white)
                .cornerRadius(6)
                .shadow(
                    color: isActive ? .blue.opacity(0.4) : .black.opacity(0.15),
                    radius: isActive ? 6 : 3,
                    y: isActive ? 2 : 1
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isActive ? Color.blue : Color.clear, lineWidth: 2)
                )
                
                // Page number badge
                Text("\(spreadIndex + 1)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(isActive ? Color.blue : Color.black.opacity(0.6))
                    .cornerRadius(4)
                    .offset(x: -4, y: 4)
                
                // Delete button (on hover)
                if let onDelete = onDelete, isHovering {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.red)
                            .background(Color.white.clipShape(Circle()))
                    }
                    .buttonStyle(.plain)
                    .offset(x: 8, y: -8)
                }
            }
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isActive)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

/// Miniature representation of a single page
struct SpreadPageMiniature: View {
    let page: PageModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(hex: page.backgroundColorHex) ?? .white
                
                // Layer indicators (simplified)
                ForEach(page.layers.prefix(3)) { wrapper in
                    if let photoLayer = wrapper.layer as? PhotoLayer {
                        // Show tiny colored rectangles to represent layers
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(
                                width: max(8, geometry.size.width * (photoLayer.frame.width / 400)),
                                height: max(6, geometry.size.height * (photoLayer.frame.height / 300))
                            )
                            .position(
                                x: geometry.size.width * (photoLayer.frame.midX / 400),
                                y: geometry.size.height * (photoLayer.frame.midY / 300)
                            )
                    } else if let textLayer = wrapper.layer as? TextLayer {
                        Rectangle()
                            .fill(Color.orange.opacity(0.4))
                            .frame(width: 15, height: 4)
                            .position(
                                x: geometry.size.width * (textLayer.frame.midX / 400),
                                y: geometry.size.height * (textLayer.frame.midY / 300)
                            )
                    }
                }
                
                // Layer count badge
                if page.layers.count > 0 {
                    Text("\(page.layers.count)")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.7))
                        .cornerRadius(2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(2)
                }
            }
        }
    }
}

// MARK: - Legacy Support (for backward compatibility)

/// Legacy PhotoPage support - converts to/from spread model
extension PageNavigatorView {
    /// Create a standalone navigator with PhotoPage array (legacy mode)
    init(pages: Binding<[PhotoPage]>, activePageId: Binding<UUID?>) {
        // This initializer is for legacy support only
        // New code should use the EditorState-based version
        self.init()
    }
}
