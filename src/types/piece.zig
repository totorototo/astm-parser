const Point = @import("point.zig").Point;
const Polyline = @import("polyline.zig").Polyline;
const Arc = @import("arc.zig").Arc;
const Circle = @import("circle.zig").Circle;
const Notch = @import("notch.zig").Notch;
const DrillHole = @import("drill_hole.zig").DrillHole;
const TextAnnotation = @import("text_annotation.zig").TextAnnotation;
const GrainLine = @import("grain_line.zig").GrainLine;
const SeamLine = @import("seam_line.zig").SeamLine;
const AllowedRotation = @import("allowed_rotation.zig").AllowedRotation;

/// Pièce complète avec toutes ses géométries
pub const Piece = struct {
    // Identifiants
    id: []const u8 = "",
    name: []const u8 = "",
    qty: u32 = 1,
    material: []const u8 = "",
    category: []const u8 = "",

    // Position et orientation
    origin: Point = .{ .x = 0, .y = 0 },
    rotation: f64 = 0,
    mirror: bool = false,
    allowed_rotation: AllowedRotation = .none,
    grain_angle: f64 = 0,

    // Bounding box
    bbox_min: Point = .{ .x = 0, .y = 0 },
    bbox_max: Point = .{ .x = 0, .y = 0 },

    // Géométries associées
    polylines: []Polyline = &[_]Polyline{},
    arcs: []Arc = &[_]Arc{},
    circles: []Circle = &[_]Circle{},
    notches: []Notch = &[_]Notch{},
    drill_holes: []DrillHole = &[_]DrillHole{},
    annotations: []TextAnnotation = &[_]TextAnnotation{},
    grain_line: ?GrainLine = null,
    seam_lines: []SeamLine = &[_]SeamLine{},

    comment: []const u8 = "",
};
