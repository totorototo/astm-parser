const std = @import("std");

pub const Parser = @import("parser.zig").Parser;
pub const ParseError = @import("parser.zig").ParseError;

pub const AstmLogger = @import("logger.zig").AstmLogger;

const types = @import("types.zig");

pub const LineQuality = types.LineQuality;
pub const NotchType = types.NotchType;
pub const AllowedRotation = types.AllowedRotation;

pub const Point = types.Point;

pub const Header = types.Header;
pub const Marker = types.Marker;
pub const Piece = types.Piece;
pub const Polyline = types.Polyline;
pub const Arc = types.Arc;
pub const Circle = types.Circle;
pub const Notch = types.Notch;
pub const DrillHole = types.DrillHole;
pub const TextAnnotation = types.TextAnnotation;
pub const GrainLine = types.GrainLine;
pub const SeamLine = types.SeamLine;
pub const AstmDocument = types.AstmDocument;

pub const Cmd = types.Cmd;
pub const CmdKind = types.CmdKind;
pub const visitCmd = types.visitCmd;

comptime {
    _ = @import("parser.zig");
    _ = @import("logger.zig");
    _ = @import("types.zig");
}

test "parse simple document" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    var parser = Parser.init(arena.allocator());

    const CountVisitor = struct {
        count: usize = 0,
        pub fn visitHeader(self: *@This(), _: *const Header) !void {
            self.count += 1;
        }
        pub fn visitMarker(self: *@This(), _: *const Marker) !void {
            self.count += 1;
        }
        pub fn visitPiece(self: *@This(), _: *const Piece) !void {
            self.count += 1;
        }
        pub fn visitPolyline(self: *@This(), _: *const Polyline) !void {
            self.count += 1;
        }
        pub fn visitArc(self: *@This(), _: *const Arc) !void {
            self.count += 1;
        }
        pub fn visitCircle(self: *@This(), _: *const Circle) !void {
            self.count += 1;
        }
        pub fn visitNotch(self: *@This(), _: *const Notch) !void {
            self.count += 1;
        }
        pub fn visitDrillHole(self: *@This(), _: *const DrillHole) !void {
            self.count += 1;
        }
        pub fn visitText(self: *@This(), _: *const TextAnnotation) !void {
            self.count += 1;
        }
        pub fn visitGrainLine(self: *@This(), _: *const GrainLine) !void {
            self.count += 1;
        }
        pub fn visitSeamLine(self: *@This(), _: *const SeamLine) !void {
            self.count += 1;
        }
        pub fn visitEnd(self: *@This()) !void {
            self.count += 1;
        }
    };

    var visitor = CountVisitor{};
    try parser.parse("H,ASTM,1.0,MM,Test,2026,Auth\nEOF", &visitor);

    try std.testing.expectEqual(@as(usize, 2), visitor.count);
}
