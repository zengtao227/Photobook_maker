import SwiftUI

// MARK: - Bleed Guide Overlay

struct BleedGuideOverlay: View {
    let bleedPoints: CGFloat
    let pageSize: CGSize
    
    var body: some View {
        ZStack {
            Rectangle()
                .stroke(
                    Color.red.opacity(0.6),
                    style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                )
                .frame(width: pageSize.width, height: pageSize.height)
            
            Rectangle()
                .stroke(
                    Color.red.opacity(0.8),
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                )
                .frame(
                    width: pageSize.width - bleedPoints * 2,
                    height: pageSize.height - bleedPoints * 2
                )
            
            VStack {
                HStack {
                    BleedLabel(text: "裁切线 (3mm)")
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    BleedLabel(text: "安全区域")
                }
                .padding(.bottom, bleedPoints + 4)
                .padding(.trailing, bleedPoints + 4)
            }
            .padding(4)
        }
    }
}

// MARK: - Bleed Label

struct BleedLabel: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.red)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.white.opacity(0.85))
            .cornerRadius(3)
    }
}
