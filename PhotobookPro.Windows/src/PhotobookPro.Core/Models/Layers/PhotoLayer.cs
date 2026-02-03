using System.Text.Json.Serialization;
using PhotobookPro.Core.Models;

namespace PhotobookPro.Core.Models.Layers;

public sealed record PhotoLayer : ILayer
{
    [JsonPropertyName("id")]
    public required LayerId Id { get; init; }

    [JsonPropertyName("type")]
    public string Type { get; init; } = "photo";

    [JsonPropertyName("frame")]
    public required PbRect Frame { get; init; }

    [JsonPropertyName("rotation")]
    public double Rotation { get; init; }

    [JsonPropertyName("zIndex")]
    public int ZIndex { get; init; }

    [JsonPropertyName("isLocked")]
    public bool IsLocked { get; init; }

    [JsonPropertyName("photoId")]
    public required Guid PhotoId { get; init; }

    [JsonPropertyName("photoUrl")]
    public required string PhotoUrl { get; init; }

    [JsonPropertyName("maskType")]
    public string MaskType { get; init; } = "rectangle";

    [JsonPropertyName("cropScale")]
    public double CropScale { get; init; } = 1.0;

    [JsonPropertyName("cropOffset")]
    public PbSize CropOffset { get; init; }

    [JsonPropertyName("normalizedCropRect")]
    public PbRect? NormalizedCropRect { get; init; }

    [JsonPropertyName("cropRotation")]
    public double CropRotation { get; init; }

    [JsonPropertyName("filterType")]
    public string FilterType { get; init; } = "原图";

    [JsonPropertyName("brightness")]
    public double Brightness { get; init; }

    [JsonPropertyName("contrast")]
    public double Contrast { get; init; } = 1.0;

    [JsonPropertyName("saturation")]
    public double Saturation { get; init; } = 1.0;

    [JsonPropertyName("vignetteIntensity")]
    public double VignetteIntensity { get; init; }

    [JsonPropertyName("sharpenIntensity")]
    public double SharpenIntensity { get; init; }

    [JsonPropertyName("temperature")]
    public double Temperature { get; init; } = 6500;

    [JsonPropertyName("borderWidth")]
    public double BorderWidth { get; init; }

    [JsonPropertyName("borderColorHex")]
    public string BorderColorHex { get; init; } = "#FFFFFF";

    [JsonPropertyName("shadowRadius")]
    public double ShadowRadius { get; init; }

    [JsonPropertyName("shadowOpacity")]
    public double ShadowOpacity { get; init; }

    [JsonPropertyName("shadowOffset")]
    public PbSize ShadowOffset { get; init; }
}

