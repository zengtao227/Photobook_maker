using System.Text.Json.Serialization;
using PhotobookPro.Core.Json;
using PhotobookPro.Core.Models;

namespace PhotobookPro.Core.Models.Layers;

public sealed record StickerLayer : ILayer
{
    [JsonPropertyName("id")]
    public required LayerId Id { get; init; }

    [JsonPropertyName("type")]
    public string Type { get; init; } = "sticker";

    [JsonPropertyName("frame")]
    public required PbRect Frame { get; init; }

    [JsonPropertyName("rotation")]
    public double Rotation { get; init; }

    [JsonPropertyName("zIndex")]
    public int ZIndex { get; init; }

    [JsonPropertyName("isLocked")]
    public bool IsLocked { get; init; }

    [JsonPropertyName("content")]
    [JsonConverter(typeof(StickerContentJsonConverter))]
    public required StickerContent Content { get; init; }

    [JsonPropertyName("colorHex")]
    public string? ColorHex { get; init; }

    [JsonPropertyName("shadowRadius")]
    public double ShadowRadius { get; init; }

    [JsonPropertyName("shadowOpacity")]
    public double ShadowOpacity { get; init; } = 0.5;
}

