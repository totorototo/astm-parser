const Header = @import("header.zig").Header;
const Marker = @import("marker.zig").Marker;
const Piece = @import("piece.zig").Piece;
const Polyline = @import("polyline.zig").Polyline;
const Arc = @import("arc.zig").Arc;
const Circle = @import("circle.zig").Circle;
const Notch = @import("notch.zig").Notch;
const DrillHole = @import("drill_hole.zig").DrillHole;
const TextAnnotation = @import("text_annotation.zig").TextAnnotation;
const GrainLine = @import("grain_line.zig").GrainLine;
const SeamLine = @import("seam_line.zig").SeamLine;

/// Types de commandes pour le visiteur
pub const CmdKind = enum {
    Header,
    Marker,
    Piece,
    Polyline,
    Arc,
    Circle,
    Notch,
    DrillHole,
    Text,
    GrainLine,
    SeamLine,
    End,
};

pub const Cmd = union(CmdKind) {
    Header: Header,
    Marker: Marker,
    Piece: Piece,
    Polyline: Polyline,
    Arc: Arc,
    Circle: Circle,
    Notch: Notch,
    DrillHole: DrillHole,
    Text: TextAnnotation,
    GrainLine: GrainLine,
    SeamLine: SeamLine,
    End: void,
};

/// Dispatcher (Pattern Visiteur)
pub fn visitCmd(v: anytype, c: *const Cmd) !void {
    switch (c.*) {
        .Header => |*h| try v.visitHeader(h),
        .Marker => |*m| try v.visitMarker(m),
        .Piece => |*p| try v.visitPiece(p),
        .Polyline => |*pl| try v.visitPolyline(pl),
        .Arc => |*ar| try v.visitArc(ar),
        .Circle => |*ci| try v.visitCircle(ci),
        .Notch => |*n| try v.visitNotch(n),
        .DrillHole => |*d| try v.visitDrillHole(d),
        .Text => |*t| try v.visitText(t),
        .GrainLine => |*g| try v.visitGrainLine(g),
        .SeamLine => |*s| try v.visitSeamLine(s),
        .End => try v.visitEnd(),
    }
}
