const Polyline = @import("polyline.zig").Polyline;

/// Ligne de valeur de couture (seam allowance)
pub const SeamLine = struct {
    polyline: Polyline = .{},
    allowance: f64 = 0, // Valeur de couture
};
