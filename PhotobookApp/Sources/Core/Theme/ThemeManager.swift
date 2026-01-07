import SwiftUI
import Observation

@Observable
public class ThemeManager {
    public var currentMode: AppThemeMode = .studio
    
    public var theme: AppTheme {
        switch currentMode {
        case .studio:
            return .studio
        case .glass:
            return .glass
        }
    }
    
    public init() {}
    
    public func toggleTheme() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentMode = (currentMode == .studio) ? .glass : .studio
        }
    }
    
    public func setMode(_ mode: AppThemeMode) {
        withAnimation(.easeInOut) {
            currentMode = mode
        }
    }
    
    // View Modifier Integration
    public struct Provider: ViewModifier {
        @State private var manager = ThemeManager()
        
        public func body(content: Content) -> some View {
            content
                .environment(manager)
                .preferredColorScheme(manager.currentMode == .studio ? .light : .dark)
        }
    }
}

public extension View {
    func withTheme() -> some View {
        modifier(ThemeManager.Provider())
    }
}
