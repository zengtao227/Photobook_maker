using System.Text.Json.Serialization;
using PhotobookPro.Core.Models;

namespace PhotobookPro.Core.Models.Layers;

public sealed record TextLayer : ILayer
{
    [JsonPropertyName("id")]
    public required LayerId Id { get; init; }

    [JsonPropertyName("type")]
    public string Type { get; init; } = "text";

    [JsonPropertyName("frame")]
    public required PbRect Frame { get; init; }

    [JsonPropertyName("rotation")]
    public double Rotation { get; init; }

    [JsonPropertyName("zIndex")]
    public int ZIndex { get; init; }

    [JsonPropertyName("isLocked")]
    public bool IsLocked { get; init; }

    [JsonPropertyName("text")]
    public required string Text { get; init; }

    [JsonPropertyName("fontSize")]
    public double FontSize { get; init; } = 24;

    [JsonPropertyName("fontName")]
    public string FontName { get; init; } = "Helvetica Neue";

    [JsonPropertyName("isBold")]
    public bool IsBold { get; init; }

    [JsonPropertyName("isItalic")]
    public bool IsItalic { get; init; }

    [JsonPropertyName("colorHex")]
    public string ColorHex { get; init; } = "#000000";

    [JsonPropertyName("backgroundColorHex")]
    public string? BackgroundColorHex { get; init; }

    [JsonPropertyName("alignment")]
    public string Alignment { get; init; } = "center";
}

