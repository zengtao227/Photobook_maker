import SwiftUI

/// Export settings modal with professional options
struct ExportSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    @Environment(EditorState.self) private var editorState
    @Environment(LocalizationManager.self) private var localization
    
    @State private var config = ExportConfiguration.professionalPrint
    @State private var isExporting = false
    @State private var exportProgress = ExportProgress()
    @State private var showingFilePicker = false
    @State private var exportResult: ExportResult?
    @State private var showResultAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Presets
                    presetsSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Resolution Settings
                    resolutionSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Bleed Settings
                    bleedSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Export Mode
                    exportModeSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Print Marks
                    printMarksSection
                    
                    // Book Info
                    bookInfoSection
                }
                .padding(24)
            }
            
            Divider()
            
            // Footer with Export Button
            footerView
        }
        .frame(width: 520, height: 680)
        .background(themeManager.theme.panelColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .fileExporter(
            isPresented: $showingFilePicker,
            document: PDFExportDocument(),
            contentType: .pdf,
            defaultFilename: "Photobook_\(formattedDate).pdf"
        ) { result in
            handleExportResult(result)
        }
        .alert(localization.localized(.exportComplete), isPresented: $showResultAlert) {
            Button(localization.localized(.confirm)) { 
                if exportResult?.success == true {
                    dismiss()
                }
            }
            if let url = exportResult?.outputURL {
                Button(localization.localized(.showInFinder)) {
                    NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
                    dismiss()
                }
            }
        } message: {
            if let result = exportResult {
                if result.success {
                    Text("已成功导出 \(result.pageCount) 页\n文件大小: \(formatFileSize(result.fileSize ?? 0))")
                } else {
                    Text("导出失败: \(result.error?.localizedDescription ?? "未知错误")")
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(localization.localized(.exportPDF))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.theme.textColor)
                
                Text(localization.localized(.configureExport))
                    .font(.caption)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }
    
    // MARK: - Presets Section
    
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(localization.localized(.quickPresets), systemImage: "wand.and.stars")
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            
            HStack(spacing: 12) {
                PresetButton(
                    title: localization.localized(.screenPreview),
                    subtitle: "72 DPI",
                    icon: "display",
                    isSelected: config.dpi == 72 && !config.includeBleed
                ) {
                    config = .screenPreview
                }
                
                PresetButton(
                    title: localization.localized(.homePrint),
                    subtitle: "150 DPI",
                    icon: "printer",
                    isSelected: config.dpi == 150
                ) {
                    config = .homePrint
                }
                
                PresetButton(
                    title: localization.localized(.professionalPrint),
                    subtitle: "300 DPI + " + localization.localized(.includeBleed),
                    icon: "building.2",
                    isSelected: config.dpi == 300 && config.includeBleed
                ) {
                    config = .professionalPrint
                }
            }
        }
    }
    
    // MARK: - Resolution Section
    
    private var resolutionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(localization.localized(.resolution), systemImage: "square.resize")
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            
            HStack(spacing: 16) {
                ForEach(DPIPreset.allCases) { preset in
                    DPIOptionButton(
                        preset: preset,
                        isSelected: Int(config.dpi) == preset.rawValue
                    ) {
                        config.dpi = CGFloat(preset.rawValue)
                    }
                }
            }
            
            // Custom DPI slider
            HStack {
                Text(localization.localized(.customDPI))
                    .font(.caption)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
                
                Slider(value: $config.dpi, in: 72...600, step: 1)
                    .frame(width: 150)
                
                Text("\(Int(config.dpi)) DPI")
                    .font(.caption)
                    .foregroundColor(themeManager.theme.textColor)
                    .frame(width: 60)
            }
        }
    }
    
    // MARK: - Bleed Section
    
    private var bleedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(localization.localized(.bleedSettings), systemImage: "crop")
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            
            // Explanation text
            Text(localization.localized(.bleedExplanation))
                .font(.caption)
                .foregroundColor(themeManager.theme.secondaryTextColor)
                .padding(8)
                .background(themeManager.theme.searchFieldColor.opacity(0.5))
                .cornerRadius(6)
            
            Toggle(localization.localized(.includeBleed), isOn: $config.includeBleed)
                .toggleStyle(.switch)
                .foregroundColor(themeManager.theme.textColor)
            
            if config.includeBleed {
                HStack {
                    Text(localization.localized(.bleedMargin) + ":")
                        .font(.caption)
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                    
                    Picker("", selection: $config.bleedMM) {
                        Text("2mm").tag(CGFloat(2))
                        Text("3mm (" + (localization.currentLanguage == .chinese ? "标准" : "Standard") + ")").tag(CGFloat(3))
                        Text("5mm").tag(CGFloat(5))
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }
        }
    }
    
    // MARK: - Export Mode Section
    
    private var exportModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(localization.localized(.exportMode), systemImage: "doc.badge.gearshape")
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            
            VStack(spacing: 8) {
                ForEach(ExportMode.allCases, id: \.rawValue) { mode in
                    ExportModeRow(
                        mode: mode,
                        isSelected: config.exportMode == mode
                    ) {
                        config.exportMode = mode
                    }
                }
            }
        }
    }
    
    // MARK: - Print Marks Section
    
    private var printMarksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(localization.localized(.printMarks), systemImage: "target")
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            
            VStack(alignment: .leading, spacing: 12) {
                // Crop Marks
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(localization.localized(.cropMarks), isOn: $config.includeCropMarks)
                        .toggleStyle(.switch)
                        .foregroundColor(themeManager.theme.textColor)
                        .font(.subheadline)
                    Text(localization.localized(.cropMarksHelp))
                        .font(.caption2)
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                        .padding(.leading, 52)
                }
                
                // Registration Marks
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(localization.localized(.registrationMarks), isOn: $config.includeRegistrationMarks)
                        .toggleStyle(.switch)
                        .foregroundColor(themeManager.theme.textColor)
                        .font(.subheadline)
                    Text(localization.localized(.registrationMarksHelp))
                        .font(.caption2)
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                        .padding(.leading, 52)
                }
                
                // Color Bars
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(localization.localized(.colorBars), isOn: $config.includeColorBars)
                        .toggleStyle(.switch)
                        .foregroundColor(themeManager.theme.textColor)
                        .font(.subheadline)
                    Text(localization.localized(.colorBarsHelp))
                        .font(.caption2)
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                        .padding(.leading, 52)
                }
                
                // Page Info
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(localization.localized(.pageInfo), isOn: $config.includePageInfo)
                        .toggleStyle(.switch)
                        .foregroundColor(themeManager.theme.textColor)
                        .font(.subheadline)
                    Text(localization.localized(.pageInfoHelp))
                        .font(.caption2)
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                        .padding(.leading, 52)
                }
            }
        }
    }
    
    // MARK: - Book Info Section
    
    private var bookInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(localization.localized(.bookInfo), systemImage: "book.closed")
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            
            let totalPages = editorState.bookStructure.totalInnerPages + 2
            let bindingType = editorState.bookStructure.bindingType
            let isValidForSaddle = totalPages % 4 == 0
            
            let innerLabel = localization.currentLanguage == .chinese ? "内页" : "Inner"
            let totalLabel = localization.currentLanguage == .chinese ? "总页数" : "Total"
            let spineLabel = localization.currentLanguage == .chinese ? "书脊" : "Spine"
            let bindingLabel = localization.currentLanguage == .chinese ? "装订" : "Binding"
            let pagesUnit = localization.currentLanguage == .chinese ? "页" : "pages"
            
            HStack(spacing: 24) {
                InfoItem(label: innerLabel, value: "\(editorState.bookStructure.totalInnerPages) \(pagesUnit)")
                InfoItem(label: totalLabel, value: "\(totalPages) \(pagesUnit)")
                InfoItem(label: spineLabel, value: String(format: "%.1fmm", editorState.bookStructure.spineWidthMM))
                InfoItem(label: bindingLabel, value: bindingType.displayName(localization: localization))
            }
            .padding()
            .background(themeManager.theme.searchFieldColor.opacity(0.5))
            .cornerRadius(8)
            
            // Warning for saddle stitch
            if bindingType == .saddleStitch && !isValidForSaddle {
                let warningText = localization.currentLanguage == .chinese 
                    ? "骑马钉装订需要总页数为 4 的倍数，当前 \(totalPages) 页，将自动添加 \(4 - (totalPages % 4)) 页空白页"
                    : "Saddle stitch binding requires total pages to be a multiple of 4. Current: \(totalPages) pages. Will automatically add \(4 - (totalPages % 4)) blank pages."
                
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(warningText)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Imposition preview for saddle stitch
            if bindingType == .saddleStitch {
                impositionPreview
            }
        }
    }
    
    // MARK: - Imposition Preview (for Saddle Stitch)
    
    private var impositionPreview: some View {
        let totalPages = editorState.bookStructure.totalInnerPages + 2
        let sheets = SaddleStitchImposition.generateImposition(totalPages: totalPages)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(localization.localized(.impositionPreview), systemImage: "rectangle.split.2x2")
                    .font(.subheadline.bold())
                    .foregroundColor(themeManager.theme.textColor)
                
                Spacer()
                
                Text(localization.localized(.sheets(sheets.count)))
                    .font(.caption)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sheets, id: \.sheetNumber) { sheet in
                        ImpositionSheetPreview(sheet: sheet, totalPages: totalPages)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(themeManager.theme.searchFieldColor.opacity(0.3))
        .cornerRadius(8)
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            // Estimated file size
            VStack(alignment: .leading, spacing: 2) {
                Text(localization.localized(.estimatedSize))
                    .font(.caption)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
                Text(estimatedFileSize)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.theme.textColor)
            }
            
            Spacer()
            
            // Cancel Button
            Button(localization.localized(.cancel)) {
                dismiss()
            }
            .buttonStyle(.bordered)
            
            // Export Button
            Button(action: startExport) {
                HStack {
                    if isExporting {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Text(isExporting ? localization.localized(.exporting) : localization.localized(.exportPDF))
                }
                .frame(width: 120)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isExporting)
        }
        .padding(20)
    }
    
    // MARK: - Helpers
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmm"
        return formatter.string(from: Date())
    }
    
    private var estimatedFileSize: String {
        // Rough estimation based on DPI and page count
        let pageCount = editorState.bookStructure.totalInnerPages + 2 // +2 for covers
        let baseSize: Double = 2.0 // MB per page at 300 DPI
        let dpiMultiplier = pow(config.dpi / 300, 2)
        let estimated = Double(pageCount) * baseSize * dpiMultiplier
        
        if estimated < 1 {
            return String(format: "%.0f KB", estimated * 1024)
        } else if estimated < 1024 {
            return String(format: "%.1f MB", estimated)
        } else {
            return String(format: "%.2f GB", estimated / 1024)
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func startExport() {
        showingFilePicker = true
    }
    
    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            Task {
                await performExport(to: url)
            }
        case .failure(let error):
            exportResult = .failure(error: error)
            showResultAlert = true
        }
    }
    
    @MainActor
    private func performExport(to url: URL) async {
        isExporting = true
        let startTime = Date()
        
        do {
            // Save current state first
            editorState.saveCurrentState()
            
            let bindingType = editorState.bookStructure.bindingType
            
            // Create PDF config from export config
            var pdfConfig = PDFExportConfig.defaultA4
            pdfConfig.dpi = config.dpi
            pdfConfig.includeBleed = config.includeBleed
            pdfConfig.bleedMM = config.bleedMM
            pdfConfig.includeCropMarks = config.includeCropMarks
            pdfConfig.includeRegistrationMarks = config.includeRegistrationMarks
            pdfConfig.includeColorBars = config.includeColorBars
            pdfConfig.includePageInfo = config.includePageInfo
            
            var pageCount = 0
            
            if bindingType == .saddleStitch {
                // Use saddle stitch exporter with imposition
                try await SaddleStitchExporter.exportSaddleStitch(
                    bookStructure: editorState.bookStructure,
                    config: pdfConfig,
                    to: url
                ) { progress in
                    exportProgress.currentPage = Int(progress * Double(editorState.bookStructure.innerSpreads.count + 1))
                    exportProgress.totalPages = editorState.bookStructure.innerSpreads.count + 1
                }
                
                let totalPages = editorState.bookStructure.totalInnerPages + 2
                let adjustedTotal = ((totalPages + 3) / 4) * 4
                pageCount = adjustedTotal / 2 // Each sheet has 2 PDF pages (front + back)
                
            } else {
                // Use standard spread exporter for other binding types
                var spreadsToExport: [(left: PageModel, right: PageModel)] = []
                
                // Add cover spread
                spreadsToExport.append((left: editorState.bookStructure.backCover, 
                                        right: editorState.bookStructure.frontCover))
                
                // Add inner spreads
                spreadsToExport.append(contentsOf: editorState.bookStructure.innerSpreads)
                
                try await SpreadPDFExporter.exportBook(
                    spreads: spreadsToExport,
                    config: pdfConfig,
                    to: url
                ) { progress in
                    exportProgress.currentPage = Int(progress * Double(spreadsToExport.count))
                    exportProgress.totalPages = spreadsToExport.count
                }
                
                pageCount = spreadsToExport.count
            }
            
            // Get file size
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            let duration = Date().timeIntervalSince(startTime)
            exportResult = .success(url: url, fileSize: fileSize, pageCount: pageCount, duration: duration)
            
        } catch {
            exportResult = .failure(error: error)
        }
        
        isExporting = false
        showResultAlert = true
    }
}

// MARK: - Supporting Views

struct PresetButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(themeManager.theme.secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? themeManager.theme.accentColor.opacity(0.2) : themeManager.theme.searchFieldColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? themeManager.theme.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? themeManager.theme.accentColor : themeManager.theme.textColor)
    }
}

struct DPIOptionButton: View {
    let preset: DPIPreset
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        Button(action: action) {
            Text("\(preset.rawValue)")
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? themeManager.theme.accentColor : themeManager.theme.searchFieldColor)
                .foregroundColor(isSelected ? .white : themeManager.theme.textColor)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct ExportModeRow: View {
    let mode: ExportMode
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(ThemeManager.self) private var themeManager
    @Environment(LocalizationManager.self) private var localization
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? themeManager.theme.accentColor : themeManager.theme.secondaryTextColor)
                
                Image(systemName: mode.icon)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.displayName(localization: localization))
                        .fontWeight(.medium)
                    Text(mode.description(localization: localization))
                        .font(.caption)
                        .foregroundColor(themeManager.theme.secondaryTextColor)
                }
                
                Spacer()
            }
            .padding(10)
            .background(isSelected ? themeManager.theme.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .foregroundColor(themeManager.theme.textColor)
    }
}

struct InfoItem: View {
    let label: String
    let value: String
    
    @Environment(ThemeManager.self) private var themeManager
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundColor(themeManager.theme.textColor)
            Text(label)
                .font(.caption)
                .foregroundColor(themeManager.theme.secondaryTextColor)
        }
    }
}

// MARK: - PDF Export Document (for file exporter)

struct PDFExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    
    init() {}
    
    init(configuration: ReadConfiguration) throws {
        // Not used for export
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Return empty wrapper - actual export happens separately
        return FileWrapper(regularFileWithContents: Data())
    }
}

import UniformTypeIdentifiers


// MARK: - Imposition Sheet Preview

struct ImpositionSheetPreview: View {
    let sheet: SaddleStitchImposition.PrintSheet
    let totalPages: Int
    
    @Environment(LocalizationManager.self) private var localization
    
    private let adjustedTotal: Int
    
    init(sheet: SaddleStitchImposition.PrintSheet, totalPages: Int) {
        self.sheet = sheet
        self.totalPages = totalPages
        self.adjustedTotal = ((totalPages + 3) / 4) * 4
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Sheet number
            Text(localization.localized(.sheet(sheet.sheetNumber)))
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
            
            // Front side
            HStack(spacing: 2) {
                pageCell(sheet.frontLeft)
                pageCell(sheet.frontRight)
            }
            
            Text(localization.localized(.frontSide))
                .font(.system(size: 7))
                .foregroundColor(.secondary)
            
            // Back side
            HStack(spacing: 2) {
                pageCell(sheet.backLeft)
                pageCell(sheet.backRight)
            }
            
            Text(localization.localized(.backSide))
                .font(.system(size: 7))
                .foregroundColor(.secondary)
        }
        .padding(6)
        .background(Color.white)
        .cornerRadius(6)
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
    
    private func pageCell(_ pageNum: Int) -> some View {
        let isBlank = pageNum > totalPages
        let isCover = pageNum == 1 || pageNum == totalPages
        
        return ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(isBlank ? Color.gray.opacity(0.2) : (isCover ? Color.blue.opacity(0.2) : Color.green.opacity(0.2)))
                .frame(width: 24, height: 32)
            
            if isBlank {
                Text(localization.localized(.blank))
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
            } else {
                Text("\(pageNum)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isCover ? .blue : .green)
            }
        }
    }
}
