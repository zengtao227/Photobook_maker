using System.Text.Json;
using System.Text.Json.Serialization;
using PhotobookPro.Core.Models.Layers;

namespace PhotobookPro.Core.Json;

public sealed class StickerContentJsonConverter : JsonConverter<StickerContent>
{
    public override StickerContent Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        using var document = JsonDocument.ParseValue(ref reader);
        var root = document.RootElement;

        if (root.ValueKind != JsonValueKind.Object)
            throw new JsonException("StickerContent must be an object");

        string? url = null;
        string? systemImage = null;
        string? emoji = null;

        if (root.TryGetProperty("url", out var urlEl))
            url = urlEl.GetString();

        if (root.TryGetProperty("systemImage", out var systemEl))
            systemImage = systemEl.GetString();

        if (root.TryGetProperty("emoji", out var emojiEl))
            emoji = emojiEl.GetString();

        var setCount =
            (url is null ? 0 : 1) +
            (systemImage is null ? 0 : 1) +
            (emoji is null ? 0 : 1);

        if (setCount != 1)
            throw new JsonException("StickerContent must contain exactly one of: url, systemImage, emoji");

        return new StickerContent { Url = url, SystemImage = systemImage, Emoji = emoji };
    }

    public override void Write(Utf8JsonWriter writer, StickerContent value, JsonSerializerOptions options)
    {
        var setCount =
            (value.Url is null ? 0 : 1) +
            (value.SystemImage is null ? 0 : 1) +
            (value.Emoji is null ? 0 : 1);

        if (setCount != 1)
            throw new JsonException("StickerContent must contain exactly one of: Url, SystemImage, Emoji");

        writer.WriteStartObject();
        if (value.Url is not null)
            writer.WriteString("url", value.Url);
        if (value.SystemImage is not null)
            writer.WriteString("systemImage", value.SystemImage);
        if (value.Emoji is not null)
            writer.WriteString("emoji", value.Emoji);
        writer.WriteEndObject();
    }
}

