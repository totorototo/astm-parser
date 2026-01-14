/// Qualificateur de ligne selon ASTM D6673
pub const LineQuality = enum(u8) {
    cut = 0, // Contour de coupe
    internal = 1, // Ligne interne
    grain = 2, // Ligne de grain
    seam = 3, // Ligne de couture (seam allowance)
    annotation = 4, // Ligne d'annotation
    mirror = 5, // Ligne de symétrie
    match = 6, // Ligne de raccord
    stripe = 7, // Ligne de rayure/motif

    pub fn fromInt(val: u8) LineQuality {
        return @enumFromInt(@min(val, 7));
    }
};
