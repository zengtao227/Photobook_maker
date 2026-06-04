#!/usr/bin/env python3
"""
Render and compare exported photobook PDFs visually.

This script is intended as a regression safety net before refactoring PDF export,
repairing CGPDFExporter, or changing imposition logic.

Dependencies:
    pip install pymupdf pillow numpy

Examples:
    python tools/pdf_regression/pdf_visual_diff.py render \
        --pdf tools/pdf_regression/golden/01_basic_spread.pdf \
        --out tools/pdf_regression/output/golden_01 \
        --dpi 150

    python tools/pdf_regression/pdf_visual_diff.py compare \
        --expected tools/pdf_regression/golden/01_basic_spread.pdf \
        --actual tools/pdf_regression/current/01_basic_spread.pdf \
        --out tools/pdf_regression/output/01_basic_spread_diff \
        --dpi 150
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import List

try:
    import fitz  # PyMuPDF
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Missing dependency: pymupdf. Install with: pip install pymupdf pillow numpy"
    ) from exc

try:
    import numpy as np
    from PIL import Image
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Missing dependency: pillow or numpy. Install with: pip install pymupdf pillow numpy"
    ) from exc


@dataclass
class PageDiffResult:
    page: int
    expected_size: List[int]
    actual_size: List[int]
    size_matches: bool
    mean_abs_diff: float | None
    max_abs_diff: int | None
    changed_pixel_ratio: float | None
    diff_image: str | None


@dataclass
class CompareResult:
    expected_pdf: str
    actual_pdf: str
    dpi: int
    page_count_matches: bool
    expected_page_count: int
    actual_page_count: int
    pages: List[PageDiffResult]
    passed: bool


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def render_pdf(pdf_path: Path, out_dir: Path, dpi: int) -> List[Path]:
    if not pdf_path.exists():
        raise FileNotFoundError(f"PDF does not exist: {pdf_path}")

    ensure_dir(out_dir)
    rendered_paths: List[Path] = []

    doc = fitz.open(pdf_path)
    try:
        for index, page in enumerate(doc, start=1):
            pix = page.get_pixmap(dpi=dpi, alpha=False)
            out_path = out_dir / f"page_{index:03d}.png"
            pix.save(out_path)
            rendered_paths.append(out_path)
    finally:
        doc.close()

    return rendered_paths


def image_array(path: Path) -> np.ndarray:
    image = Image.open(path).convert("RGB")
    return np.asarray(image, dtype=np.int16)


def save_diff_image(expected: np.ndarray, actual: np.ndarray, out_path: Path) -> None:
    """Save a visible difference image.

    The raw difference is amplified to make subtle differences easier to see.
    """

    diff = np.abs(expected - actual).astype(np.uint8)
    amplified = np.clip(diff * 8, 0, 255).astype(np.uint8)
    Image.fromarray(amplified, mode="RGB").save(out_path)


def compare_rendered_pages(
    expected_pages: List[Path],
    actual_pages: List[Path],
    out_dir: Path,
) -> List[PageDiffResult]:
    ensure_dir(out_dir)
    results: List[PageDiffResult] = []

    max_pages = max(len(expected_pages), len(actual_pages))
    for idx in range(max_pages):
        page_number = idx + 1

        if idx >= len(expected_pages):
            actual = image_array(actual_pages[idx])
            results.append(
                PageDiffResult(
                    page=page_number,
                    expected_size=[],
                    actual_size=list(actual.shape[:2]),
                    size_matches=False,
                    mean_abs_diff=None,
                    max_abs_diff=None,
                    changed_pixel_ratio=None,
                    diff_image=None,
                )
            )
            continue

        if idx >= len(actual_pages):
            expected = image_array(expected_pages[idx])
            results.append(
                PageDiffResult(
                    page=page_number,
                    expected_size=list(expected.shape[:2]),
                    actual_size=[],
                    size_matches=False,
                    mean_abs_diff=None,
                    max_abs_diff=None,
                    changed_pixel_ratio=None,
                    diff_image=None,
                )
            )
            continue

        expected = image_array(expected_pages[idx])
        actual = image_array(actual_pages[idx])
        size_matches = expected.shape == actual.shape

        if not size_matches:
            results.append(
                PageDiffResult(
                    page=page_number,
                    expected_size=list(expected.shape[:2]),
                    actual_size=list(actual.shape[:2]),
                    size_matches=False,
                    mean_abs_diff=None,
                    max_abs_diff=None,
                    changed_pixel_ratio=None,
                    diff_image=None,
                )
            )
            continue

        diff = np.abs(expected - actual)
        mean_abs_diff = float(diff.mean())
        max_abs_diff = int(diff.max())
        changed_pixels = np.any(diff > 0, axis=2).sum()
        total_pixels = diff.shape[0] * diff.shape[1]
        changed_pixel_ratio = float(changed_pixels / total_pixels)

        diff_path = out_dir / f"diff_page_{page_number:03d}.png"
        save_diff_image(expected, actual, diff_path)

        results.append(
            PageDiffResult(
                page=page_number,
                expected_size=list(expected.shape[:2]),
                actual_size=list(actual.shape[:2]),
                size_matches=True,
                mean_abs_diff=mean_abs_diff,
                max_abs_diff=max_abs_diff,
                changed_pixel_ratio=changed_pixel_ratio,
                diff_image=str(diff_path),
            )
        )

    return results


def compare_pdfs(
    expected_pdf: Path,
    actual_pdf: Path,
    out_dir: Path,
    dpi: int,
    max_changed_pixels: float,
    max_mean_diff: float,
) -> CompareResult:
    ensure_dir(out_dir)

    expected_render_dir = out_dir / "expected_pages"
    actual_render_dir = out_dir / "actual_pages"
    diff_dir = out_dir / "diff_pages"

    expected_pages = render_pdf(expected_pdf, expected_render_dir, dpi)
    actual_pages = render_pdf(actual_pdf, actual_render_dir, dpi)
    page_results = compare_rendered_pages(expected_pages, actual_pages, diff_dir)

    page_count_matches = len(expected_pages) == len(actual_pages)

    passed = page_count_matches
    for page in page_results:
        if not page.size_matches:
            passed = False
            continue
        if page.changed_pixel_ratio is None or page.mean_abs_diff is None:
            passed = False
            continue
        if page.changed_pixel_ratio > max_changed_pixels:
            passed = False
        if page.mean_abs_diff > max_mean_diff:
            passed = False

    result = CompareResult(
        expected_pdf=str(expected_pdf),
        actual_pdf=str(actual_pdf),
        dpi=dpi,
        page_count_matches=page_count_matches,
        expected_page_count=len(expected_pages),
        actual_page_count=len(actual_pages),
        pages=page_results,
        passed=passed,
    )

    report_path = out_dir / "report.json"
    report_path.write_text(json.dumps(asdict(result), indent=2), encoding="utf-8")

    return result


def print_compare_summary(result: CompareResult) -> None:
    status = "PASS" if result.passed else "FAIL"
    print(f"PDF visual comparison: {status}")
    print(f"Expected pages: {result.expected_page_count}")
    print(f"Actual pages:   {result.actual_page_count}")
    print(f"DPI:            {result.dpi}")
    print("")

    for page in result.pages:
        if not page.size_matches:
            print(
                f"Page {page.page}: SIZE MISMATCH "
                f"expected={page.expected_size} actual={page.actual_size}"
            )
            continue

        print(
            f"Page {page.page}: "
            f"mean_abs_diff={page.mean_abs_diff:.4f}, "
            f"max_abs_diff={page.max_abs_diff}, "
            f"changed_pixel_ratio={page.changed_pixel_ratio:.6f}"
        )

    print("\nJSON report written to output folder.")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="PDF visual regression helper")
    subparsers = parser.add_subparsers(dest="command", required=True)

    render_parser = subparsers.add_parser("render", help="Render one PDF to PNG pages")
    render_parser.add_argument("--pdf", required=True, type=Path)
    render_parser.add_argument("--out", required=True, type=Path)
    render_parser.add_argument("--dpi", default=150, type=int)

    compare_parser = subparsers.add_parser("compare", help="Compare two PDFs visually")
    compare_parser.add_argument("--expected", required=True, type=Path)
    compare_parser.add_argument("--actual", required=True, type=Path)
    compare_parser.add_argument("--out", required=True, type=Path)
    compare_parser.add_argument("--dpi", default=150, type=int)
    compare_parser.add_argument(
        "--max-changed-pixels",
        default=0.001,
        type=float,
        help="Maximum allowed changed pixel ratio, e.g. 0.001 = 0.1%%",
    )
    compare_parser.add_argument(
        "--max-mean-diff",
        default=0.5,
        type=float,
        help="Maximum allowed mean absolute RGB difference",
    )

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "render":
        pages = render_pdf(args.pdf, args.out, args.dpi)
        print(f"Rendered {len(pages)} pages to {args.out}")
        return 0

    if args.command == "compare":
        result = compare_pdfs(
            expected_pdf=args.expected,
            actual_pdf=args.actual,
            out_dir=args.out,
            dpi=args.dpi,
            max_changed_pixels=args.max_changed_pixels,
            max_mean_diff=args.max_mean_diff,
        )
        print_compare_summary(result)
        return 0 if result.passed else 1

    parser.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
