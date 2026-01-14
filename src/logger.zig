const std = @import("std");
const types = @import("types.zig");
const testing = std.testing;

const Header = types.Header;
const Marker = types.Marker;
const Piece = types.Piece;
const Polyline = types.Polyline;
const Arc = types.Arc;
const Circle = types.Circle;
const Notch = types.Notch;
const DrillHole = types.DrillHole;
const TextAnnotation = types.TextAnnotation;
const GrainLine = types.GrainLine;
const SeamLine = types.SeamLine;

pub const AstmLogger = struct {
    indent: usize = 0,

    fn printIndent(self: *AstmLogger) void {
        var i: usize = 0;
        while (i < self.indent) : (i += 1) {
            std.debug.print("    ", .{});
        }
    }

    pub fn visitHeader(_: *AstmLogger, h: *const Header) !void {
        std.debug.print("ASTM D6673 Document\n", .{});
        std.debug.print("  Standard: {s}  Version: {s}  Units: {s}\n", .{ h.std_name, h.version, h.units });
        if (h.comment.len > 0) {
            std.debug.print("  Comment: {s}\n", .{h.comment});
        }
        std.debug.print("\n", .{});
    }

    pub fn visitMarker(_: *AstmLogger, m: *const Marker) !void {
        std.debug.print("MARKER: {s}\n", .{m.id});
        std.debug.print("  Size: {d:.2} x {d:.2}  Material: {s}  Efficiency: {d:.1}%\n\n", .{ m.width, m.length, m.material, m.efficiency });
    }

    pub fn visitPiece(self: *AstmLogger, p: *const Piece) !void {
        std.debug.print("PIECE: {s} (qty: {d})\n", .{ p.id, p.qty });
        std.debug.print("  Material: {s}\n", .{p.material});
        std.debug.print("  Origin: ({d:.2}, {d:.2})  Rotation: {d:.1}", .{ p.origin.x, p.origin.y, p.rotation });
        if (p.mirror) std.debug.print(" [MIRRORED]", .{});
        std.debug.print("\n", .{});
        std.debug.print("  Grain angle: {d:.1}  Allowed rotation: {s}\n", .{ p.grain_angle, @tagName(p.allowed_rotation) });
        self.indent = 1;
    }

    pub fn visitPolyline(self: *AstmLogger, pl: *const Polyline) !void {
        self.printIndent();
        std.debug.print("POLYLINE [{s}]: {d} points", .{ @tagName(pl.quality), pl.points.len });
        if (pl.closed) std.debug.print(" (closed)", .{});
        std.debug.print("\n", .{});
    }

    pub fn visitArc(self: *AstmLogger, ar: *const Arc) !void {
        self.printIndent();
        std.debug.print("ARC [{s}]: ({d:.2},{d:.2}) -> ({d:.2},{d:.2}) -> ({d:.2},{d:.2})\n", .{
            @tagName(ar.quality),
            ar.start.x,
            ar.start.y,
            ar.mid.x,
            ar.mid.y,
            ar.end_pt.x,
            ar.end_pt.y,
        });
    }

    pub fn visitCircle(self: *AstmLogger, ci: *const Circle) !void {
        self.printIndent();
        std.debug.print("CIRCLE [{s}]: center=({d:.2},{d:.2}) r={d:.2}\n", .{
            @tagName(ci.quality),
            ci.center.x,
            ci.center.y,
            ci.radius,
        });
    }

    pub fn visitNotch(self: *AstmLogger, n: *const Notch) !void {
        self.printIndent();
        std.debug.print("NOTCH [{s}]: ({d:.2},{d:.2}) angle={d:.1} depth={d:.2}\n", .{
            @tagName(n.notch_type),
            n.position.x,
            n.position.y,
            n.angle,
            n.depth,
        });
    }

    pub fn visitDrillHole(self: *AstmLogger, d: *const DrillHole) !void {
        self.printIndent();
        std.debug.print("DRILL: ({d:.2},{d:.2}) d={d:.2}\n", .{ d.position.x, d.position.y, d.diameter });
    }

    pub fn visitText(self: *AstmLogger, t: *const TextAnnotation) !void {
        self.printIndent();
        std.debug.print("TEXT: \"{s}\" at ({d:.2},{d:.2}) h={d:.1}\n", .{ t.text, t.position.x, t.position.y, t.height });
    }

    pub fn visitGrainLine(self: *AstmLogger, g: *const GrainLine) !void {
        self.printIndent();
        std.debug.print("GRAIN LINE: ({d:.2},{d:.2}) -> ({d:.2},{d:.2})\n", .{ g.start.x, g.start.y, g.end_pt.x, g.end_pt.y });
    }

    pub fn visitSeamLine(self: *AstmLogger, s: *const SeamLine) !void {
        self.printIndent();
        std.debug.print("SEAM LINE: allowance={d:.2} points={d}\n", .{ s.allowance, s.polyline.points.len });
    }

    pub fn visitEnd(self: *AstmLogger) !void {
        self.indent = 0;
        std.debug.print("\n--- END ---\n", .{});
    }
};

test "AstmLogger init" {
    const logger = AstmLogger{};
    try testing.expectEqual(@as(usize, 0), logger.indent);
}

test "AstmLogger indent increments on piece" {
    var logger = AstmLogger{};
    const piece = Piece{
        .id = "TEST",
        .qty = 1,
        .material = "Cotton",
        .origin = .{ .x = 0, .y = 0 },
        .rotation = 0,
        .mirror = false,
        .grain_angle = 90,
        .allowed_rotation = .none,
        .comment = "",
    };

    try logger.visitPiece(&piece);
    try testing.expectEqual(@as(usize, 1), logger.indent);
}

test "AstmLogger indent resets on end" {
    var logger = AstmLogger{};
    logger.indent = 3;

    try logger.visitEnd();
    try testing.expectEqual(@as(usize, 0), logger.indent);
}

test "AstmLogger visitHeader" {
    var logger = AstmLogger{};
    const header = Header{
        .std_name = "ASTM-D6673",
        .version = "1.0",
        .units = "MM",
        .comment = "Test",
        .creation_date = "2026-01-14",
        .author = "Author",
    };

    // Should not error
    try logger.visitHeader(&header);
}

test "AstmLogger visitMarker" {
    var logger = AstmLogger{};
    const marker = Marker{
        .id = "MARKER001",
        .width = 1500,
        .length = 3000,
        .material = "Cotton",
        .efficiency = 85.5,
        .comment = "Test",
    };

    try logger.visitMarker(&marker);
}

test "AstmLogger visitPolyline" {
    var logger = AstmLogger{};
    var points = [_]types.Point{
        .{ .x = 0, .y = 0 },
        .{ .x = 100, .y = 0 },
        .{ .x = 100, .y = 100 },
    };
    const polyline = Polyline{
        .points = points[0..],
        .quality = .cut,
        .closed = false,
    };

    try logger.visitPolyline(&polyline);
}

test "AstmLogger visitArc" {
    var logger = AstmLogger{};
    const arc = Arc{
        .start = .{ .x = 0, .y = 0 },
        .mid = .{ .x = 50, .y = 50 },
        .end_pt = .{ .x = 100, .y = 0 },
        .quality = .cut,
    };

    try logger.visitArc(&arc);
}

test "AstmLogger visitCircle" {
    var logger = AstmLogger{};
    const circle = Circle{
        .center = .{ .x = 100, .y = 100 },
        .radius = 50,
        .quality = .internal,
    };

    try logger.visitCircle(&circle);
}

test "AstmLogger visitNotch" {
    var logger = AstmLogger{};
    const notch = Notch{
        .position = .{ .x = 50, .y = 0 },
        .angle = 270,
        .notch_type = .v_notch,
        .depth = 8,
        .width = 3,
    };

    try logger.visitNotch(&notch);
}

test "AstmLogger visitDrillHole" {
    var logger = AstmLogger{};
    const drill = DrillHole{
        .position = .{ .x = 100, .y = 150 },
        .diameter = 4,
    };

    try logger.visitDrillHole(&drill);
}

test "AstmLogger visitText" {
    var logger = AstmLogger{};
    const text = TextAnnotation{
        .position = .{ .x = 100, .y = 150 },
        .angle = 0,
        .height = 12,
        .text = "FRONT",
    };

    try logger.visitText(&text);
}

test "AstmLogger visitGrainLine" {
    var logger = AstmLogger{};
    const grain = GrainLine{
        .start = .{ .x = 100, .y = 50 },
        .end_pt = .{ .x = 100, .y = 250 },
    };

    try logger.visitGrainLine(&grain);
}

test "AstmLogger visitSeamLine" {
    var logger = AstmLogger{};
    var points = [_]types.Point{
        .{ .x = 0, .y = 0 },
        .{ .x = 100, .y = 0 },
    };
    const seam = SeamLine{
        .polyline = .{
            .points = points[0..],
            .quality = .seam,
            .closed = false,
        },
        .allowance = 10,
    };

    try logger.visitSeamLine(&seam);
}
