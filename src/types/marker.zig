/// Informations de marqueur (Marker)
pub const Marker = struct {
    id: []const u8 = "",
    width: f64 = 0,
    length: f64 = 0,
    material: []const u8 = "",
    efficiency: f64 = 0, // Pourcentage d'utilisation matière
    comment: []const u8 = "",
};
