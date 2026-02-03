using SkiaSharp;

namespace PhotobookPro.Core.Export;

public static class ColorUtils
{
    public static SKColor ParseHex(string hex, SKColor fallback)
    {
        if (string.IsNullOrWhiteSpace(hex))
            return fallback;

        var raw = hex.Trim();
        if (raw.StartsWith('#'))
            raw = raw[1..];

        if (raw.Length == 6)
        {
            if (uint.TryParse(raw, System.Globalization.NumberStyles.HexNumber, null, out var rgb))
            {
                var r = (byte)((rgb >> 16) & 0xFF);
                var g = (byte)((rgb >> 8) & 0xFF);
                var b = (byte)(rgb & 0xFF);
                return new SKColor(r, g, b, 0xFF);
            }
        }

        if (raw.Length == 8)
        {
            if (uint.TryParse(raw, System.Globalization.NumberStyles.HexNumber, null, out var argb))
            {
                var a = (byte)((argb >> 24) & 0xFF);
                var r = (byte)((argb >> 16) & 0xFF);
                var g = (byte)((argb >> 8) & 0xFF);
                var b = (byte)(argb & 0xFF);
                return new SKColor(r, g, b, a);
            }
        }

        return fallback;
    }
}

