# Photobook Maker Development Plan

_Last updated: 2026-06-04_

This document summarizes the current development direction of `Photobook_maker` after review by multiple AI assistants and repository inspection.

The most important correction to the earlier plan is this:

> The project already contains a `CGPDFExporter.swift` prototype. Therefore, high-quality vector-oriented PDF export is not a distant experimental Phase 5 task. It should be moved forward and treated as an existing prototype that needs repair, validation, and UI integration.

The next development goal is to turn the current PDF export system into a reliable print-oriented pipeline while preserving existing raster exporters as fallback paths.

---

## 1. Current Project Positioning

`Photobook_maker` is a macOS native Swift / SwiftUI photo book creator focused on generating print-ready PDF files.

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

The project is already stronger than a simple image-to-PDF generator. Its next growth area is professional export correctness: regression testing, vector PDF output, imposition reuse, font embedding, and color management.

---

## 2. Key Repository Findings That Changed the Roadmap

### 2.1 `CGPDFExporter.swift` already exists

The repository already contains a Core Graphics based PDF exporter:

```text
PhotobookApp/Sources/Services/CGPDFExporter.swift
```

It already uses `CGContext(url:mediaBox:)` and includes logic for:

- `MediaBox`
- `TrimBox`
- `BleedBox`
- Vector background rectangles
- Vector crop marks
- Direct drawing into a PDF `CGContext`

This changes the priority significantly. The task is not to create a new vector exporter from scratch, but to fix and integrate the existing prototype.

### 2.2 The likely text rendering bug is in `drawTextLayer`

`CGPDFExporter.drawTextLayer` uses:

```swift
attributedString.draw(in: textRect)
```

However, `NSAttributedString.draw(in:)` depends on AppKit's current `NSGraphicsContext`. If the PDF `CGContext` is not wrapped and set as `NSGraphicsContext.current`, text can silently fail to render or behave inconsistently.

Short-term fix:

```swift
let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = nsContext
attributedString.draw(in: textRect)
NSGraphicsContext.restoreGraphicsState()
```

Longer-term print-quality direction:

- Move text rendering to Core Text.
- Verify that fonts are embedded in the generated PDF.
- Use `pdffonts` or an equivalent tool to check font embedding.

### 2.3 The future pipeline should inject `CGContext`, not bake in `CGImage`

The old plan risked turning the new export architecture into this pattern:

```text
PageRenderService -> CGImage -> PDFWriteService
```

That would permanently bake rasterization into the architecture.

The corrected direction is:

```text
PDFContextExporter opens CGContext
    ↓
Inject CGContext into page/layer drawing services
    ↓
Draw backgrounds, photos, text, stickers, crop marks, and PDF boxes directly
```

The existing `ImageRenderer` / `PDFDocument` exporters should remain as stable raster fallback paths, but they should not define the future architecture.

### 2.4 Color management is a first-class print concern

The earlier plan underweighted color management.

A practical roadmap should not immediately force CMYK conversion, because many consumer photo book services accept RGB PDF. However, the app should explicitly manage and check color.

Recommended staged approach:

1. Preflight checks for image color spaces and missing ICC information.
2. Explicit sRGB ICC profile handling for exported PDFs.
3. Research PDF/X compliance and target ICC profiles for professional workflows.

Color management should be part of the product roadmap, not an afterthought.

---

## 3. Corrected Architecture Direction

Recommended export architecture:

```text
BookStructure
    ↓
PageSequenceBuilder
    ↓
ImpositionService
    ↓
PDFContextExporter / RasterPDFExporter
    ↓
Final PDF
```

Important design rule:

```text
For high-quality export, PDF writing opens the CGContext first.
The drawing layer receives that context and draws directly into it.
```

Recommended modules:

```text
PhotoBookApp
├── Export
│   ├── PDFExportConfig
│   ├── RasterPDFExporter              # Existing ImageRenderer/PDFDocument path
│   ├── CGPDFExporter                  # Existing vector-oriented prototype
│   ├── PDFContextExporter             # Future cleaned-up CGPDFExporter direction
│   └── ExportPresetService
├── Drawing
│   ├── PDFPageDrawingService
│   ├── PDFLayerDrawingService
│   ├── PDFTextDrawingService
│   ├── PDFImageDrawingService
│   └── PDFPrintMarksDrawingService
├── Imposition
│   ├── ImpositionService
│   ├── SaddleStitchImposition
│   ├── SequentialDoubleSidedImposition
│   └── BlankPagePaddingService
├── Regression
│   ├── GoldenPDFSamples
│   └── PDFPixelDiffTool
├── Preflight
│   ├── PDFPreflightChecker
│   ├── ImageResolutionChecker
│   ├── FontEmbeddingChecker
│   ├── ColorSpaceChecker
│   └── PrintProviderCompatibilityChecker
└── Cache
    ├── FilteredImageCache
    └── ThumbnailCache
```

The architecture should avoid duplicating page-order and imposition logic across exporters.

---

## 4. Revised Session Plan

### Session 1: Golden PDF baseline and regression comparison tool

Core goal:

Create a regression safety net before changing any PDF export architecture.

Why this must come first:

PDF export changes can easily break:

- Coordinate flipping
- Bleed offset
- Crop marks
- Saddle-stitch page order
- Text rotation
- Photo cropping
- Page boxes
- Left/right spread placement

These regressions may be subtle on screen but expensive in print.

Tasks:

- [ ] Add a `pymupdf`-based PDF rendering and pixel comparison script.
- [ ] Create 3-5 representative exported PDFs manually from the current app.
- [ ] Store them as golden baseline samples outside normal source code if they are large, or document their expected location.
- [ ] Render baseline PDFs to PNG at 150 DPI or 300 DPI.
- [ ] Compare future exports against golden renders.

Recommended baseline samples:

```text
01_basic_spread.pdf
02_text_and_rotation.pdf
03_bleed_cropmarks.pdf
04_saddle_stitch_8_pages.pdf
05_mixed_filters_stickers.pdf
```

Completion standard:

- 5 sample PDFs exist locally or in an agreed regression folder.
- The comparison script can render PDFs to PNG.
- The comparison script can report pixel-level differences.
- The workflow is documented clearly enough for another AI or developer to run.

Priority: **Highest**

---

### Session 2: Repair and integrate `CGPDFExporter` for spread mode

Core goal:

Make the existing Core Graphics PDF exporter usable for normal spread export.

Scope boundary:

Session 2 should **only** cover spread mode. Saddle-stitch support for `CGPDFExporter` should wait until Session 3, after `ImpositionService` exists.

Tasks:

- [ ] Fix `drawTextLayer` so text actually renders into the PDF context.
- [ ] Prefer Core Text for a robust long-term implementation, or use `NSGraphicsContext` as a short-term bridge.
- [ ] Add a UI option such as `High Quality PDF Export` or `CGPDF Export`.
- [ ] Export a spread PDF using `CGPDFExporter`.
- [ ] Verify that text remains vector text where possible.
- [ ] Verify font embedding using `pdffonts` or an equivalent tool.
- [ ] Compare output against golden baseline renders.

Font validation command:

```bash
brew install poppler
pdffonts output.pdf
```

Completion standard:

- The UI can choose the CGPDF spread exporter.
- Text appears in CGPDF output.
- Font embedding is checked.
- If fonts are not embedded, the issue is either fixed or explicitly documented as a blocker.
- Golden PDF pixel comparison shows no unacceptable visual regression for spread-mode samples.

Priority: **Very high**

---

### Session 3: Extract `ImpositionService` and update all exporters

Core goal:

Remove duplicated page-order and imposition logic.

Important requirement:

It is not enough for only `CGPDFExporter` to call `ImpositionService`. Existing raster exporters must also be moved to the shared imposition service, otherwise the project will still have duplicated imposition logic.

Tasks:

- [ ] Create `PageSequenceBuilder`.
- [ ] Create `ImpositionService`.
- [ ] Move saddle-stitch page-order logic into a standalone testable service.
- [ ] Move blank-page padding to shared logic.
- [ ] Make `SaddleStitchExporter` call `ImpositionService`.
- [ ] Make `SequentialDoubleSidedExporter` call `ImpositionService`.
- [ ] Make spread or normal exporters use shared page sequence logic where practical.
- [ ] Prepare `CGPDFExporter` to use the same imposition result in a later step.
- [ ] Add unit tests for page order.

Suggested unit tests:

```text
4 pages  -> Sheet 1: Front [4,1], Back [2,3]
8 pages  -> Sheet 1: Front [8,1], Back [2,7]
12 pages -> Sheet 1: Front [12,1], Back [2,11]
```

Completion standard:

- Saddle-stitch unit tests pass.
- Existing raster saddle-stitch and double-sided exporters no longer own independent imposition logic.
- Golden PDF comparison shows no unacceptable visual regression.

Priority: **Very high**

---

### Session 4: Add `FilteredImageCache` with quantized floating-point keys

Core goal:

Speed up repeated preview/export operations and avoid recomputing filtered images unnecessarily.

Important detail:

Do not use raw floating-point filter parameters directly as cache keys. Tiny precision differences can cause unnecessary cache misses.

Use quantized keys:

```swift
func quantize(_ value: Double, precision: Double = 1000) -> Int {
    Int((value * precision).rounded())
}
```

Cache key should include:

```text
photoUrl
fileModificationDate
filterType
quantized brightness
quantized contrast
quantized saturation
quantized vignetteIntensity
quantized sharpenIntensity
quantized temperature
targetPixelSize
```

Completion standard:

- Repeated export uses cached filtered images.
- Cache invalidates when the source file or filter parameters change.
- Repeated export timing is measured before and after.

Priority: **High**

---

### Session 5: Add Preflight system with color management placeholders

Core goal:

Start treating export readiness as a first-class feature.

Tasks:

- [ ] Add a basic `PDFPreflightChecker`.
- [ ] Check page size.
- [ ] Check DPI.
- [ ] Check bleed.
- [ ] Check `TrimBox` / `BleedBox` presence where applicable.
- [ ] Check image availability.
- [ ] Check low-resolution images.
- [ ] Check text objects near trim/safe area.
- [ ] Check color space information where available.
- [ ] Warn about unknown color profiles.
- [ ] Add print-provider preset fields for ICC / PDF-X expectations.
- [ ] Add placeholder for future sRGB ICC embedding and PDF/X compliance checks.

Color management stages:

```text
Stage 1: Detect and report color spaces / missing ICC profiles.
Stage 2: Explicitly support sRGB ICC profile handling in export.
Stage 3: Research PDF/X and optional CMYK workflows for professional print providers.
```

Completion standard:

- A preflight result is shown before export.
- Color management appears in the preflight model, even if conversion is not implemented yet.
- Warnings are understandable to non-expert users.

Priority: **High**

---

## 5. Golden PDF Regression Strategy

The project should use rendered image comparison for PDF regression tests.

Reason:

- PDF files are binary and not useful in normal `git diff`.
- Internal PDF object ordering can change even if visual output is identical.
- For this app, visual correctness is the most important regression target.

Recommended tool:

```text
Python + pymupdf / fitz
```

Basic rendering approach:

```python
import fitz

doc = fitz.open("output.pdf")
for i, page in enumerate(doc):
    pix = page.get_pixmap(dpi=150)
    pix.save(f"page_{i + 1}.png")
```

Recommended comparison levels:

1. Render each PDF page to PNG.
2. Compare page counts and rendered dimensions.
3. Compute pixel differences.
4. Report mean difference, max difference, and changed pixel percentage.
5. Save diff images for manual inspection.

The first implementation does not need to be perfect. It only needs to detect obvious regressions before export architecture changes.

---

## 6. Font Embedding Validation

Font embedding must be checked during Session 2, not deferred to the final Preflight phase.

Reason:

If CGPDF output draws real text but fails to embed fonts, print providers may substitute fonts and cause layout changes.

Recommended command-line check:

```bash
brew install poppler
pdffonts output.pdf
```

Important column:

```text
emb
```

Expected result:

```text
emb = yes
```

If `pdffonts` is not available, investigate PyMuPDF or another PDF inspection approach, but `pdffonts` is the simplest first tool.

---

## 7. Open-Source Projects Worth Studying

These projects are useful references, but they should be treated as design references rather than direct sources for copied code.

### 7.1 `Thors161/PhotoBookGenerator`

```text
https://github.com/Thors161/PhotoBookGenerator
```

Relevant because it has a similar broad goal: generating a PDF photo book from photos.

Caution:

- License is GPL-2.0.
- Do not copy code directly unless license implications are fully understood.

### 7.2 `josch/img2pdf`

```text
https://github.com/josch/img2pdf
```

Relevant for efficient image-to-PDF generation and avoiding unnecessary image recompression.

### 7.3 `pdfarranger/pdfarranger`

```text
https://github.com/pdfarranger/pdfarranger
```

Relevant for PDF page manipulation and page-order thinking.

### 7.4 `pikepdf/pikepdf`

```text
https://github.com/pikepdf/pikepdf
```

Relevant for PDF structure, page operations, metadata, and possible future PDF post-processing.

### 7.5 `scribusproject/scribus`

```text
https://github.com/scribusproject/scribus
```

Relevant as a conceptual reference for desktop publishing features:

- Master pages
- Preflight checks
- Safe areas and bleed
- Professional export presets
- Missing font / missing image checks
- Color management concepts

---

## 8. Design Principles Going Forward

Preferred principle:

```text
One book model
One logical page sequence
Shared imposition strategies
Raster fallback exporters
CGContext-based high-quality exporter
Shared preflight checks
Shared regression baselines
```

Avoid this anti-pattern:

```text
Each exporter owns its own page order, image preparation, rendering, and PDF writing.
```

The project should preserve current working raster export behavior while gradually moving high-quality export toward a direct PDF `CGContext` drawing pipeline.

---

## 9. Notes for Future AI Assistants

When analyzing this project, inspect these files first:

- `PhotobookApp/Sources/Services/CGPDFExporter.swift`
- `PhotobookApp/Sources/Services/SpreadPDFExporter.swift`
- `PhotobookApp/Sources/Services/SequentialDoubleSidedExporter.swift`
- `PhotobookApp/Sources/Services/SaddleStitchExporter.swift`
- `PDFExportConfig`
- `SaddleStitchImposition`
- `BookStructure`
- `PageModel`
- `PhotoLayer`
- `TextLayer`
- `StickerLayer`

Recommended analysis order:

1. Understand the book model.
2. Understand page and layer coordinates.
3. Understand how bleed and trim size are represented.
4. Understand `CGPDFExporter` and why it is currently not fully used.
5. Check text rendering and font embedding.
6. Understand normal spread export.
7. Understand double-sided export.
8. Understand saddle-stitch export.
9. Identify duplicated imposition and image-loading logic.
10. Preserve golden PDF output before refactoring.

Do not start by rewriting the UI. The highest-value improvements are currently:

1. Golden PDF regression testing.
2. Repairing and integrating `CGPDFExporter`.
3. Extracting shared imposition logic.
4. Adding filtered image caching.
5. Adding preflight checks with color management placeholders.
