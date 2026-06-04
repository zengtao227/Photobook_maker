# Photobook Maker Development Plan

_Last updated: 2026-06-04_

This document summarizes the current direction of `Photobook_maker` and proposes a practical development roadmap for improving PDF generation quality, export efficiency, maintainability, and future extensibility.

The goal of this document is to help the next development session — human or AI-assisted — quickly understand what to improve next and why.

---

## 1. Current Project Positioning

`Photobook_maker` is already more than a simple image-to-PDF script. It is a macOS native Swift / SwiftUI photo book creator focused on generating print-ready PDF files.

Current capabilities include:

- Importing local photos.
- Organizing photos by EXIF date / timeline.
- Selecting photos for a photobook.
- Multiple photo layout templates, such as 1 / 2 / 3 / 4 / 6 photos per page.
- Exporting 300 DPI print-ready PDFs.
- Supporting A4, A5, A6, and square formats.
- Supporting bleed, crop marks, registration marks, and color bars.
- Supporting double-sided and saddle-stitch booklet export.
- Targeting print providers such as Fotofabrik and epubli.

The current implementation is already strong in the area of practical PDF generation for personal photo books, especially compared with many small open-source projects that only combine images into a PDF.

---

## 2. Current Export Architecture Observations

The current export pipeline appears to follow this general pattern:

1. Prepare page or spread data.
2. Preload original or filtered images.
3. Render SwiftUI / Canvas content using `ImageRenderer`.
4. Convert the rendered result into `CGImage` / `NSImage`.
5. Insert the rendered image into a `PDFDocument` as a `PDFPage`.
6. Write the PDF file to disk.

This approach is practical and reliable, but it has several limitations:

- The whole page or spread becomes one large raster image inside the PDF.
- Text, crop marks, page numbers, and vector-like elements are rasterized.
- PDF files can become larger than necessary.
- Re-exporting can be slow because images and filters may be recalculated.
- Export logic is partly duplicated across spread, double-sided, and saddle-stitch exporters.
- PDF generation, imposition, rendering, and image preparation are currently tightly coupled.

The next development stage should focus on separating these responsibilities.

---

## 3. Recommended Architecture Direction

The project should gradually move toward a modular export architecture.

Recommended modules:

```text
PhotoBookApp
├── Import
│   ├── PhotoImportService
│   └── EXIFReader
├── Layout
│   ├── LayoutTemplate
│   ├── TemplatePreset
│   └── AutoLayoutEngine
├── Rendering
│   ├── PageRenderService
│   ├── SpreadRenderService
│   └── PreviewRenderService
├── Export
│   ├── PDFExportConfig
│   ├── RasterPDFExporter
│   ├── VectorPDFExporter
│   ├── PDFWriteService
│   └── ExportPresetService
├── Imposition
│   ├── ImpositionService
│   ├── SaddleStitchImposition
│   ├── SequentialDoubleSidedImposition
│   └── BlankPagePaddingService
├── Preflight
│   ├── PDFPreflightChecker
│   ├── ImageResolutionChecker
│   └── PrintProviderCompatibilityChecker
└── Cache
    ├── ImageCacheService
    ├── FilteredImageCache
    └── ThumbnailCache
```

The main idea is:

- Rendering should not decide page order.
- Imposition should not render images.
- PDF writing should not know about UI state.
- Filters and image preparation should be cached and reusable.
- Export presets should describe print requirements instead of being hard-coded across exporters.

---

## 4. Highest Priority Improvements

### 4.1 Add Image and Filter Caching

Current export logic preloads filtered images before export. This is correct, but expensive if repeated often.

Add a cache key based on:

```text
photoUrl
fileModificationDate
filterType
brightness
contrast
saturation
vignetteIntensity
sharpenIntensity
temperature
targetPixelSize
```

Expected benefits:

- Faster repeated exports.
- Faster preview updates.
- Less duplicated filter processing.
- Better responsiveness when adjusting export settings.

Suggested implementation:

```swift
struct FilteredImageCacheKey: Hashable {
    let photoURL: URL
    let fileModificationDate: Date?
    let filterType: FilterType
    let brightness: Double
    let contrast: Double
    let saturation: Double
    let vignetteIntensity: Double
    let sharpenIntensity: Double
    let temperature: Double
    let targetPixelSize: CGSize
}
```

Then create a dedicated `FilteredImageCache` service used by all exporters.

Priority: **Very high**

---

### 4.2 Refactor the PDF Export Pipeline

Currently, `SpreadPDFExporter`, `SequentialDoubleSidedExporter`, and `SaddleStitchExporter` appear to share similar responsibilities.

Recommended target pipeline:

```text
BookStructure
    ↓
PageSequenceBuilder
    ↓
ImpositionService
    ↓
PageRenderService / SpreadRenderService
    ↓
PDFWriteService
    ↓
Final PDF
```

Suggested services:

#### `PageSequenceBuilder`

Builds a normal logical page sequence:

```text
front cover
inner page 1
inner page 2
...
back cover
```

#### `ImpositionService`

Transforms the logical page sequence into a print sequence:

- Normal single-page PDF.
- Spread PDF.
- Sequential double-sided PDF.
- Saddle-stitch imposed PDF.
- Future hardcover cover / dust jacket layout.

#### `PDFWriteService`

Receives rendered page images or vector drawing commands and writes the final PDF.

Expected benefits:

- Less duplicated export logic.
- Easier to add new print modes.
- Easier to test imposition separately.
- Easier for other AI tools to reason about the code.

Priority: **Very high**

---

### 4.3 Add Export Preflight Checks

Before exporting, the app should run a preflight check similar to professional print software.

Recommended checks:

- Page size is correct.
- Bleed is enabled and set to expected value.
- DPI is 300 or higher.
- All images are available.
- No missing image files.
- No unsupported image formats.
- Low-resolution image warning.
- Saddle-stitch page count is a multiple of 4 after padding.
- Export mode matches the selected print provider.
- Text and important objects are inside the safe area.
- File size estimate is reasonable.

Example UI result:

```text
Preflight Result

✅ Page size: A6
✅ DPI: 300
✅ Bleed: 3 mm
✅ Total pages: 48
✅ Saddle-stitch compatible: yes
⚠️ 3 photos may be below recommended print resolution
⚠️ 1 text layer is close to trim edge
```

Expected benefits:

- Fewer bad print exports.
- Easier debugging.
- More confidence before ordering from Fotofabrik or epubli.

Priority: **High**

---

### 4.4 Keep Raster Export, Add Experimental Vector Export

The current raster-based export method should be kept because it is simple and reliable.

However, add a second export mode:

```text
Export Method
- Standard Raster Export
- Experimental High-Quality Export
```

The high-quality exporter should eventually:

- Draw background colors as vector rectangles.
- Draw text as real PDF text where possible.
- Draw crop marks, fold marks, registration marks, and page info as vector paths.
- Downsample large photos to the required print resolution before embedding.
- Avoid rasterizing the entire page when not necessary.

Expected benefits:

- Smaller PDF files.
- Sharper text.
- Sharper print marks.
- Better long-term print quality.

Important note:

Do not replace the current exporter immediately. Build the vector exporter as an experimental option first.

Priority: **High, but after caching and pipeline refactor**

---

### 4.5 Move Layout Templates Toward Data-Driven Presets

Current layout templates appear to be code-driven. For faster iteration, templates should become more data-driven.

Possible future template format:

```json
{
  "id": "a6_4_photo_grid",
  "name": "A6 4 Photo Grid",
  "pageSize": "A6",
  "safeMarginMM": 5,
  "bleedMM": 3,
  "photoSlots": [
    { "x": 10, "y": 10, "width": 80, "height": 55 },
    { "x": 10, "y": 70, "width": 80, "height": 55 }
  ],
  "textSlots": [],
  "autoFillStrategy": "chronological"
}
```

Benefits:

- Easier to add templates.
- Easier to let AI generate new templates.
- Easier to support print-provider-specific presets.
- Easier to test layout logic separately from SwiftUI.

Priority: **Medium to high**

---

## 5. Open-Source Projects Worth Studying

The following projects are useful references, but they should be treated as design references, not necessarily direct dependencies.

### 5.1 `Thors161/PhotoBookGenerator`

Repository:

```text
https://github.com/Thors161/PhotoBookGenerator
```

Why it is relevant:

- Similar overall goal: generating a PDF photo book from photos.
- Contains concepts such as pages, layouts, images, and editing UI.
- Useful as a reference for object model and editor structure.

Important caution:

- License is GPL-2.0.
- Do not copy code directly into this project unless the license implications are fully understood.
- Best used as an architectural reference.

---

### 5.2 `josch/img2pdf`

Repository:

```text
https://github.com/josch/img2pdf
```

Why it is relevant:

- Strong reference for efficient image-to-PDF generation.
- Focuses on avoiding unnecessary image recompression.
- Useful for thinking about PDF size, image quality, and export speed.

Ideas to borrow:

- Avoid recompressing JPEG images when possible.
- Separate image embedding from page layout.
- Treat PDF generation as a data pipeline, not just a screen render.

---

### 5.3 `pdfarranger/pdfarranger`

Repository:

```text
https://github.com/pdfarranger/pdfarranger
```

Why it is relevant:

- Good reference for PDF page manipulation.
- Supports rearranging, rotating, cropping, splitting, and combining PDF pages.
- Useful for future PDF post-processing and imposition ideas.

Ideas to borrow:

- Separate content generation from PDF page manipulation.
- Provide clear page-level operations.
- Treat page order as data that can be transformed.

---

### 5.4 `pikepdf/pikepdf`

Repository:

```text
https://github.com/pikepdf/pikepdf
```

Why it is relevant:

- Python PDF manipulation library based on QPDF.
- Useful for understanding PDF structure and page operations.
- Could become a future helper tool if a Python-based export or post-processing workflow is ever introduced.

Ideas to borrow:

- Page-level transformations.
- Metadata handling.
- PDF optimization and repair concepts.

---

### 5.5 `scribusproject/scribus`

Repository:

```text
https://github.com/scribusproject/scribus
```

Why it is relevant:

- Mature open-source desktop publishing application.
- Useful conceptual reference for print-ready layout software.

Ideas to borrow conceptually:

- Master pages.
- Preflight checks.
- Object alignment.
- Safe areas and bleed areas.
- Professional export presets.
- Missing font / missing image checks.

This project is large and should not be copied directly. It is best used as a design reference.

---

## 6. Suggested Development Roadmap

### Phase 1: Stabilize and Speed Up Current Export

Tasks:

- [ ] Add `FilteredImageCache`.
- [ ] Add thumbnail cache if not already present.
- [ ] Reuse cached filtered images across preview and export.
- [ ] Add export progress detail, not only percentage.
- [ ] Add export error reporting for missing files and render failures.
- [ ] Reduce debug `print` noise or move it behind a debug flag.

Expected result:

Current export becomes faster and easier to debug without changing the output format.

---

### Phase 2: Refactor Export Architecture

Tasks:

- [ ] Create `PageSequenceBuilder`.
- [ ] Create `ImpositionService`.
- [ ] Move saddle-stitch page-order logic into a testable standalone service.
- [ ] Create `PDFWriteService`.
- [ ] Make `SpreadPDFExporter`, `SequentialDoubleSidedExporter`, and `SaddleStitchExporter` use shared services.
- [ ] Add unit tests for page ordering.

Suggested tests:

```text
4 pages  -> Sheet 1: Front [4,1], Back [2,3]
8 pages  -> Sheet 1: Front [8,1], Back [2,7]
12 pages -> Sheet 1: Front [12,1], Back [2,11]
```

Expected result:

Export modes become easier to maintain and extend.

---

### Phase 3: Add Preflight System

Tasks:

- [ ] Create `PDFPreflightChecker`.
- [ ] Add image resolution checks.
- [ ] Add missing image checks.
- [ ] Add safe-area warnings.
- [ ] Add page-count compatibility checks.
- [ ] Add print-provider preset checks.
- [ ] Show preflight results before export.

Expected result:

The app becomes safer for real print orders.

---

### Phase 4: Add Print Provider Presets

Possible presets:

```text
Fotofabrik A6 Hardcover
Fotofabrik Square
Epubli A6
Generic A5
Generic A4
Custom
```

Each preset should define:

- Page size.
- Bleed.
- Safe margin.
- Recommended DPI.
- Max page count.
- Export mode.
- Whether saddle-stitch is allowed.
- Whether cover is separate or included.

Expected result:

Users do not need to manually understand every PDF setting.

---

### Phase 5: Experimental High-Quality PDF Exporter

Tasks:

- [ ] Create `VectorPDFExporter`.
- [ ] Draw crop marks and registration marks as vector paths.
- [ ] Draw background as vector rectangles.
- [ ] Investigate drawing text as real PDF text.
- [ ] Downsample photos to exact required print resolution.
- [ ] Compare output size and quality against current raster exporter.

Expected result:

A future-proof PDF exporter that can generate smaller and sharper PDFs.

---

### Phase 6: Data-Driven Template System

Tasks:

- [ ] Define template schema.
- [ ] Move several existing layouts into template presets.
- [ ] Add template preview.
- [ ] Add automatic photo fill by chronological order.
- [ ] Add support for AI-generated layout templates.

Expected result:

New photo book layouts can be added much faster.

---

## 7. Proposed Immediate Next Tasks

The next coding session should probably start with these tasks:

1. Add `FilteredImageCache`.
2. Add `PageSequenceBuilder`.
3. Add `ImpositionService` with unit tests for saddle-stitch ordering.
4. Move duplicate preload/render/write logic into shared services.
5. Add a basic preflight checker for page count, DPI, bleed, and missing images.

This sequence is recommended because it improves performance and code structure before attempting a more ambitious vector PDF exporter.

---

## 8. Design Principle Going Forward

The project should avoid becoming a collection of separate exporters with duplicated logic.

Preferred principle:

```text
One book model
One logical page sequence
Multiple imposition strategies
Multiple renderers
One PDF writing layer
```

This will make the project easier to maintain, easier to test, and easier for future AI tools to analyze or extend.

---

## 9. Notes for Future AI Assistants

When analyzing this project, pay special attention to:

- `PDFExportConfig`
- `SpreadPDFExporter`
- `SequentialDoubleSidedExporter`
- `SaddleStitchExporter`
- `SaddleStitchImposition`
- `BookStructure`
- `PageModel`
- `PhotoLayer`
- `TextLayer`
- `StickerLayer`
- Any image filter generation code
- Any SwiftUI preview or Canvas rendering code

Recommended analysis order:

1. Understand the book model.
2. Understand page and layer coordinates.
3. Understand how bleed and trim size are represented.
4. Understand normal spread export.
5. Understand double-sided export.
6. Understand saddle-stitch export.
7. Identify duplicated rendering or image-loading logic.
8. Propose refactors that preserve current output behavior.

Do not start by rewriting the UI. The highest-value improvements are currently in export architecture, caching, preflight validation, and PDF quality.
