/// Rotation autorisée pour une pièce
pub const AllowedRotation = enum(u8) {
    none = 0, // Pas de rotation
    rot_180 = 1, // 180° seulement
    rot_90 = 2, // 90° incréments
    free = 3, // Rotation libre

    pub fn fromInt(val: u8) AllowedRotation {
        return @enumFromInt(@min(val, 3));
    }
};
