using System.Text.Json;
using PhotobookPro.Core.Layouts;
using PhotobookPro.Core.Models;

namespace PhotobookPro.Core.Tests;

public class LayoutTemplateFixtureTests
{
    [Fact]
    public void LayoutTemplates_MatchSwiftFixtures()
    {
        var fixturesPath = Path.Combine(AppContext.BaseDirectory, "Fixtures", "LayoutTemplateFixtures.json");
        var json = File.ReadAllText(fixturesPath);

        var options = new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        var fixtures = JsonSerializer.Deserialize<LayoutTemplateFixtures>(json, options);
        Assert.NotNull(fixtures);

        foreach (var best in fixtures!.BestByPhotoCount)
        {
            var actual = LayoutTemplates.BestTemplateForPhotoCount(best.Count);
            Assert.Equal(best.Template, actual);
        }

        foreach (var template in fixtures.Templates)
        {
            var actualSlots = LayoutTemplates.GetSlots(template.Name);
            Assert.Equal(template.Slots.Count, actualSlots.Count);

            for (var i = 0; i < template.Slots.Count; i++)
            {
                AssertRectAlmostEqual(template.Slots[i], actualSlots[i], 1e-9);
            }
        }
    }

    private static void AssertRectAlmostEqual(PbRect expected, PbRect actual, double epsilon)
    {
        AssertPointAlmostEqual(expected.Origin, actual.Origin, epsilon);
        AssertSizeAlmostEqual(expected.Size, actual.Size, epsilon);
    }

    private static void AssertPointAlmostEqual(PbPoint expected, PbPoint actual, double epsilon)
    {
        Assert.True(Math.Abs(expected.X - actual.X) <= epsilon, $"X expected {expected.X} actual {actual.X}");
        Assert.True(Math.Abs(expected.Y - actual.Y) <= epsilon, $"Y expected {expected.Y} actual {actual.Y}");
    }

    private static void AssertSizeAlmostEqual(PbSize expected, PbSize actual, double epsilon)
    {
        Assert.True(Math.Abs(expected.Width - actual.Width) <= epsilon, $"Width expected {expected.Width} actual {actual.Width}");
        Assert.True(Math.Abs(expected.Height - actual.Height) <= epsilon, $"Height expected {expected.Height} actual {actual.Height}");
    }

    private sealed record LayoutTemplateFixtures
    {
        public required int SchemaVersion { get; init; }
        public required List<TemplateFixture> Templates { get; init; }
        public required List<BestTemplateFixture> BestByPhotoCount { get; init; }
    }

    private sealed record TemplateFixture
    {
        public required string Name { get; init; }
        public required List<PbRect> Slots { get; init; }
    }

    private sealed record BestTemplateFixture
    {
        public required int Count { get; init; }
        public required string Template { get; init; }
    }
}

