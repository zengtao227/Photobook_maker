using System.Text.Json;
using System.Text.Json.Serialization;
using PhotobookPro.Core.Models.Layers;

namespace PhotobookPro.Core.Json;

public sealed class AnyLayerJsonConverter : JsonConverter<AnyLayer>
{
    public override AnyLayer Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        using var document = JsonDocument.ParseValue(ref reader);
        var root = document.RootElement;

        var type = root.GetProperty("type").GetString();
        if (string.IsNullOrWhiteSpace(type))
            throw new JsonException("Missing layer type");

        var dataElement = root.GetProperty("data");

        ILayer data = type switch
        {
            "photo" => dataElement.Deserialize<PhotoLayer>(options) ?? throw new JsonException("Invalid photo layer"),
            "text" => dataElement.Deserialize<TextLayer>(options) ?? throw new JsonException("Invalid text layer"),
            "sticker" => dataElement.Deserialize<StickerLayer>(options) ?? throw new JsonException("Invalid sticker layer"),
            _ => throw new JsonException($"Unsupported layer type: {type}")
        };

        return new AnyLayer { Type = type, Data = data };
    }

    public override void Write(Utf8JsonWriter writer, AnyLayer value, JsonSerializerOptions options)
    {
        writer.WriteStartObject();
        writer.WriteString("type", value.Type);
        writer.WritePropertyName("data");
        switch (value.Type)
        {
            case "photo":
                JsonSerializer.Serialize(writer, (PhotoLayer)value.Data, options);
                break;
            case "text":
                JsonSerializer.Serialize(writer, (TextLayer)value.Data, options);
                break;
            case "sticker":
                JsonSerializer.Serialize(writer, (StickerLayer)value.Data, options);
                break;
            default:
                throw new JsonException($"Unsupported layer type: {value.Type}");
        }
        writer.WriteEndObject();
    }
}

