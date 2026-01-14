const Point = @import("point.zig").Point;

/// Point de perçage
pub const DrillHole = struct {
    position: Point = .{ .x = 0, .y = 0 },
    diameter: f64 = 3.0, // Diamètre par défaut 3mm
};
