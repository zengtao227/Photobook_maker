using PhotobookPro.Core.Portable;

namespace PhotobookPro.Core.Tests;

public class PhotobookBundleReaderTests
{
    [Fact]
    public void Read_NormalizesRelativeImagePaths_ToBundleImagesDirectory()
    {
        var bundlePath = Path.Combine(Path.GetTempPath(), $"photobook_{Guid.NewGuid():N}.photobook");
        var imagesPath = Path.Combine(bundlePath, "images");
        Directory.CreateDirectory(imagesPath);

        var manifestPath = Path.Combine(bundlePath, "manifest.json");
        File.WriteAllText(manifestPath, CreateManifestJson("images/image_0.png"));

        var bundle = PhotobookBundleReader.Read(bundlePath);

        var photoUrl = bundle.Manifest.Spreads[0].LeftPage.Layers[0].Type switch
        {
            "photo" => ((PhotobookPro.Core.Models.Layers.PhotoLayer)bundle.Manifest.Spreads[0].LeftPage.Layers[0].Data).PhotoUrl,
            _ => throw new Exception("Unexpected layer type")
        };

        Assert.Equal(Path.Combine(imagesPath, "image_0.png"), photoUrl);
    }

    [Fact]
    public void Read_RemapMissingAbsoluteFileUrlByFilename_WhenBundleContainsMatch()
    {
        var bundlePath = Path.Combine(Path.GetTempPath(), $"photobook_{Guid.NewGuid():N}.photobook");
        var imagesPath = Path.Combine(bundlePath, "images");
        Directory.CreateDirectory(imagesPath);
        File.WriteAllBytes(Path.Combine(imagesPath, "image_0.png"), Array.Empty<byte>());

        var manifestPath = Path.Combine(bundlePath, "manifest.json");
        File.WriteAllText(manifestPath, CreateManifestJson("file:///Users/zengtao/Downloads/image_0.png"));

        var bundle = PhotobookBundleReader.Read(bundlePath);

        var photoUrl = ((PhotobookPro.Core.Models.Layers.PhotoLayer)bundle.Manifest.Spreads[0].LeftPage.Layers[0].Data).PhotoUrl;

        Assert.Equal(Path.Combine(imagesPath, "image_0.png"), photoUrl);
    }

    private static string CreateManifestJson(string photoUrl)
    {
        var createdAt = DateTimeOffset.UtcNow.ToString("O");
        var modifiedAt = DateTimeOffset.UtcNow.ToString("O");
        var manifestId = Guid.NewGuid();
        var photoId = Guid.NewGuid();
        var layerId = Guid.NewGuid();
        var pageId = Guid.NewGuid();

        return $$"""
        {
          "version": "1.0",
          "createdAt": "{{createdAt}}",
          "modifiedAt": "{{modifiedAt}}",
          "projectName": "Test",
          "pageSize": "A4",
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
                "id": "{{manifestId}}",
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
