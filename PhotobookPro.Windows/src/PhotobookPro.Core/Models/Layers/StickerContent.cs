namespace PhotobookPro.Core.Models.Layers;

public sealed record StickerContent
{
    public string? Url { get; init; }
    public string? SystemImage { get; init; }
    public string? Emoji { get; init; }
}

