# PhotobookApp

A macOS native photo book creator for generating print-ready PDFs.

## Features

- Import photos from local folders
- Timeline view organized by month (based on EXIF date)
- Click to select photos for your photobook
- Multiple layout templates (1/2/3/4/6 photos per page)
- Export to 300 DPI print-ready PDF
- Support for A4, A5, A6, and square formats

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later

## How to Run

### Method 1: Using Xcode (Recommended)

1. Open Xcode
2. File → Open → Select the `PhotobookApp` folder
3. Wait for Swift Package to resolve
4. Click the Run button (▶) or press `Cmd + R`

### Method 2: Using Terminal

```bash
cd /Users/zengtao/Photobooks/PhotobookApp
swift build
swift run
```

Note: Terminal method may have limitations with macOS GUI apps.

## Project Structure

```
PhotobookApp/
├── Package.swift              # Swift Package manifest
├── README.md
└── Sources/
    ├── PhotobookApp.swift     # App entry point
    ├── ContentView.swift      # Main UI
    ├── Models/
    │   ├── Photo.swift        # Photo data model
    │   └── LayoutTemplate.swift # Page layout templates
    ├── Views/
    │   ├── PhotoGridView.swift      # Photo grid display
    │   └── SelectedPhotosView.swift # Selection panel
    └── Services/
        ├── PhotoStore.swift   # Main data store
        ├── EXIFReader.swift   # EXIF metadata reader
        └── PDFExporter.swift  # PDF generation
```

## Usage

1. **Import Photos**: Click "Import" or use `Cmd + O` to select a folder
2. **Browse Timeline**: Photos are organized by month in the sidebar
3. **Select Photos**: Click photos to add/remove from selection
4. **Export PDF**: Click "Export PDF" to save your photobook

## Supported Image Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)
- HEIC (.heic)
- TIFF (.tiff, .tif)

## Print Specifications

| Parameter | Value |
|-----------|-------|
| Resolution | 300 DPI |
| Color Space | sRGB |
| Bleed | 3mm |
| PDF Version | 1.5+ |

## Target Printers

This app generates PDFs compatible with:
- **Fotofabrik** (recommended) - A6 Hardcover up to 100 pages
- **epubli** - A6 up to 600+ pages
- Any printer accepting standard PDF files

## Development

Built with:
- Swift 5.9
- SwiftUI
- PDFKit
- ImageIO (EXIF reading)

## License

MIT License
