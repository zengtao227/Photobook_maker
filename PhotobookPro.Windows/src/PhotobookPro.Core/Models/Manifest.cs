using System.Text.Json.Serialization;

namespace PhotobookPro.Core.Models;

public sealed record Manifest
{
    [JsonPropertyName("version")]
    public required string Version { get; init; }

    [JsonPropertyName("createdAt")]
    public required DateTimeOffset CreatedAt { get; init; }

    [JsonPropertyName("modifiedAt")]
    public required DateTimeOffset ModifiedAt { get; init; }

    [JsonPropertyName("projectName")]
    public required string ProjectName { get; init; }

    [JsonPropertyName("pageSize")]
    public required string PageSize { get; init; }

    [JsonPropertyName("spreads")]
    public required List<SpreadData> Spreads { get; init; }

    public sealed record SpreadData
    {
        [JsonPropertyName("leftPage")]
        public required PageModel LeftPage { get; init; }

        [JsonPropertyName("rightPage")]
        public required PageModel RightPage { get; init; }
    }
}

