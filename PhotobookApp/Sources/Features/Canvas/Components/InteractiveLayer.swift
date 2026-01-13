import SwiftUI

struct InteractiveLayer: View {
    let wrapper: AnyLayer
    let isLeftPage: Bool
    let scale: CGFloat
    let logicalPageSize: CGSize
    @Environment(EditorState.self) private var editorState
    @Environment(LocalizationManager.self) private var localization
    
    @State private var transientFrame: CGRect? = nil
    @State private var transientRotation: Double? = nil
    
    private func toDisplayFrame(_ logicalFrame: CGRect) -> CGRect {
        CGRect(
            x: logicalFrame.origin.x * scale,
            y: logicalFrame.origin.y * scale,
            width: logicalFrame.size.width * scale,
            height: logicalFrame.size.height * scale
        )
    }
    
    private func toLogicalFrame(_ displayFrame: CGRect) -> CGRect {
        CGRect(
            x: displayFrame.origin.x / scale,
            y: displayFrame.origin.y / scale,
            width: displayFrame.size.width / scale,
            height: displayFrame.size.height / scale
        )
    }
    
    private var currentLayer: (any LayerProtocol)? {
        let _ = editorState.updateCounter
        let pageModel = isLeftPage ? editorState.leftPage : editorState.rightPage
        return pageModel.layers.first(where: { $0.id == wrapper.id })?.layer
    }
    
    var body: some View {
        if let photoLayer = currentLayer as? PhotoLayer {
            photoLayerView(photoLayer)
        } else if let textLayer = currentLayer as? TextLayer {
            textLayerView(textLayer)
        } else if let stickerLayer = currentLayer as? StickerLayer {
            stickerLayerView(stickerLayer)
        }
    }
}

// MARK: - Photo Layer View
extension InteractiveLayer {
    @ViewBuilder
    private func photoLayerView(_ photoLayer: PhotoLayer) -> some View {
        let displayFrame = transientFrame ?? toDisplayFrame(photoLayer.frame)
        let rotation = transientRotation ?? photoLayer.rotation
        let isSelected = editorState.selectedLayerId == photoLayer.id
        let isCropping = editorState.croppingLayerId == photoLayer.id
        
        ZStack {
            if isCropping {
                PhotoLayerElement(layer: photoLayer)
                    .frame(width: displayFrame.width, height: displayFrame.height)
                    .clipped()
                    .opacity(0.3)
                    .allowsHitTesting(false)
            } else {
                PhotoLayerElement(layer: photoLayer)
                    .frame(width: displayFrame.width, height: displayFrame.height)
                    .clipped()
                    .contentShape(Rectangle())
                
                if isSelected {
                    SelectionBorder(
                        frame: Binding(get: { displayFrame }, set: { transientFrame = $0 }),
                        rotation: Binding(get: { rotation }, set: { transientRotation = $0 }),
                        onCommitFrame: {
                            if let finalDisplayFrame = transientFrame {
                                editorState.updateLayerFrame(photoLayer.id, newFrame: toLogicalFrame(finalDisplayFrame))
                                transientFrame = nil
                            }
                        },
                        onCommitRotation: {
                            if let finalRot = transientRotation {
                                editorState.updateLayerRotation(photoLayer.id, newRotation: finalRot)
                                transientRotation = nil
                            }
                        }
                    )
                    .frame(width: displayFrame.width, height: displayFrame.height)
                }
            }
        }
        .position(x: displayFrame.midX, y: displayFrame.midY)
        .rotationEffect(Angle(degrees: rotation), anchor: .center)
        .zIndex(isCropping ? 9999 : (Double(photoLayer.zIndex) + (isSelected ? 100 : 0)))
        .highPriorityGesture(TapGesture(count: 2).onEnded { editorState.startCropping(photoLayer.id) })
        .gesture(photoDragGesture(photoLayer: photoLayer, isSelected: isSelected, isCropping: isCropping, rotation: rotation))
        .simultaneousGesture(TapGesture().onEnded { 
            if !isCropping { 
                editorState.selectLayer(photoLayer.id)
                editorState.activePageSide = isLeftPage ? .left : .right
            } 
        })
        .contextMenu { photoContextMenu(photoLayer) }
    }
    
    private func photoDragGesture(photoLayer: PhotoLayer, isSelected: Bool, isCropping: Bool, rotation: Double) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard isSelected, !isCropping else { return }
                let radians = -rotation * .pi / 180.0
                let cos = Darwin.cos(radians)
                let sin = Darwin.sin(radians)
                let adjustedX = value.translation.width * cos - value.translation.height * sin
                let adjustedY = value.translation.width * sin + value.translation.height * cos
                let originalDisplayFrame = toDisplayFrame(photoLayer.frame)
                var newDisplayFrame = originalDisplayFrame
                newDisplayFrame.origin.x += adjustedX
                newDisplayFrame.origin.y += adjustedY
                transientFrame = newDisplayFrame
            }
            .onEnded { _ in
                guard isSelected, !isCropping else { return }
                if let finalDisplayFrame = transientFrame {
                    editorState.updateLayerFrame(photoLayer.id, newFrame: toLogicalFrame(finalDisplayFrame))
                    transientFrame = nil
                }
            }
    }
    
    @ViewBuilder
    private func photoContextMenu(_ photoLayer: PhotoLayer) -> some View {
        Button { editorState.cutSelectedLayer() } label: { 
            Label(localization.localized(.cut), systemImage: "scissors") 
        }
        .keyboardShortcut("x", modifiers: .command)
        
        Button { editorState.copySelectedLayer() } label: { 
            Label(localization.localized(.copy), systemImage: "doc.on.doc") 
        }
        .keyboardShortcut("c", modifiers: .command)
        
        Button { editorState.duplicateSelectedLayer() } label: { 
            Label(localization.localized(.duplicate), systemImage: "plus.square.on.square") 
        }
        .keyboardShortcut("d", modifiers: .command)
        
        Divider()
        
        Button { editorState.moveLayerToFront(photoLayer.id) } label: { 
            Label(localization.localized(.bringToFront), systemImage: "square.3.layers.3d.top.filled") 
        }
        Button { editorState.moveLayerForward(photoLayer.id) } label: { 
            Label(localization.localized(.bringForward), systemImage: "arrow.up.square") 
        }
        Button { editorState.moveLayerBackward(photoLayer.id) } label: { 
            Label(localization.localized(.sendBackward), systemImage: "arrow.down.square") 
        }
        Button { editorState.moveLayerToBack(photoLayer.id) } label: { 
            Label(localization.localized(.sendToBack), systemImage: "square.3.layers.3d.bottom.filled") 
        }
        
        Divider()
        
        Button { editorState.startCropping(photoLayer.id) } label: { 
            Label(localization.localized(.crop), systemImage: "crop") 
        }
        Button { editorState.startFiltering(photoLayer.id) } label: { 
            Label(localization.localized(.filter), systemImage: "camera.filters") 
        }
        
        Divider()
        
        Button(role: .destructive) { editorState.deleteSelectedLayer() } label: { 
            Label(localization.localized(.delete), systemImage: "trash") 
        }
        .keyboardShortcut(.delete, modifiers: [])
    }
}

// MARK: - Text Layer View
extension InteractiveLayer {
    @ViewBuilder
    private func textLayerView(_ textLayer: TextLayer) -> some View {
        let displayFrame = transientFrame ?? toDisplayFrame(textLayer.frame)
        let rotation = transientRotation ?? textLayer.rotation
        let isSelected = editorState.selectedLayerId == textLayer.id
        let isEditing = editorState.editingTextLayerId == textLayer.id
        
        ZStack {
            if isEditing {
                InlineTextEditor(
                    layer: textLayer,
                    onCommit: { newText in
                        editorState.updateTextContent(id: textLayer.id, text: newText)
                        editorState.endTextEditing()
                    },
                    onCancel: { editorState.endTextEditing() }
                )
                .frame(width: displayFrame.width, height: displayFrame.height)
            } else {
                TextLayerElement(layer: textLayer)
            }
            
            if isSelected && !isEditing {
                SelectionBorder(
                    frame: Binding(get: { displayFrame }, set: { transientFrame = $0 }),
                    rotation: Binding(get: { rotation }, set: { transientRotation = $0 }),
                    lockAspectRatio: false,
                    onCommitFrame: {
                        if let finalDisplayFrame = transientFrame {
                            editorState.updateLayerFrame(textLayer.id, newFrame: toLogicalFrame(finalDisplayFrame))
                        }
                        transientFrame = nil
                    },
                    onCommitRotation: {
                        if let rot = transientRotation {
                            editorState.updateLayerRotation(textLayer.id, newRotation: rot)
                        }
                        transientRotation = nil
                    }
                )
            }
        }
        .frame(width: displayFrame.width, height: displayFrame.height)
        .rotationEffect(.degrees(rotation))
        .position(x: displayFrame.midX, y: displayFrame.midY)
        .gesture(textDragGesture(textLayer: textLayer, isEditing: isEditing))
        .simultaneousGesture(TapGesture().onEnded { editorState.selectLayer(textLayer.id) })
        .simultaneousGesture(TapGesture(count: 2).onEnded { editorState.startTextEditing(textLayer.id) })
        .contextMenu { textContextMenu(textLayer) }
    }
    
    private func textDragGesture(textLayer: TextLayer, isEditing: Bool) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !isEditing {
                    if transientFrame == nil { transientFrame = toDisplayFrame(textLayer.frame) }
                    let originalDisplayFrame = toDisplayFrame(textLayer.frame)
                    let newOrigin = CGPoint(
                        x: originalDisplayFrame.origin.x + value.translation.width,
                        y: originalDisplayFrame.origin.y + value.translation.height
                    )
                    transientFrame = CGRect(origin: newOrigin, size: originalDisplayFrame.size)
                }
            }
            .onEnded { _ in
                if let finalDisplayFrame = transientFrame {
                    editorState.updateLayerFrame(textLayer.id, newFrame: toLogicalFrame(finalDisplayFrame))
                }
                transientFrame = nil
            }
    }
    
    @ViewBuilder
    private func textContextMenu(_ textLayer: TextLayer) -> some View {
        Button { editorState.startTextEditing(textLayer.id) } label: { 
            Label(localization.localized(.editText), systemImage: "pencil") 
        }
        
        Divider()
        
        Button { editorState.cutSelectedLayer() } label: { 
            Label(localization.localized(.cut), systemImage: "scissors") 
        }
        .keyboardShortcut("x", modifiers: .command)
        
        Button { editorState.copySelectedLayer() } label: { 
            Label(localization.localized(.copy), systemImage: "doc.on.doc") 
        }
        .keyboardShortcut("c", modifiers: .command)
        
        Button { editorState.duplicateSelectedLayer() } label: { 
            Label(localization.localized(.duplicate), systemImage: "plus.square.on.square") 
        }
        .keyboardShortcut("d", modifiers: .command)
        
        Divider()
        
        Button { editorState.moveLayerToFront(textLayer.id) } label: { 
            Label(localization.localized(.bringToFront), systemImage: "square.3.layers.3d.top.filled") 
        }
        Button { editorState.moveLayerToBack(textLayer.id) } label: { 
            Label(localization.localized(.sendToBack), systemImage: "square.3.layers.3d.bottom.filled") 
        }
        
        Divider()
        
        Button(role: .destructive) { editorState.deleteSelectedLayer() } label: { 
            Label(localization.localized(.delete), systemImage: "trash") 
        }
        .keyboardShortcut(.delete, modifiers: [])
    }
}

// MARK: - Sticker Layer View
extension InteractiveLayer {
    @ViewBuilder
    private func stickerLayerView(_ stickerLayer: StickerLayer) -> some View {
        let displayFrame = transientFrame ?? toDisplayFrame(stickerLayer.frame)
        let rotation = transientRotation ?? stickerLayer.rotation
        let isSelected = editorState.selectedLayerId == stickerLayer.id
        
        ZStack {
            StickerLayerElement(layer: stickerLayer)
                .frame(width: displayFrame.width, height: displayFrame.height)
                .contentShape(Rectangle())
            
            if isSelected {
                SelectionBorder(
                    frame: Binding(get: { displayFrame }, set: { transientFrame = $0 }),
                    rotation: Binding(get: { rotation }, set: { transientRotation = $0 }),
                    onCommitFrame: {
                        if let finalDisplayFrame = transientFrame {
                            editorState.updateLayerFrame(stickerLayer.id, newFrame: toLogicalFrame(finalDisplayFrame))
                            transientFrame = nil
                        }
                    },
                    onCommitRotation: {
                        if let finalRot = transientRotation {
                            editorState.updateLayerRotation(stickerLayer.id, newRotation: finalRot)
                            transientRotation = nil
                        }
                    }
                )
                .frame(width: displayFrame.width, height: displayFrame.height)
            }
        }
        .position(x: displayFrame.midX, y: displayFrame.midY)
        .rotationEffect(Angle(degrees: rotation), anchor: .center)
        .zIndex(Double(stickerLayer.zIndex) + (isSelected ? 100 : 0))
        .gesture(stickerDragGesture(stickerLayer: stickerLayer, isSelected: isSelected))
        .simultaneousGesture(TapGesture().onEnded { editorState.selectLayer(stickerLayer.id) })
        .contextMenu { stickerContextMenu(stickerLayer) }
    }
    
    private func stickerDragGesture(stickerLayer: StickerLayer, isSelected: Bool) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard isSelected else { return }
                if transientFrame == nil { transientFrame = toDisplayFrame(stickerLayer.frame) }
                let originalDisplayFrame = toDisplayFrame(stickerLayer.frame)
                var newFrame = originalDisplayFrame
                newFrame.origin.x += value.translation.width
                newFrame.origin.y += value.translation.height
                transientFrame = newFrame
            }
            .onEnded { _ in
                guard isSelected else { return }
                if let finalDisplayFrame = transientFrame {
                    editorState.updateLayerFrame(stickerLayer.id, newFrame: toLogicalFrame(finalDisplayFrame))
                    transientFrame = nil
                }
            }
    }
    
    @ViewBuilder
    private func stickerContextMenu(_ stickerLayer: StickerLayer) -> some View {
        Button { editorState.cutSelectedLayer() } label: { 
            Label(localization.localized(.cut), systemImage: "scissors") 
        }
        .keyboardShortcut("x", modifiers: .command)
        
        Button { editorState.copySelectedLayer() } label: { 
            Label(localization.localized(.copy), systemImage: "doc.on.doc") 
        }
        .keyboardShortcut("c", modifiers: .command)
        
        Button { editorState.duplicateSelectedLayer() } label: { 
            Label(localization.localized(.duplicate), systemImage: "plus.square.on.square") 
        }
        .keyboardShortcut("d", modifiers: .command)
        
        Divider()
        
        Button { editorState.moveLayerToFront(stickerLayer.id) } label: { 
            Label(localization.localized(.bringToFront), systemImage: "square.3.layers.3d.top.filled") 
        }
        Button { editorState.moveLayerToBack(stickerLayer.id) } label: { 
            Label(localization.localized(.sendToBack), systemImage: "square.3.layers.3d.bottom.filled") 
        }
        
        Divider()
        
        Button(role: .destructive) { editorState.deleteSelectedLayer() } label: { 
            Label(localization.localized(.delete), systemImage: "trash") 
        }
        .keyboardShortcut(.delete, modifiers: [])
    }
}
