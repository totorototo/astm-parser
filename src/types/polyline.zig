const Point = @import("point.zig").Point;
const LineQuality = @import("line_quality.zig").LineQuality;

/// Polyligne avec qualité de ligne
pub const Polyline = struct {
    points: []Point = &[_]Point{},
    quality: LineQuality = .cut,
    closed: bool = false,
};
