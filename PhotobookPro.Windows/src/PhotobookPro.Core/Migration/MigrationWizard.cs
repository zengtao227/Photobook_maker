using PhotobookPro.Core.Models;
using PhotobookPro.Core.Models.Layers;

namespace PhotobookPro.Core.Migration;

public static class MigrationWizard
{
    public static MigrationReport AnalyzeMissingAssets(Manifest manifest)
    {
        var missing = new List<MissingAsset>();

        for (var spreadIndex = 0; spreadIndex < manifest.Spreads.Count; spreadIndex++)
        {
            var spread = manifest.Spreads[spreadIndex];
            CollectMissingFromPage(missing, spreadIndex, "left", spread.LeftPage);
            CollectMissingFromPage(missing, spreadIndex, "right", spread.RightPage);
        }

        return missing.Count == 0
            ? MigrationReport.Empty
            : new MigrationReport { MissingAssets = missing };
    }

    public static Manifest RelinkMissingAssets(Manifest manifest, string mediaRoot)
    {
        if (string.IsNullOrWhiteSpace(mediaRoot))
            throw new ArgumentException("Media root is required", nameof(mediaRoot));

        var spreads = new List<Manifest.SpreadData>(manifest.Spreads.Count);

        for (var spreadIndex = 0; spreadIndex < manifest.Spreads.Count; spreadIndex++)
        {
            var spread = manifest.Spreads[spreadIndex];
            spreads.Add(spread with
            {
                LeftPage = RelinkPage(spread.LeftPage, mediaRoot),
                RightPage = RelinkPage(spread.RightPage, mediaRoot)
            });
        }

        return manifest with { Spreads = spreads };
    }

    private static void CollectMissingFromPage(List<MissingAsset> missing, int spreadIndex, string side, PageModel page)
    {
        foreach (var wrapper in page.Layers)
        {
            switch (wrapper.Type)
            {
                case "photo":
                {
                    var layer = (PhotoLayer)wrapper.Data;
                    var localPath = AssetPath.NormalizeToLocalPath(layer.PhotoUrl);
                    if (!File.Exists(localPath))
                    {
                        missing.Add(new MissingAsset(spreadIndex, side, "photo", layer.Id.Id, layer.PhotoUrl));
                    }
                    break;
                }
                case "sticker":
                {
                    var layer = (StickerLayer)wrapper.Data;
                    if (layer.Content.Url is null)
                        break;
                    var localPath = AssetPath.NormalizeToLocalPath(layer.Content.Url);
                    if (!File.Exists(localPath))
                    {
                        missing.Add(new MissingAsset(spreadIndex, side, "sticker", layer.Id.Id, layer.Content.Url));
                    }
                    break;
                }
            }
        }
    }

    private static PageModel RelinkPage(PageModel page, string mediaRoot)
    {
        var layers = page.Layers.Select(layer =>
        {
            return layer.Type switch
            {
                "photo" => layer with { Data = RelinkPhotoLayer((PhotoLayer)layer.Data, mediaRoot) },
                "sticker" => layer with { Data = RelinkStickerLayer((StickerLayer)layer.Data, mediaRoot) },
                _ => layer
            };
        }).ToList();

        return page with { Layers = layers };
    }

    private static PhotoLayer RelinkPhotoLayer(PhotoLayer layer, string mediaRoot)
    {
        var localPath = AssetPath.NormalizeToLocalPath(layer.PhotoUrl);
        if (File.Exists(localPath))
            return layer;

        var filename = AssetPath.ExtractFilename(localPath);
        if (filename is null)
            return layer;

        var candidate = Path.Combine(mediaRoot, filename);
        if (File.Exists(candidate))
            return layer with { PhotoUrl = candidate };

        var imagesCandidate = Path.Combine(mediaRoot, "Images", filename);
        if (File.Exists(imagesCandidate))
            return layer with { PhotoUrl = imagesCandidate };

        return layer;
    }

    private static StickerLayer RelinkStickerLayer(StickerLayer layer, string mediaRoot)
    {
        if (layer.Content.Url is null)
            return layer;

        var localPath = AssetPath.NormalizeToLocalPath(layer.Content.Url);
        if (File.Exists(localPath))
            return layer;

        var filename = AssetPath.ExtractFilename(localPath);
        if (filename is null)
            return layer;

        var candidate = Path.Combine(mediaRoot, filename);
        if (File.Exists(candidate))
            return layer with { Content = layer.Content with { Url = candidate } };

        var imagesCandidate = Path.Combine(mediaRoot, "Images", filename);
        if (File.Exists(imagesCandidate))
            return layer with { Content = layer.Content with { Url = imagesCandidate } };

        return layer;
    }
}

