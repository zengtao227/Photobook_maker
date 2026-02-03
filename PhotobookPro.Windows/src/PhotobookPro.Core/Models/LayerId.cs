using System.Text.Json.Serialization;

namespace PhotobookPro.Core.Models;

public readonly record struct LayerId([property: JsonPropertyName("id")] Guid Id);

