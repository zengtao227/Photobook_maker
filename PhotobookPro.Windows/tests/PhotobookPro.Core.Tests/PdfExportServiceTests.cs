using PhotobookPro.Core.Export;
using PhotobookPro.Core.Models;

namespace PhotobookPro.Core.Tests;

public class PdfExportServiceTests
{
    [Fact]
    public void ExportManifestToPdfPrecise_CreatesPdfFile()
    {
        var manifest = new Manifest
        {
            Version = "1.0",
            CreatedAt = DateTimeOffset.UtcNow,
            ModifiedAt = DateTimeOffset.UtcNow,
            ProjectName = "Test",
            PageSize = "A5 Landscape",
            Spreads =
            [
                new Manifest.SpreadData
                {
                    LeftPage = new PageModel
                    {
                        Id = Guid.NewGuid(),
                        PageNumber = 0,
                        Layers = [],
                        BackgroundColorHex = "#FFFFFF"
                    },
                    RightPage = new PageModel
                    {
                        Id = Guid.NewGuid(),
                        PageNumber = 1,
                        Layers = [],
                        BackgroundColorHex = "#FFFFFF"
                    }
                }
            ]
        };

        var output = Path.Combine(Path.GetTempPath(), $"photobook_{Guid.NewGuid():N}.pdf");

        PdfExportService.ExportManifestToPdfPrecise(manifest, output);

        Assert.True(File.Exists(output));
        Assert.True(new FileInfo(output).Length > 100);
    }
}

