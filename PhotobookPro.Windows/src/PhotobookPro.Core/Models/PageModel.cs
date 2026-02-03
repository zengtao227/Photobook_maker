using System.Text.Json.Serialization;
using PhotobookPro.Core.Models.Layers;

namespace PhotobookPro.Core.Models;

public sealed record PageModel
{
    [JsonPropertyName("id")]
    public Guid Id { get; init; }

    [JsonPropertyName("pageNumber")]
    public int PageNumber { get; init; }

    [JsonPropertyName("layers")]
    public required List<AnyLayer> Layers { get; init; }

    [JsonPropertyName("backgroundColorHex")]
    public string BackgroundColorHex { get; init; } = "#FFFFFF";

    [JsonPropertyName("backgroundType")]
    public string BackgroundType { get; init; } = "solid";

    [JsonPropertyName("gradientColors")]
    public List<string>? GradientColors { get; init; }

    [JsonPropertyName("patternType")]
    public string? PatternType { get; init; }

    [JsonPropertyName("textureType")]
    public string? TextureType { get; init; }

    [JsonPropertyName("backgroundOpacity")]
    public double BackgroundOpacity { get; init; } = 1.0;
}

