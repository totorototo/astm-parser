# ASTM D6673 Parser

A Zig library for parsing ASTM D6673 pattern files.

## Installation

Add to your `build.zig.zon`:

```zig
.dependencies = .{
    .astm_parser = .{
        .url = "https://github.com/your-repo/astm-parser/archive/main.tar.gz",
        .hash = "...",
    },
},
```

Then in `build.zig`:

```zig
const astm = b.dependency("astm_parser", .{});
exe.root_module.addImport("astm_parser", astm.module("astm_parser"));
```

## Usage

```zig
const astm = @import("astm_parser");

var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();

var parser = astm.Parser.init(arena.allocator());
try parser.parse(content, &my_visitor);
```

## Visitor Pattern

Implement a visitor struct with these methods:

```zig
const MyVisitor = struct {
    pub fn visitHeader(self: *@This(), h: *const astm.Header) !void { }
    pub fn visitMarker(self: *@This(), m: *const astm.Marker) !void { }
    pub fn visitPiece(self: *@This(), p: *const astm.Piece) !void { }
    pub fn visitPolyline(self: *@This(), pl: *const astm.Polyline) !void { }
    pub fn visitArc(self: *@This(), a: *const astm.Arc) !void { }
    pub fn visitCircle(self: *@This(), c: *const astm.Circle) !void { }
    pub fn visitNotch(self: *@This(), n: *const astm.Notch) !void { }
    pub fn visitDrillHole(self: *@This(), d: *const astm.DrillHole) !void { }
    pub fn visitText(self: *@This(), t: *const astm.TextAnnotation) !void { }
    pub fn visitGrainLine(self: *@This(), g: *const astm.GrainLine) !void { }
    pub fn visitSeamLine(self: *@This(), s: *const astm.SeamLine) !void { }
    pub fn visitEnd(self: *@This()) !void { }
};
```

## Tests

```bash
zig build test
```

## License

MIT
