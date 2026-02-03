namespace PhotobookPro.Core.Export;

public sealed record PdfExportOptions
{
    public int Dpi { get; init; } = 300;
}

