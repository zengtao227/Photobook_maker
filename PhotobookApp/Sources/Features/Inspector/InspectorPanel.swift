import SwiftUI

struct InspectorPanel: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(BookContext.self) private var bookContext
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section: Book Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Book Settings")
                        .font(.headline)
                        .foregroundColor(themeManager.theme.textColor)
                    
                    // Preset Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Size Preset")
                            .font(.caption)
                            .foregroundColor(themeManager.theme.secondaryTextColor)
                        
                        Picker("", selection: Bindable(bookContext).pageSize) {
                            ForEach(BookPageSize.allCases) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                        .labelsHidden()
                    }
                    
                    // Custom Dimensions (Visible only if Custom)
                    if bookContext.pageSize == .custom {
                        HStack {
                            dimensionField("Width", value: Bindable(bookContext).customWidth)
                            dimensionField("Height", value: Bindable(bookContext).customHeight)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        // Read-only display
                        HStack {
                            Text("Dimensionss:")
                                .foregroundColor(themeManager.theme.secondaryTextColor)
                            Spacer()
                            Text(bookContext.dimensionString)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(themeManager.theme.textColor)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(themeManager.theme.backgroundColor.opacity(0.5))
                .cornerRadius(themeManager.theme.cornerRadius)
                
                // Placeholder for future sections
                Text("Design Elements (Coming Soon)")
                    .font(.subheadline)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
                    .padding(.top)
            }
            .padding()
        }
        .animation(.easeInOut, value: bookContext.pageSize)
    }
    
    private func dimensionField(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label + " (mm)")
                .font(.caption2)
                .foregroundColor(themeManager.theme.secondaryTextColor)
            TextField("", value: value, format: .number)
                .textFieldStyle(.roundedBorder)
        }
    }
}
