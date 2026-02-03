using System.Text.Json.Serialization;

namespace PhotobookPro.Core.Models;

public readonly record struct PbPoint(
    [property: JsonPropertyName("x")] double X,
    [property: JsonPropertyName("y")] double Y
);

public readonly record struct PbSize(
    [property: JsonPropertyName("width")] double Width,
    [property: JsonPropertyName("height")] double Height
);

public readonly record struct PbRect(
    [property: JsonPropertyName("origin")] PbPoint Origin,
    [property: JsonPropertyName("size")] PbSize Size
);

