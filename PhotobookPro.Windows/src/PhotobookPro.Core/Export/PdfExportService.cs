using PhotobookPro.Core.Models;
using PhotobookPro.Core.Models.Layers;
using PhotobookPro.Core.Portable;
using QuestPDF;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using SkiaSharp;

namespace PhotobookPro.Core.Export;

public static class PdfExportService
{
    public static void ExportBundleToPdf(string bundlePath, string outputPdfPath, PdfExportOptions? options = null)
    {
        options ??= new PdfExportOptions();

        QuestPDF.Settings.License = LicenseType.Community;

        var bundle = PhotobookBundleReader.Read(bundlePath);
        ExportManifestToPdfPrecise(bundle.Manifest, outputPdfPath);
    }

    public static void ExportManifestToPdf(Manifest manifest, string outputPdfPath)
    {
        ExportManifestToPdfPrecise(manifest, outputPdfPath);
    }

    public static void ExportManifestToPdfPrecise(Manifest manifest, string outputPdfPath)
    {
        QuestPDF.Settings.License = LicenseType.Community;

        var (singleWidthPt, singleHeightPt) = BookPageSizeSpec.GetSinglePagePoints(manifest.PageSize);
        var (spreadWidthPt, spreadHeightPt) = BookPageSizeSpec.GetSpreadPoints(manifest.PageSize);

        Document.Create(container =>
        {
            for (var spreadIndex = 0; spreadIndex < manifest.Spreads.Count; spreadIndex++)
            {
                var spread = manifest.Spreads[spreadIndex];
                container.Page(page =>
                {
                    page.Size((float)spreadWidthPt, (float)spreadHeightPt, Unit.Point);
                    page.Margin(0, Unit.Point);
                    page.PageColor(Colors.White);

                    page.Content().SkiaSharpSvgCanvas((canvas, size) =>
                    {
                        using var bgPaint = new SKPaint { IsAntialias = true, Style = SKPaintStyle.Fill };

                        DrawPage(canvas, spread.LeftPage, 0, 0, (float)singleWidthPt, (float)singleHeightPt, bgPaint);
                        DrawPage(canvas, spread.RightPage, (float)singleWidthPt, 0, (float)singleWidthPt, (float)singleHeightPt, bgPaint);
                    });
                });
            }
        }).GeneratePdf(outputPdfPath);
    }

    private static void DrawPage(SKCanvas canvas, PageModel page, float offsetX, float offsetY, float width, float height, SKPaint bgPaint)
    {
        bgPaint.Color = ColorUtils.ParseHex(page.BackgroundColorHex, SKColors.White);
        canvas.DrawRect(new SKRect(offsetX, offsetY, offsetX + width, offsetY + height), bgPaint);

        var ordered = page.Layers
            .OrderBy(l => ((ILayer)l.Data).ZIndex)
            .ThenBy(l => l.Type, StringComparer.Ordinal)
            .ToList();

        foreach (var wrapper in ordered)
        {
            switch (wrapper.Type)
            {
                case "photo":
                    DrawPhotoLayer(canvas, (PhotoLayer)wrapper.Data, offsetX, offsetY);
                    break;
                case "text":
                    DrawTextLayer(canvas, (TextLayer)wrapper.Data, offsetX, offsetY);
                    break;
                case "sticker":
                    DrawStickerLayer(canvas, (StickerLayer)wrapper.Data, offsetX, offsetY);
                    break;
            }
        }
    }

    private static void DrawPhotoLayer(SKCanvas canvas, PhotoLayer layer, float offsetX, float offsetY)
    {
        var dest = ToDestRect(layer.Frame, offsetX, offsetY);
        if (dest.Width <= 1 || dest.Height <= 1)
            return;

        if (!File.Exists(layer.PhotoUrl))
            return;

        using var data = SKData.Create(layer.PhotoUrl);
        using var image = SKImage.FromEncodedData(data);

        DrawImageWithCrop(canvas, image, dest, (float)layer.CropScale, (float)layer.CropOffset.Width, (float)layer.CropOffset.Height, (float)layer.CropRotation);
    }

    private static void DrawTextLayer(SKCanvas canvas, TextLayer layer, float offsetX, float offsetY)
    {
        var dest = ToDestRect(layer.Frame, offsetX, offsetY);
        if (dest.Width <= 1 || dest.Height <= 1)
            return;

        using var paint = new SKPaint
        {
            IsAntialias = true,
            Color = ColorUtils.ParseHex(layer.ColorHex, SKColors.Black),
            TextSize = (float)Math.Max(10, layer.FontSize),
            Typeface = SKTypeface.FromFamilyName(layer.FontName) ?? SKTypeface.Default
        };

        var metrics = paint.FontMetrics;
        var baseline = dest.Top + (dest.Height - (metrics.Descent - metrics.Ascent)) / 2 - metrics.Ascent;
        var textWidth = paint.MeasureText(layer.Text);

        var x = layer.Alignment switch
        {
            "leading" => dest.Left,
            "trailing" => dest.Right - textWidth,
            _ => dest.Left + (dest.Width - textWidth) / 2
        };

        canvas.DrawText(layer.Text, x, baseline, paint);
    }

    private static void DrawStickerLayer(SKCanvas canvas, StickerLayer layer, float offsetX, float offsetY)
    {
        var dest = ToDestRect(layer.Frame, offsetX, offsetY);
        if (dest.Width <= 1 || dest.Height <= 1)
            return;

        if (layer.Content.Emoji is not null)
        {
            using var paint = new SKPaint
            {
                IsAntialias = true,
                Color = SKColors.Black,
                TextSize = Math.Min(dest.Width, dest.Height) * 0.8f,
                Typeface = SKTypeface.Default
            };

            var metrics = paint.FontMetrics;
            var baseline = dest.Top + (dest.Height - (metrics.Descent - metrics.Ascent)) / 2 - metrics.Ascent;
            var textWidth = paint.MeasureText(layer.Content.Emoji);
            var x = dest.Left + (dest.Width - textWidth) / 2;
            canvas.DrawText(layer.Content.Emoji, x, baseline, paint);
            return;
        }

        if (layer.Content.Url is not null && File.Exists(layer.Content.Url))
        {
            using var data = SKData.Create(layer.Content.Url);
            using var image = SKImage.FromEncodedData(data);
            DrawImageAspectFill(canvas, image, dest);
        }
    }

    private static SKRect ToDestRect(PhotobookPro.Core.Models.PbRect rect, float offsetX, float offsetY)
        => new(
            (float)(offsetX + rect.Origin.X),
            (float)(offsetY + rect.Origin.Y),
            (float)(offsetX + rect.Origin.X + rect.Size.Width),
            (float)(offsetY + rect.Origin.Y + rect.Size.Height)
        );

    private static void DrawImageWithCrop(SKCanvas canvas, SKImage image, SKRect dest, float cropScale, float offsetX, float offsetY, float rotationDegrees)
    {
        canvas.Save();
        canvas.ClipRect(dest);

        var centerX = dest.MidX + offsetX;
        var centerY = dest.MidY + offsetY;

        canvas.Translate(centerX, centerY);
        if (Math.Abs(rotationDegrees) > 0.001f)
            canvas.RotateDegrees(rotationDegrees);
        if (Math.Abs(cropScale - 1f) > 0.001f)
            canvas.Scale(cropScale);
        canvas.Translate(-dest.MidX, -dest.MidY);

        DrawImageAspectFill(canvas, image, dest);
        canvas.Restore();
    }

    private static void DrawImageAspectFill(SKCanvas canvas, SKImage image, SKRect dest)
    {
        var srcW = (float)image.Width;
        var srcH = (float)image.Height;
        if (srcW <= 0 || srcH <= 0)
            return;

        var scale = Math.Max(dest.Width / srcW, dest.Height / srcH);
        var drawW = srcW * scale;
        var drawH = srcH * scale;

        var left = dest.Left + (dest.Width - drawW) / 2;
        var top = dest.Top + (dest.Height - drawH) / 2;
        var drawRect = new SKRect(left, top, left + drawW, top + drawH);

        canvas.DrawImage(image, drawRect);
    }
}
