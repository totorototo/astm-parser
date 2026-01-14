const Point = @import("point.zig").Point;

/// Annotation textuelle
pub const TextAnnotation = struct {
    position: Point = .{ .x = 0, .y = 0 },
    angle: f64 = 0,
    text: []const u8 = "",
    height: f64 = 10.0, // Hauteur du texte
};
