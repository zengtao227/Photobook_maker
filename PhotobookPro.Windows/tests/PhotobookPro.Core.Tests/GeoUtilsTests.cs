using PhotobookPro.Core.Geo;

namespace PhotobookPro.Core.Tests;

public class GeoUtilsTests
{
    [Fact]
    public void DistanceKilometers_ReturnsZeroForSamePoint()
    {
        var d = GeoUtils.DistanceKilometers(0, 0, 0, 0);
        Assert.True(Math.Abs(d) < 1e-12);
    }

    [Fact]
    public void DistanceKilometers_ApproximatesKnownDistance()
    {
        var d = GeoUtils.DistanceKilometers(0, 0, 0, 1);
        Assert.InRange(d, 110.0, 112.0);
    }
}

