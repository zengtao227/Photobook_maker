using PhotobookPro.Core.Migration;
using PhotobookPro.Core.Portable;

namespace PhotobookPro.Core.Tests;

public class MigrationWizardTests
{
    [Fact]
    public void AnalyzeMissingAssets_FindsMissingPhotoUrls()
    {
        var bundlePath = Path.Combine(Path.GetTempPath(), $"photobook_{Guid.NewGuid():N}.photobook");
        Directory.CreateDirectory(Path.Combine(bundlePath, "images"));

        var manifestPath = Path.Combine(bundlePath, "manifest.json");
        File.WriteAllText(manifestPath, CreateManifestJson("file:///Users/zengtao/DoesNotExist/image_0.png"));

        var bundle = PhotobookBundleReader.Read(bundlePath);
        var report = MigrationWizard.AnalyzeMissingAssets(bundle.Manifest);

        Assert.True(report.MissingCount >= 1);
        Assert.Contains(report.MissingAssets, m => m.LayerType == "photo");
    }

    [Fact]
    public void RelinkMissingAssets_UsesMediaRootImagesFolderWhenFilenameMatches()
    {
        var bundlePath = Path.Combine(Path.GetTempPath(), $"photobook_{Guid.NewGuid():N}.photobook");
        Directory.CreateDirectory(Path.Combine(bundlePath, "images"));

        var mediaRoot = Path.Combine(Path.GetTempPath(), $"media_{Guid.NewGuid():N}");
        var mediaImages = Path.Combine(mediaRoot, "Images");
        Directory.CreateDirectory(mediaImages);
        File.WriteAllBytes(Path.Combine(mediaImages, "image_0.png"), Array.Empty<byte>());

        var manifestPath = Path.Combine(bundlePath, "manifest.json");
        File.WriteAllText(manifestPath, CreateManifestJson("file:///Users/zengtao/DoesNotExist/image_0.png"));

        var bundle = PhotobookBundleReader.Read(bundlePath);
        var migrated = MigrationWizard.RelinkMissingAssets(bundle.Manifest, mediaRoot);

        var actual = ((PhotobookPro.Core.Models.Layers.PhotoLayer)migrated.Spreads[0].LeftPage.Layers[0].Data).PhotoUrl;
        Assert.Equal(Path.Combine(mediaImages, "image_0.png"), actual);
    }

    private static string CreateManifestJson(string photoUrl)
    {
        var createdAt = DateTimeOffset.UtcNow.ToString("O");
        var modifiedAt = DateTimeOffset.UtcNow.ToString("O");
        var photoId = Guid.NewGuid();
        var layerId = Guid.NewGuid();
        var pageId = Guid.NewGuid();

        return $$"""
        {
          "version": "1.0",
          "createdAt": "{{createdAt}}",
          "modifiedAt": "{{modifiedAt}}",
          "projectName": "Test",
          "pageSize": "A4 Landscape",
          "spreads": [
            {
              "leftPage": {
                "id": "{{pageId}}",
                "pageNumber": 0,
                "layers": [
                  {
                    "type": "photo",
                    "data": {
                      "id": { "id": "{{layerId}}" },
                      "type": "photo",
                      "frame": {
                        "origin": { "x": 0, "y": 0 },
                        "size": { "width": 100, "height": 100 }
                      },
                      "rotation": 0,
                      "zIndex": 0,
                      "isLocked": false,
                      "photoId": "{{photoId}}",
                      "photoUrl": "{{photoUrl}}"
                    }
                  }
                ],
                "backgroundColorHex": "#FFFFFF",
                "backgroundType": "solid",
                "gradientColors": null,
                "patternType": null,
                "textureType": null,
                "backgroundOpacity": 1
              },
              "rightPage": {
                "id": "{{Guid.NewGuid()}}",
                "pageNumber": 1,
                "layers": [],
                "backgroundColorHex": "#FFFFFF",
                "backgroundType": "solid",
                "gradientColors": null,
                "patternType": null,
                "textureType": null,
                "backgroundOpacity": 1
              }
            }
          ]
        }
        """;
    }
}

