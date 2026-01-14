const Header = @import("header.zig").Header;
const Marker = @import("marker.zig").Marker;
const Piece = @import("piece.zig").Piece;

/// Document ASTM D6673 complet
pub const AstmDocument = struct {
    header: Header = .{},
    marker: ?Marker = null,
    pieces: []Piece = &[_]Piece{},
};
