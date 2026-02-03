namespace PhotobookPro.Core.Export;

public static class BookPageSizeSpec
{
    private const double PointsPerMillimeter = 2.83465;

    public static (double widthPt, double heightPt) GetSinglePagePoints(string pageSize)
    {
        var mm = pageSize switch
        {
            "A4 Landscape" => (297d, 210d),
            "A5 Landscape" => (210d, 148d),
            "A6 Landscape" => (148d, 105d),
            "Square (30x30)" => (300d, 300d),
            "Square (21x21)" => (210d, 210d),
            _ => (210d, 148d)
        };

        return (mm.Item1 * PointsPerMillimeter, mm.Item2 * PointsPerMillimeter);
    }

    public static (double widthPt, double heightPt) GetSpreadPoints(string pageSize)
    {
        var (w, h) = GetSinglePagePoints(pageSize);
        return (w * 2, h);
    }
}

