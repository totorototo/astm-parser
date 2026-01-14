const Point = @import("point.zig").Point;
const LineQuality = @import("line_quality.zig").LineQuality;

/// Arc défini par 3 points (start, mid, end) - format ASTM
pub const Arc = struct {
    start: Point = .{ .x = 0, .y = 0 },
    mid: Point = .{ .x = 0, .y = 0 },
    end_pt: Point = .{ .x = 0, .y = 0 },
    quality: LineQuality = .cut,
};
