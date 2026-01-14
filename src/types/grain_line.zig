const Point = @import("point.zig").Point;

/// Ligne de grain
pub const GrainLine = struct {
    start: Point = .{ .x = 0, .y = 0 },
    end_pt: Point = .{ .x = 0, .y = 0 },
};
