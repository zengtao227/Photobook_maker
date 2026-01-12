//
//  CropEditor.swift
//  PhotobookApp
//
//  Created by Antigravity on 2026/01/07.
//

import SwiftUI

struct CropEditor: View {
    let layer: PhotoLayer
    let onSave: (Double, CGSize, CGRect?, Double, CGRect?) -> Void
    let onCancel: () -> Void
    
    // Geometry State
    @State private var imageSize: CGSize = .zero
    @State private var cropRect: CGRect = .zero
    @State private var rotationAngle: Double = 0.0
    @State private var isReady: Bool = false
    @State private var loadError: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if loadError {
                    errorView
                } else if let image = NSImage(contentsOf: layer.photoUrl) {
                    mainContent(image: image, geometry: geometry)
                } else {
                    loadingView
                        .onAppear {
                            // 延迟检查加载失败
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                if !isReady {
                                    loadError = true
                                }
                            }
                        }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    @ViewBuilder
    private func mainContent(image: NSImage, geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Fixed Header with close button
            HStack {
                Button(action: onCancel) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                        Text("关闭")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Text("裁剪与调整")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isReady {
                    Text("\(Int(cropRect.width)) × \(Int(cropRect.height))")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .padding()
            .background(Color.black.opacity(0.8))
            
            // Main editing area
            ZStack {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .rotationEffect(.degrees(rotationAngle))
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { initialize(size: geo.size) }
                                .onChange(of: geo.size) { _, newSize in 
                                    if !isReady {
                                        initialize(size: newSize) 
                                    }
                                }
                        }
                    )
                    .padding(60)
                
                if isReady && imageSize.width > 0 {
                    CropOverlayView(cropRect: $cropRect, imageSize: imageSize)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Fixed bottom controls
            VStack(spacing: 16) {
                // Rotation slider
                HStack(spacing: 12) {
                    Image(systemName: "rotate.left")
                        .foregroundColor(.white)
                    Slider(value: $rotationAngle, in: -180...180)
                        .tint(.white)
                    Image(systemName: "rotate.right")
                        .foregroundColor(.white)
                    Text("\(Int(rotationAngle))°")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 40)
                }
                .padding(.horizontal, 40)
                
                // Action buttons - always visible
                HStack(spacing: 16) {
                    // Cancel button
                    Button(action: onCancel) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                            Text("取消")
                        }
                        .frame(minWidth: 100)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                    
                    // Reset button
                    Button {
                        withAnimation {
                            cropRect = CGRect(origin: .zero, size: imageSize)
                            rotationAngle = 0
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("重置")
                        }
                        .frame(minWidth: 100)
                        .padding(.vertical, 12)
                        .background(Color.yellow.opacity(0.2))
                        .foregroundColor(.yellow)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    // Done button
                    Button(action: commit) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                            Text("完成")
                        }
                        .frame(minWidth: 120)
                        .fontWeight(.semibold)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.return, modifiers: [])
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 20)
            .background(Color.black.opacity(0.9))
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Text("正在加载图片...")
                .foregroundColor(.white)
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("无法加载图片")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("图片文件可能已损坏或不存在")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Button(action: onCancel) {
                HStack {
                    Image(systemName: "xmark")
                    Text("关闭")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
    }
    
    private func initialize(size: CGSize) {
        guard size.width > 0 && !isReady else { return }
        DispatchQueue.main.async {
            self.imageSize = size
            
            // RESTORE PREVIOUS CROP IF EXISTS
            if let normRect = layer.normalizedCropRect {
                self.cropRect = CGRect(
                    x: normRect.origin.x * size.width,
                    y: normRect.origin.y * size.height,
                    width: normRect.size.width * size.width,
                    height: normRect.size.height * size.height
                )
            } else {
                self.cropRect = CGRect(origin: .zero, size: size)
            }
            
            // USE INTERNAL CROP ROTATION (NOT CANVAS ROTATION)
            self.rotationAngle = layer.cropRotation
            self.isReady = true
        }
    }
    
    private func commit() {
        guard isReady else { return }
        
        // Calculate Normalized Rect for Persistence
        let normX = cropRect.minX / imageSize.width
        let normY = cropRect.minY / imageSize.height
        let normW = cropRect.width / imageSize.width
        let normH = cropRect.height / imageSize.height
        let normalizedRect = CGRect(x: normX, y: normY, width: normW, height: normH)
        
        let cx = normX + normW / 2.0
        let cy = normY + normH / 2.0
        
        let newAR = cropRect.width / cropRect.height
        let newFrame = CGRect(x: layer.frame.minX, y: layer.frame.minY, width: layer.frame.width, height: layer.frame.width / newAR)
        
        let scale = 1.0 / normW
        let ox = (0.5 - cx) * newFrame.width * scale
        let oy = (0.5 - cy) * newFrame.height * scale
        
        onSave(scale, CGSize(width: ox, height: oy), newFrame, rotationAngle, normalizedRect)
    }
}

struct CropOverlayView: View {
    @Binding var cropRect: CGRect
    let imageSize: CGSize
    
    var body: some View {
        ZStack {
            // Background Mask (The "Dark" part)
            Path { path in
                path.addRect(CGRect(origin: .zero, size: imageSize))
                path.addRect(cropRect)
            }
            .fill(Color.black.opacity(0.6), style: FillStyle(eoFill: true))
            
            // Grid Lines and Border
            ZStack {
                Rectangle().stroke(Color.white, lineWidth: 2)
                
                // Thirds lines
                Path { p in
                    let w = cropRect.width; let h = cropRect.height
                    p.move(to: CGPoint(x: w/3, y: 0)); p.addLine(to: CGPoint(x: w/3, y: h))
                    p.move(to: CGPoint(x: 2*w/3, y: 0)); p.addLine(to: CGPoint(x: 2*w/3, y: h))
                    p.move(to: CGPoint(x: 0, y: h/3)); p.addLine(to: CGPoint(x: w, y: h/3))
                    p.move(to: CGPoint(x: 0, y: 2*h/3)); p.addLine(to: CGPoint(x: w, y: 2*h/3))
                }
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
            }
            .frame(width: cropRect.width, height: cropRect.height)
            .position(x: cropRect.midX, y: cropRect.midY)
            
            // Handles (Highest Priority)
            HandlesLayer(rect: $cropRect, bounds: CGRect(origin: .zero, size: imageSize))
        }
        .frame(width: imageSize.width, height: imageSize.height)
    }
}

struct HandlesLayer: View {
    @Binding var rect: CGRect
    let bounds: CGRect
    @State private var start: CGRect?
    
    var body: some View {
        ZStack {
            // Drag Area (Center)
            Rectangle()
                .fill(Color.white.opacity(0.001))
                .frame(width: max(1, rect.width - 40), height: max(1, rect.height - 40))
                .position(x: rect.midX, y: rect.midY)
                .gesture(DragGesture().onChanged { v in
                    if start == nil { start = rect }
                    var nr = start!
                    nr.origin.x = max(bounds.minX, min(nr.origin.x + v.translation.width, bounds.maxX - nr.width))
                    nr.origin.y = max(bounds.minY, min(nr.origin.y + v.translation.height, bounds.maxY - nr.height))
                    rect = nr
                }.onEnded { _ in start = nil })
            
            // Corner Handles
            CornerH(rect: $rect, bounds: bounds, dragging: $start, corner: .tl)
            CornerH(rect: $rect, bounds: bounds, dragging: $start, corner: .tr)
            CornerH(rect: $rect, bounds: bounds, dragging: $start, corner: .bl)
            CornerH(rect: $rect, bounds: bounds, dragging: $start, corner: .br)
        }
    }
}

struct CornerH: View {
    @Binding var rect: CGRect; let bounds: CGRect; @Binding var dragging: CGRect?; enum C { case tl, tr, bl, br }; let corner: C
    var body: some View {
        ZStack {
            Color.white.opacity(0.001).frame(width: 44, height: 44)
            ZStack {
                Rectangle().fill(.white).frame(width: 4, height: 20).offset(x: ox, y: 0)
                Rectangle().fill(.white).frame(width: 20, height: 4).offset(x: 0, y: oy)
            }
        }
        .position(x: px, y: py)
        .gesture(DragGesture().onChanged { v in
            if dragging == nil { dragging = rect }
            guard let s = dragging else { return }
            var n = s; let minS: CGFloat = 20
            switch corner {
            case .tl: 
                let nx = max(bounds.minX, min(s.minX + v.translation.width, s.maxX - minS))
                let ny = max(bounds.minY, min(s.minY + v.translation.height, s.maxY - minS))
                n = CGRect(x: nx, y: ny, width: s.maxX - nx, height: s.maxY - ny)
            case .tr:
                let nw = max(minS, min(s.width + v.translation.width, bounds.maxX - s.minX))
                let ny = max(bounds.minY, min(s.minY + v.translation.height, s.maxY - minS))
                n = CGRect(x: s.minX, y: ny, width: nw, height: s.maxY - ny)
            case .bl:
                let nx = max(bounds.minX, min(s.minX + v.translation.width, s.maxX - minS))
                let nh = max(minS, min(s.height + v.translation.height, bounds.maxY - s.minY))
                n = CGRect(x: nx, y: s.minY, width: s.maxX - nx, height: nh)
            case .br:
                let nw = max(minS, min(s.width + v.translation.width, bounds.maxX - s.minX))
                let nh = max(minS, min(s.height + v.translation.height, bounds.maxY - s.minY))
                n = CGRect(x: s.minX, y: s.minY, width: nw, height: nh)
            }
            rect = n
        }.onEnded { _ in dragging = nil })
    }
    private var px: CGFloat { (corner == .tl || corner == .bl) ? rect.minX : rect.maxX }
    private var py: CGFloat { (corner == .tl || corner == .tr) ? rect.minY : rect.maxY }
    private var ox: CGFloat { (corner == .tl || corner == .bl) ? -8 : 8 }
    private var oy: CGFloat { (corner == .tl || corner == .tr) ? -8 : 8 }
}
