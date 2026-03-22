const std = @import("std");
const types = @import("types.zig");
const testing = std.testing;

const LineQuality = types.LineQuality;
const NotchType = types.NotchType;
const AllowedRotation = types.AllowedRotation;
const Point = types.Point;
const Header = types.Header;
const Marker = types.Marker;
const Polyline = types.Polyline;
const Arc = types.Arc;
const Circle = types.Circle;
const Notch = types.Notch;
const DrillHole = types.DrillHole;
const TextAnnotation = types.TextAnnotation;
const GrainLine = types.GrainLine;
const SeamLine = types.SeamLine;
const Piece = types.Piece;
const Cmd = types.Cmd;
const visitCmd = types.visitCmd;

pub const ParseError = error{
    InvalidFormat,
    InvalidNumber,
    UnexpectedToken,
    OutOfMemory,
    InvalidCharacter,
    Overflow,
};

pub const Parser = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Parser {
        return .{ .allocator = allocator };
    }

    pub fn deinit(_: *Parser) void {}

    /// Parse ASTM D6673 input and dispatch to visitor methods.
    ///
    /// LIFETIME: string fields on Header, Marker, Piece, and TextAnnotation
    /// (id, name, material, comment, text, etc.) are slices into `input` — they
    /// are NOT heap-allocated copies. The caller must keep `input` alive for as
    /// long as those values are in use.
    pub fn parse(self: *Parser, input: []const u8, visitor: anytype) !void {
        var lines = std.mem.splitAny(u8, input, "\n\r");

        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t");
            if (trimmed.len == 0) continue;
            if (trimmed[0] == '#' or trimmed[0] == ';') continue;

            var it = std.mem.splitScalar(u8, trimmed, ',');
            const tag = std.mem.trim(u8, it.next() orelse continue, " ");

            const cmd = try self.parseRecord(tag, &it);
            if (cmd) |c| {
                try visitCmd(visitor, &c);
            }
        }
    }

    fn parseRecord(self: *Parser, tag: []const u8, it: *std.mem.SplitIterator(u8, .scalar)) ParseError!?Cmd {
        if (std.mem.eql(u8, tag, "H") or std.mem.eql(u8, tag, "HEADER")) {
            return .{ .Header = .{
                .std_name = self.nextField(it),
                .version = self.nextField(it),
                .units = self.nextField(it),
                .comment = self.nextField(it),
                .creation_date = self.nextField(it),
                .author = self.nextField(it),
            } };
        }

        if (std.mem.eql(u8, tag, "M") or std.mem.eql(u8, tag, "MARKER")) {
            return .{ .Marker = .{
                .id = self.nextField(it),
                .width = try self.parseFloat(it),
                .length = try self.parseFloat(it),
                .material = self.nextField(it),
                .efficiency = try self.parseFloatOrDefault(it, 0),
                .comment = self.nextField(it),
            } };
        }

        if (std.mem.eql(u8, tag, "P") or std.mem.eql(u8, tag, "PIECE")) {
            return .{ .Piece = .{
                .id = self.nextField(it),
                .qty = try self.parseIntOrDefault(u32, it, 1),
                .material = self.nextField(it),
                .origin = .{
                    .x = try self.parseFloatOrDefault(it, 0),
                    .y = try self.parseFloatOrDefault(it, 0),
                },
                .rotation = try self.parseFloatOrDefault(it, 0),
                .mirror = (try self.parseIntOrDefault(u8, it, 0)) != 0,
                .grain_angle = try self.parseFloatOrDefault(it, 0),
                .allowed_rotation = AllowedRotation.fromInt(try self.parseIntOrDefault(u8, it, 0)),
                .comment = self.nextField(it),
            } };
        }

        if (std.mem.eql(u8, tag, "PL") or std.mem.eql(u8, tag, "POLYLINE")) {
            const quality = LineQuality.fromInt(try self.parseIntOrDefault(u8, it, 0));
            var pts = std.ArrayListUnmanaged(Point){};
            errdefer pts.deinit(self.allocator);

            // Consume pairs until the field is empty or non-numeric. A
            // malformed coordinate silently truncates the polyline rather than
            // failing the whole parse — intentional for forward-compat with
            // ASTM files that have trailing commas or optional extra fields.
            while (it.next()) |val| {
                const x_str = std.mem.trim(u8, val, " ");
                if (x_str.len == 0) break;
                const x = std.fmt.parseFloat(f64, x_str) catch break;
                const y_str = std.mem.trim(u8, it.next() orelse break, " ");
                const y = std.fmt.parseFloat(f64, y_str) catch break;
                try pts.append(self.allocator, .{ .x = x, .y = y });
            }

            const points = try pts.toOwnedSlice(self.allocator);
            // Closed detection: ASTM convention is to repeat the first point
            // as the last. Exact equality is intentional — the parser produces
            // both from the same literal string, so there is no rounding drift.
            const closed = points.len > 2 and
                points[0].x == points[points.len - 1].x and
                points[0].y == points[points.len - 1].y;

            return .{ .Polyline = .{
                .points = points,
                .quality = quality,
                .closed = closed,
            } };
        }

        if (std.mem.eql(u8, tag, "A") or std.mem.eql(u8, tag, "ARC")) {
            return .{ .Arc = .{
                .start = .{
                    .x = try self.parseFloat(it),
                    .y = try self.parseFloat(it),
                },
                .mid = .{
                    .x = try self.parseFloat(it),
                    .y = try self.parseFloat(it),
                },
                .end_pt = .{
                    .x = try self.parseFloat(it),
                    .y = try self.parseFloat(it),
                },
                .quality = LineQuality.fromInt(try self.parseIntOrDefault(u8, it, 0)),
            } };
        }

        if (std.mem.eql(u8, tag, "C") or std.mem.eql(u8, tag, "CIRCLE")) {
            return .{ .Circle = .{
                .center = .{
                    .x = try self.parseFloat(it),
                    .y = try self.parseFloat(it),
                },
                .radius = try self.parseFloat(it),
                .quality = LineQuality.fromInt(try self.parseIntOrDefault(u8, it, 0)),
            } };
        }

        if (std.mem.eql(u8, tag, "N") or std.mem.eql(u8, tag, "NOTCH")) {
            return .{ .Notch = .{
                .position = .{
                    .x = try self.parseFloat(it),
                    .y = try self.parseFloat(it),
                },
                .angle = try self.parseFloatOrDefault(it, 0),
                .notch_type = NotchType.fromInt(try self.parseIntOrDefault(u8, it, 0)),
                .depth = try self.parseFloatOrDefault(it, 5.0),
                .width = try self.parseFloatOrDefault(it, 2.0),
            } };
        }

        if (std.mem.eql(u8, tag, "D") or std.mem.eql(u8, tag, "DRILL")) {
            return .{ .DrillHole = .{
                .position = .{
                    .x = try self.parseFloat(it),
                    .y = try self.parseFloat(it),
                },
                .diameter = try self.parseFloatOrDefault(it, 3.0),
            } };
        }

        if (std.mem.eql(u8, tag, "T") or std.mem.eql(u8, tag, "TEXT")) {
            return .{ .Text = .{
                .position = .{
                    .x = try self.parseFloat(it),
                    .y = try self.parseFloat(it),
                },
                .angle = try self.parseFloatOrDefault(it, 0),
                .height = try self.parseFloatOrDefault(it, 10.0),
                .text = self.nextField(it),
            } };
        }

        if (std.mem.eql(u8, tag, "G") or std.mem.eql(u8, tag, "GS") or std.mem.eql(u8, tag, "GRAIN")) {
            return .{ .GrainLine = .{
                .start = .{
                    .x = try self.parseFloat(it),
                    .y = try self.parseFloat(it),
                },
                .end_pt = .{
                    .x = try self.parseFloat(it),
                    .y = try self.parseFloat(it),
                },
            } };
        }

        if (std.mem.eql(u8, tag, "S") or std.mem.eql(u8, tag, "SEAM")) {
            const allowance = try self.parseFloatOrDefault(it, 0);
            const quality = LineQuality.fromInt(try self.parseIntOrDefault(u8, it, 3));

            var pts = std.ArrayListUnmanaged(Point){};
            errdefer pts.deinit(self.allocator);

            // Same silent-truncation policy as PL records (see above).
            while (it.next()) |val| {
                const x_str = std.mem.trim(u8, val, " ");
                if (x_str.len == 0) break;
                const x = std.fmt.parseFloat(f64, x_str) catch break;
                const y_str = std.mem.trim(u8, it.next() orelse break, " ");
                const y = std.fmt.parseFloat(f64, y_str) catch break;
                try pts.append(self.allocator, .{ .x = x, .y = y });
            }

            return .{ .SeamLine = .{
                .polyline = .{
                    .points = try pts.toOwnedSlice(self.allocator),
                    .quality = quality,
                },
                .allowance = allowance,
            } };
        }

        if (std.mem.eql(u8, tag, "E") or std.mem.eql(u8, tag, "EOF") or std.mem.eql(u8, tag, "END")) {
            return .End;
        }

        return null;
    }

    fn nextField(self: *Parser, it: *std.mem.SplitIterator(u8, .scalar)) []const u8 {
        _ = self;
        return std.mem.trim(u8, it.next() orelse "", " ");
    }

    fn parseFloat(self: *Parser, it: *std.mem.SplitIterator(u8, .scalar)) ParseError!f64 {
        _ = self;
        const str = std.mem.trim(u8, it.next() orelse return error.InvalidFormat, " ");
        return std.fmt.parseFloat(f64, str) catch return error.InvalidNumber;
    }

    fn parseFloatOrDefault(self: *Parser, it: *std.mem.SplitIterator(u8, .scalar), default: f64) ParseError!f64 {
        _ = self;
        const str = std.mem.trim(u8, it.next() orelse return default, " ");
        if (str.len == 0) return default;
        return std.fmt.parseFloat(f64, str) catch default;
    }

    fn parseIntOrDefault(self: *Parser, comptime T: type, it: *std.mem.SplitIterator(u8, .scalar), default: T) ParseError!T {
        _ = self;
        const str = std.mem.trim(u8, it.next() orelse return default, " ");
        if (str.len == 0) return default;
        return std.fmt.parseInt(T, str, 10) catch default;
    }
};

const TestVisitor = struct {
    headers: usize = 0,
    markers: usize = 0,
    pieces: usize = 0,
    polylines: usize = 0,
    arcs: usize = 0,
    circles: usize = 0,
    notches: usize = 0,
    drills: usize = 0,
    texts: usize = 0,
    grains: usize = 0,
    seams: usize = 0,
    ended: bool = false,

    last_header: ?Header = null,
    last_marker: ?Marker = null,
    last_piece: ?Piece = null,
    last_polyline: ?Polyline = null,

    pub fn visitHeader(self: *TestVisitor, h: *const Header) !void {
        self.headers += 1;
        self.last_header = h.*;
    }
    pub fn visitMarker(self: *TestVisitor, m: *const Marker) !void {
        self.markers += 1;
        self.last_marker = m.*;
    }
    pub fn visitPiece(self: *TestVisitor, p: *const Piece) !void {
        self.pieces += 1;
        self.last_piece = p.*;
    }
    pub fn visitPolyline(self: *TestVisitor, pl: *const Polyline) !void {
        self.polylines += 1;
        self.last_polyline = pl.*;
    }
    pub fn visitArc(self: *TestVisitor, _: *const Arc) !void {
        self.arcs += 1;
    }
    pub fn visitCircle(self: *TestVisitor, _: *const Circle) !void {
        self.circles += 1;
    }
    pub fn visitNotch(self: *TestVisitor, _: *const Notch) !void {
        self.notches += 1;
    }
    pub fn visitDrillHole(self: *TestVisitor, _: *const DrillHole) !void {
        self.drills += 1;
    }
    pub fn visitText(self: *TestVisitor, _: *const TextAnnotation) !void {
        self.texts += 1;
    }
    pub fn visitGrainLine(self: *TestVisitor, _: *const GrainLine) !void {
        self.grains += 1;
    }
    pub fn visitSeamLine(self: *TestVisitor, _: *const SeamLine) !void {
        self.seams += 1;
    }
    pub fn visitEnd(self: *TestVisitor) !void {
        self.ended = true;
    }
};

test "parse header" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("H,ASTM-D6673,1.0,MM,Test comment,2026-01-14,Author", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.headers);
    try testing.expectEqualStrings("ASTM-D6673", visitor.last_header.?.std_name);
    try testing.expectEqualStrings("1.0", visitor.last_header.?.version);
    try testing.expectEqualStrings("MM", visitor.last_header.?.units);
    try testing.expectEqualStrings("Test comment", visitor.last_header.?.comment);
}

test "parse marker" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("M,MARKER001,1500,3000,Cotton,85.5,Comment", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.markers);
    try testing.expectEqualStrings("MARKER001", visitor.last_marker.?.id);
    try testing.expectApproxEqAbs(@as(f64, 1500.0), visitor.last_marker.?.width, 0.01);
    try testing.expectApproxEqAbs(@as(f64, 3000.0), visitor.last_marker.?.length, 0.01);
    try testing.expectApproxEqAbs(@as(f64, 85.5), visitor.last_marker.?.efficiency, 0.01);
}

test "parse piece" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("P,FRONT-001,2,Cotton,100,200,45,1,90,2,Comment", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.pieces);
    try testing.expectEqualStrings("FRONT-001", visitor.last_piece.?.id);
    try testing.expectEqual(@as(u32, 2), visitor.last_piece.?.qty);
    try testing.expectApproxEqAbs(@as(f64, 100.0), visitor.last_piece.?.origin.x, 0.01);
    try testing.expectApproxEqAbs(@as(f64, 200.0), visitor.last_piece.?.origin.y, 0.01);
    try testing.expectApproxEqAbs(@as(f64, 45.0), visitor.last_piece.?.rotation, 0.01);
    try testing.expect(visitor.last_piece.?.mirror);
}

test "parse polyline" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("PL,0,0,0,100,0,100,100,0,100,0,0", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.polylines);
}

test "parse arc" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("A,0,0,50,50,100,0,0", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.arcs);
}

test "parse circle" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("C,100,100,50,1", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.circles);
}

test "parse notch" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("N,50,0,270,1,8,3", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.notches);
}

test "parse drill hole" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("D,100,150,4", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.drills);
}

test "parse text annotation" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("T,100,150,0,12,FRONT", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.texts);
}

test "parse grain line" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("G,100,50,100,250", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.grains);
}

test "parse seam line" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("S,10,3,0,0,100,0,100,100,0,100,0,0", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.seams);
}

test "parse end of file" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("EOF", &visitor);

    try testing.expect(visitor.ended);
}

test "skip comments" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("# This is a comment\n; Another comment\nH,ASTM,1.0,MM,Test,2026,Auth", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.headers);
}

test "skip empty lines" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("\n\nH,ASTM,1.0,MM,Test,2026,Auth\n\n", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.headers);
}

test "parse complete document" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    const content =
        \\H,ASTM-D6673,1.0,MM,Test,2026-01-14,Author
        \\M,MARKER001,1500,3000,Cotton,85.5,Marker
        \\P,FRONT-001,2,Cotton,0,0,0,0,90,0,Piece
        \\PL,0,0,0,100,0,100,100,0,100,0,0
        \\A,200,200,225,150,200,100,0
        \\C,125,175,25,1
        \\N,50,0,270,0,8,3
        \\D,100,150,4
        \\G,100,50,100,250
        \\T,100,150,0,12,FRONT
        \\S,10,3,0,0,100,0
        \\EOF
    ;

    try parser.parse(content, &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.headers);
    try testing.expectEqual(@as(usize, 1), visitor.markers);
    try testing.expectEqual(@as(usize, 1), visitor.pieces);
    try testing.expectEqual(@as(usize, 1), visitor.polylines);
    try testing.expectEqual(@as(usize, 1), visitor.arcs);
    try testing.expectEqual(@as(usize, 1), visitor.circles);
    try testing.expectEqual(@as(usize, 1), visitor.notches);
    try testing.expectEqual(@as(usize, 1), visitor.drills);
    try testing.expectEqual(@as(usize, 1), visitor.grains);
    try testing.expectEqual(@as(usize, 1), visitor.texts);
    try testing.expectEqual(@as(usize, 1), visitor.seams);
    try testing.expect(visitor.ended);
}

test "parse long form tags" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("HEADER,ASTM,1.0,MM,Test,2026,Auth\nMARKER,M1,100,200,Mat,50,C", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.headers);
    try testing.expectEqual(@as(usize, 1), visitor.markers);
}

test "polyline is closed when first and last points match" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    // quality=0, then 5 pairs: (0,0),(100,0),(100,100),(0,100),(0,0) — last repeats first
    try parser.parse("PL,0,0,0,100,0,100,100,0,100,0,0", &visitor);

    const pl = visitor.last_polyline.?;
    try testing.expect(pl.closed);
    try testing.expectEqual(@as(usize, 5), pl.points.len);
    try testing.expectApproxEqAbs(@as(f64, 0), pl.points[0].x, 0.001);
    try testing.expectApproxEqAbs(@as(f64, 0), pl.points[0].y, 0.001);
    try testing.expectApproxEqAbs(@as(f64, 100), pl.points[1].x, 0.001);
    try testing.expectApproxEqAbs(@as(f64, 0), pl.points[1].y, 0.001);
}

test "polyline is open when last point differs" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("PL,0,0,0,100,0,100,100,0,100", &visitor);

    try testing.expect(!visitor.last_polyline.?.closed);
    try testing.expectEqual(@as(usize, 4), visitor.last_polyline.?.points.len);
}

test "piece grain angle and allowed rotation are parsed" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    // grain_angle=90, allowed_rotation=1 (rot_180)
    try parser.parse("P,BACK-001,2,Denim,0,0,0,0,90,1,Back panel", &visitor);

    const p = visitor.last_piece.?;
    try testing.expectApproxEqAbs(@as(f64, 90), p.grain_angle, 0.001);
    try testing.expectEqual(AllowedRotation.rot_180, p.allowed_rotation);
}

test "multiple pieces each trigger visitPiece" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    const input =
        \\P,FRONT,1,Mat,0,0,0,0,0,0,
        \\PL,0,0,0,50,0,50,50,0,50,0,0
        \\P,BACK,1,Mat,0,0,0,0,0,0,
        \\PL,0,0,0,60,0,60,60,0,60,0,0
        \\EOF
    ;
    try parser.parse(input, &visitor);

    try testing.expectEqual(@as(usize, 2), visitor.pieces);
    try testing.expectEqual(@as(usize, 2), visitor.polylines);
    try testing.expectEqualStrings("BACK", visitor.last_piece.?.id);
}

test "unknown tag is silently skipped" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    try parser.parse("H,ASTM,1.0,MM,Test,2026,Auth\nXXXUNKNOWN,foo,bar\nEOF", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.headers);
    try testing.expect(visitor.ended);
}

test "malformed coordinate truncates polyline without error" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    // Two valid pairs, then a non-numeric value — should yield 2 points, no error
    try parser.parse("PL,0,0,0,100,0,BADVAL,200", &visitor);

    try testing.expectEqual(@as(usize, 1), visitor.polylines);
    try testing.expectEqual(@as(usize, 2), visitor.last_polyline.?.points.len);
}

test "invalid number on required field returns error" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());
    var visitor = TestVisitor{};

    // M record: width is required — passing a non-numeric string must error
    try testing.expectError(error.InvalidNumber, parser.parse("M,ID,notanumber,3000,Mat,0,", &visitor));
}
