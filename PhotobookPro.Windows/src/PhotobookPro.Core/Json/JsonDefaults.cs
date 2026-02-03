using System.Text.Json;
using System.Text.Json.Serialization;
using PhotobookPro.Core.Models;
using PhotobookPro.Core.Models.Layers;

namespace PhotobookPro.Core.Json;

public static class JsonDefaults
{
    public static readonly JsonSerializerOptions Options = CreateOptions();

    private static JsonSerializerOptions CreateOptions()
    {
        var options = new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            PropertyNameCaseInsensitive = true,
            WriteIndented = true,
        };

        options.Converters.Add(new JsonStringEnumConverter(JsonNamingPolicy.CamelCase));
        options.Converters.Add(new AnyLayerJsonConverter());
        options.Converters.Add(new StickerContentJsonConverter());

        return options;
    }
}

