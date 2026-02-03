using System.Text.Json.Serialization;
using PhotobookPro.Core.Json;

namespace PhotobookPro.Core.Models.Layers;

[JsonConverter(typeof(AnyLayerJsonConverter))]
public sealed record AnyLayer
{
    public required string Type { get; init; }
    public required ILayer Data { get; init; }
}

