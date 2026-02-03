using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

// Set license to Community to avoid watermark/exception (check terms!)
QuestPDF.Settings.License = LicenseType.Community;

Document.Create(container =>
{
    container.Page(page =>
    {
        page.Size(PageSizes.A4);
        page.Margin(2, Unit.Centimetre);
        page.PageColor(Colors.White);
        page.DefaultTextStyle(x => x.FontSize(20));

        page.Header()
            .Text("PhotobookPro Windows POC")
            .SemiBold().FontSize(30).FontColor(Colors.Blue.Medium);

        page.Content()
            .PaddingVertical(1, Unit.Centimetre)
            .Column(x =>
            {
                x.Item().Text("Hello World");
                // Attempt to use system Chinese font
                x.Item().Text("你好，世界 (PingFang SC)").FontFamily("PingFang SC");
                x.Item().Text("你好，世界 (Arial Unicode MS)").FontFamily("Arial Unicode MS");
                x.Item().Text("Simpler default text: 你好");
            });

        page.Footer()
            .AlignCenter()
            .Text(x =>
            {
                x.Span("Page ");
                x.CurrentPageNumber();
            });
    });
})
.GeneratePdf("hello.pdf");

Console.WriteLine("PDF Generated: hello.pdf");
