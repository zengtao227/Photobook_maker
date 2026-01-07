import SwiftUI

struct TimelineBar: View {
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(1..<10) { i in
                    VStack {
                        Rectangle()
                            .fill(Color.white)
                            .aspectRatio(1.5, contentMode: .fit)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(themeManager.theme.secondaryAccentColor, lineWidth: 1)
                            )
                        Text("Page \(i)")
                            .font(.caption)
                            .foregroundColor(themeManager.theme.secondaryTextColor)
                    }
                    .frame(height: 80)
                }
            }
            .padding()
        }
    }
}
