namespace PhotobookPro.Core.Migration;

public static class AssetPath
{
    public static string NormalizeToLocalPath(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
            return raw;

        if (Uri.TryCreate(raw, UriKind.Absolute, out var uri))
        {
            if (uri.Scheme.Equals("file", StringComparison.OrdinalIgnoreCase))
                return uri.LocalPath;
        }

        return raw;
    }

    public static string? ExtractFilename(string localPath)
    {
        if (string.IsNullOrWhiteSpace(localPath))
            return null;

        var filename = Path.GetFileName(localPath);
        return string.IsNullOrWhiteSpace(filename) ? null : filename;
    }
}

