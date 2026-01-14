const Point = @import("point.zig").Point;
const LineQuality = @import("line_quality.zig").LineQuality;

/// Cercle complet
pub const Circle = struct {
    center: Point = .{ .x = 0, .y = 0 },
    radius: f64 = 0,
    quality: LineQuality = .cut,
};
