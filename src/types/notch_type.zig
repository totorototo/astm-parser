/// Type de cran (notch)
pub const NotchType = enum(u8) {
    v_notch = 0, // Cran en V
    i_notch = 1, // Cran droit (I)
    t_notch = 2, // Cran en T
    castle = 3, // Cran crénelé
    hole = 4, // Petit trou

    pub fn fromInt(val: u8) NotchType {
        return @enumFromInt(@min(val, 4));
    }
};
