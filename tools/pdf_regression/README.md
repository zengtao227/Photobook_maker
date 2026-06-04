# PDF Regression Tools

This folder contains helper scripts for visual regression testing of exported photobook PDFs.

The goal is to protect PDF export behavior before refactoring exporters, fixing `CGPDFExporter`, or changing imposition logic.

## Why rendered image comparison?

PDF files are binary and their internal object structure can change even when the visual output is identical. For this project, visual output is the most important regression target.

The recommended workflow is:

1. Export representative PDFs from the current app.
2. Store them as golden baseline files.
3. Export new PDFs after code changes.
4. Render both PDFs to PNG files.
5. Compare rendered PNGs pixel-by-pixel.
6. Inspect generated diff images if the comparison fails.

## Suggested golden samples

Create these PDFs manually from the app:

```text
01_basic_spread.pdf
02_text_and_rotation.pdf
03_bleed_cropmarks.pdf
04_saddle_stitch_8_pages.pdf
05_mixed_filters_stickers.pdf
```

Suggested folder layout:

```text
tools/pdf_regression/golden/
tools/pdf_regression/current/
tools/pdf_regression/output/
```

Large exported PDFs do not necessarily need to be committed to Git. If they are too large or contain private photos, keep them locally and document how to recreate them.

## Setup

Create or activate your Python environment, then install dependencies:

```bash
pip install pymupdf pillow numpy
```

## Render a PDF to PNG pages

```bash
python tools/pdf_regression/pdf_visual_diff.py render \
  --pdf tools/pdf_regression/golden/01_basic_spread.pdf \
  --out tools/pdf_regression/output/golden_01 \
  --dpi 150
```

## Compare two PDFs

```bash
python tools/pdf_regression/pdf_visual_diff.py compare \
  --expected tools/pdf_regression/golden/01_basic_spread.pdf \
  --actual tools/pdf_regression/current/01_basic_spread.pdf \
  --out tools/pdf_regression/output/01_basic_spread_diff \
  --dpi 150
```

The script reports:

- Page count match or mismatch
- Rendered page size match or mismatch
- Mean absolute pixel difference
- Maximum pixel difference
- Percentage of changed pixels
- Generated diff images

## Suggested first threshold

Start with a strict threshold while no intentional visual changes are expected:

```bash
--max-changed-pixels 0.001 --max-mean-diff 0.5
```

These thresholds can be relaxed later if anti-aliasing differences are expected.

## Important note

This tool is a regression safety net, not a replacement for print preflight. Later phases should add checks for:

- Font embedding
- ICC profiles
- sRGB / CMYK / unknown color spaces
- TrimBox / BleedBox
- PDF/X compliance
