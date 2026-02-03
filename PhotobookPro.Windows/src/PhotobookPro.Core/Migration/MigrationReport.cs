using PhotobookPro.Core.Models;

namespace PhotobookPro.Core.Migration;

public sealed record MissingAsset(
    int SpreadIndex,
    string PageSide,
    string LayerType,
    Guid LayerId,
    string RawPath
);

public sealed record MigrationReport
{
    public required List<MissingAsset> MissingAssets { get; init; }

    public int MissingCount => MissingAssets.Count;

    public static MigrationReport Empty { get; } = new() { MissingAssets = [] };
}

