using PhotobookPro.Core.Models;

namespace PhotobookPro.Core.Models.Layers;

public interface ILayer
{
    LayerId Id { get; }
    string Type { get; }
    PbRect Frame { get; }
    double Rotation { get; }
    int ZIndex { get; }
    bool IsLocked { get; }
}

