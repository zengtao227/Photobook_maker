using PhotobookPro.Core.Models;

namespace PhotobookPro.Core.Portable;

public sealed record PhotobookBundle
{
    public required string BundlePath { get; init; }
    public required Manifest Manifest { get; init; }
    public required string ImagesPath { get; init; }
}

