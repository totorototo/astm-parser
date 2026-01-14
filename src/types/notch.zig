const Point = @import("point.zig").Point;
const NotchType = @import("notch_type.zig").NotchType;

/// Cran/Repère de coupe
pub const Notch = struct {
    position: Point = .{ .x = 0, .y = 0 },
    angle: f64 = 0, // Direction en degrés
    notch_type: NotchType = .v_notch,
    depth: f64 = 5.0, // Profondeur par défaut 5mm
    width: f64 = 2.0, // Largeur du cran
};
