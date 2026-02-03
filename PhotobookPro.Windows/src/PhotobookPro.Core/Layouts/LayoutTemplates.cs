using PhotobookPro.Core.Models;

namespace PhotobookPro.Core.Layouts;

public static class LayoutTemplates
{
    private static readonly IReadOnlyDictionary<string, IReadOnlyList<PbRect>> SlotsByTemplate =
        new Dictionary<string, IReadOnlyList<PbRect>>(StringComparer.Ordinal)
        {
            ["singleFull"] = new[]
            {
                new PbRect(new PbPoint(0, 0), new PbSize(1, 1))
            },
            ["singleCentered"] = new[]
            {
                new PbRect(new PbPoint(0.1, 0.1), new PbSize(0.8, 0.8))
            },
            ["twoVertical"] = new[]
            {
                new PbRect(new PbPoint(0.1, 0.05), new PbSize(0.8, 0.425)),
                new PbRect(new PbPoint(0.1, 0.525), new PbSize(0.8, 0.425))
            },
            ["twoHorizontal"] = new[]
            {
                new PbRect(new PbPoint(0.05, 0.1), new PbSize(0.425, 0.8)),
                new PbRect(new PbPoint(0.525, 0.1), new PbSize(0.425, 0.8))
            },
            ["threeGrid"] = new[]
            {
                new PbRect(new PbPoint(0.05, 0.05), new PbSize(0.9, 0.43)),
                new PbRect(new PbPoint(0.05, 0.52), new PbSize(0.43, 0.43)),
                new PbRect(new PbPoint(0.52, 0.52), new PbSize(0.43, 0.43))
            },
            ["threeArtistic"] = new[]
            {
                new PbRect(new PbPoint(0.1, 0.1), new PbSize(0.5, 0.8)),
                new PbRect(new PbPoint(0.65, 0.1), new PbSize(0.25, 0.35)),
                new PbRect(new PbPoint(0.65, 0.55), new PbSize(0.25, 0.35))
            },
            ["fourGrid"] = new[]
            {
                new PbRect(new PbPoint(0.05, 0.05), new PbSize(0.43, 0.43)),
                new PbRect(new PbPoint(0.52, 0.05), new PbSize(0.43, 0.43)),
                new PbRect(new PbPoint(0.05, 0.52), new PbSize(0.43, 0.43)),
                new PbRect(new PbPoint(0.52, 0.52), new PbSize(0.43, 0.43))
            },
            ["fiveHighlight"] = new[]
            {
                new PbRect(new PbPoint(0.05, 0.05), new PbSize(0.9, 0.4)),
                new PbRect(new PbPoint(0.05, 0.5), new PbSize(0.2, 0.45)),
                new PbRect(new PbPoint(0.275, 0.5), new PbSize(0.2, 0.45)),
                new PbRect(new PbPoint(0.5, 0.5), new PbSize(0.2, 0.45)),
                new PbRect(new PbPoint(0.725, 0.5), new PbSize(0.2, 0.45))
            }
        };

    public static IReadOnlyList<string> AllTemplateNames { get; } =
        ["singleFull", "singleCentered", "twoVertical", "twoHorizontal", "threeGrid", "threeArtistic", "fourGrid", "fiveHighlight"];

    public static string BestTemplateForPhotoCount(int count) =>
        count switch
        {
            <= 1 => "singleFull",
            2 => "twoVertical",
            3 => "threeGrid",
            4 => "fourGrid",
            5 => "fiveHighlight",
            _ => "fourGrid"
        };

    public static IReadOnlyList<PbRect> GetSlots(string templateName)
    {
        if (!SlotsByTemplate.TryGetValue(templateName, out var slots))
            throw new ArgumentOutOfRangeException(nameof(templateName), $"Unknown template: {templateName}");
        return slots;
    }
}

