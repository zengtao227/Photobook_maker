using System.Text.Json;
using PhotobookPro.Core.Json;
using PhotobookPro.Core.Models;
using PhotobookPro.Core.Models.Layers;

namespace PhotobookPro.Core.Portable;

public static class PhotobookBundleReader
{
    public static PhotobookBundle Read(string bundlePath)
    {
        if (string.IsNullOrWhiteSpace(bundlePath))
            throw new ArgumentException("Bundle path is required", nameof(bundlePath));

        var manifestPath = Path.Combine(bundlePath, "manifest.json");
        if (!File.Exists(manifestPath))
            throw new FileNotFoundException("manifest.json not found", manifestPath);

        var imagesPath = Path.Combine(bundlePath, "images");
        var json = File.ReadAllText(manifestPath);
        var manifest = JsonSerializer.Deserialize<Manifest>(json, JsonDefaults.Options)
                       ?? throw new JsonException("Invalid manifest.json");

        var normalized = NormalizeManifestAssetUrls(manifest, imagesPath);

        return new PhotobookBundle
        {
            BundlePath = bundlePath,
            ImagesPath = imagesPath,
            Manifest = normalized
        };
    }

    private static Manifest NormalizeManifestAssetUrls(Manifest manifest, string imagesPath)
    {
        var spreads = manifest.Spreads
            .Select(s => s with
            {
                LeftPage = NormalizePage(s.LeftPage, imagesPath),
                RightPage = NormalizePage(s.RightPage, imagesPath)
            })
            .ToList();

        return manifest with { Spreads = spreads };
    }

    private static PageModel NormalizePage(PageModel page, string imagesPath)
    {
        var layers = page.Layers
            .Select(l => l.Type switch
            {
                "photo" => l with { Data = NormalizePhotoLayer((PhotoLayer)l.Data, imagesPath) },
                "sticker" => l with { Data = NormalizeStickerLayer((StickerLayer)l.Data, imagesPath) },
                _ => l
            })
            .ToList();

        return page with { Layers = layers };
    }

    private static PhotoLayer NormalizePhotoLayer(PhotoLayer layer, string imagesPath)
    {
        var normalized = NormalizeToAbsoluteImagesPath(layer.PhotoUrl, imagesPath);
        if (normalized is null)
            return layer;

        return layer with { PhotoUrl = normalized };
    }

    private static StickerLayer NormalizeStickerLayer(StickerLayer layer, string imagesPath)
    {
        if (layer.Content.Url is null)
            return layer;

        var normalized = NormalizeToAbsoluteImagesPath(layer.Content.Url, imagesPath);
        if (normalized is null)
            return layer;

        return layer with { Content = layer.Content with { Url = normalized } };
    }

    private static string? NormalizeToAbsoluteImagesPath(string raw, string imagesPath)
    {
        if (string.IsNullOrWhiteSpace(raw))
            return null;

        string localPath = raw;

        if (Uri.TryCreate(raw, UriKind.Absolute, out var uri))
        {
            if (uri.Scheme.Equals("file", StringComparison.OrdinalIgnoreCase))
                localPath = uri.LocalPath;
        }

        if (Path.IsPathRooted(localPath) && File.Exists(localPath))
            return localPath;

        var idx = localPath.Replace('\\', '/').IndexOf("images/", StringComparison.OrdinalIgnoreCase);
        if (idx >= 0)
        {
            var rel = localPath.Replace('\\', '/').Substring(idx + "images/".Length);
            if (string.IsNullOrWhiteSpace(rel))
                return null;
            return Path.Combine(imagesPath, rel);
        }

        if (!Path.IsPathRooted(localPath))
            return Path.Combine(imagesPath, localPath);

        var filename = Path.GetFileName(localPath);
        if (!string.IsNullOrWhiteSpace(filename))
        {
            var candidate = Path.Combine(imagesPath, filename);
            if (File.Exists(candidate))
                return candidate;
        }

        return localPath;
    }
}
