import SwiftUI

public enum AppThemeMode: String, CaseIterable, Identifiable {
    case studio
    case glass
    
    public var id: String { rawValue }
}

public struct AppTheme {
    public let mode: AppThemeMode
    
    // MARK: - Core Colors
    public let backgroundColor: Color
    public let panelColor: Color
    public let accentColor: Color
    public let secondaryAccentColor: Color
    public let textColor: Color
    public let secondaryTextColor: Color
    public let searchFieldColor: Color
    
    // MARK: - Layout Metrics
    public let panelVideoOpacity: CGFloat
    public let cornerRadius: CGFloat
    public let shadowRadius: CGFloat
    
    public static let studio = AppTheme(
        mode: .studio,
        backgroundColor: Color(hex: "FDFBF7"), // Warm White / Cream
        panelColor: .white,
        accentColor: Color(hex: "CDA882"),     // Matte Gold
        secondaryAccentColor: Color(hex: "E0D4C5"),
        textColor: Color(hex: "1A1A1A"),
        secondaryTextColor: Color(hex: "666666"),
        searchFieldColor: Color(hex: "F5F5F0"),
        panelVideoOpacity: 1.0,
        cornerRadius: 8,
        shadowRadius: 4
    )
    
    public static let glass = AppTheme(
        mode: .glass,
        backgroundColor: Color(hex: "0F172A"), // Midnight Blue / Deep Space
        panelColor: Color(hex: "1E293B").opacity(0.6), // Frosted Glass
        accentColor: Color(hex: "A855F7"),     // Electric Purple
        secondaryAccentColor: Color(hex: "38BDF8"), // Cyan
        textColor: .white,
        secondaryTextColor: Color.white.opacity(0.7),
        searchFieldColor: Color.white.opacity(0.1),
        panelVideoOpacity: 0.7,
        cornerRadius: 16,
        shadowRadius: 10
    )
}

// MARK: - Helper Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
