const std = @import("std");
const net = std.net;
const mem = std.mem;
const fmt = std.fmt;
const json = std.json;

const PORT: u16 = 9002;

const SlotRecord = struct {
    room_id:     []const u8,
    start_epoch: i64,
    end_epoch:   i64,
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

fn buildResponse(status: u16, body: []const u8, out: *std.ArrayList(u8)) !void {
    const status_line: []const u8 = if (status == 200)
        "HTTP/1.1 200 OK\r\n"
    else
        "HTTP/1.1 400 Bad Request\r\n";

    try out.appendSlice(status_line);
    try out.appendSlice("Content-Type: application/json\r\n");
    try out.appendSlice("Access-Control-Allow-Origin: *\r\n");

    var length_buf: [32]u8 = undefined;
    const length_str = try fmt.bufPrint(&length_buf, "Content-Length: {d}\r\n\r\n", .{body.len});
    try out.appendSlice(length_str);
    try out.appendSlice(body);
}

fn handleConnection(conn: net.Server.Connection) void {
    defer conn.stream.close();

    var buf: [8192]u8 = undefined;
    const n = conn.stream.read(&buf) catch return;
    const request = buf[0..n];

    var response = std.ArrayList(u8).init(allocator);
    defer response.deinit();

    if (mem.indexOf(u8, request, "GET /health") != null) {
        buildResponse(200, "{\"status\":\"ok\",\"service\":\"sys_zig\"}", &response) catch return;
        _ = conn.stream.write(response.items) catch {};
        return;
    }

    if (mem.indexOf(u8, request, "GET /metrics") != null) {
        const body =
            \\{"service":"sys_zig","uptime_seconds":0,"requests_handled":1,"platform":"zig-0.13"}
        ;
        buildResponse(200, body, &response) catch return;
        _ = conn.stream.write(response.items) catch {};
        return;
    }

    if (mem.indexOf(u8, request, "POST /validate") != null) {
        const body_start = mem.indexOf(u8, request, "\r\n\r\n") orelse {
            buildResponse(400, "{\"error\":\"no body\"}", &response) catch return;
            _ = conn.stream.write(response.items) catch {};
            return;
        };

        const body = request[body_start + 4 ..];

        var start_ok = mem.indexOf(u8, body, "\"start_time\"") != null;
        var end_ok   = mem.indexOf(u8, body, "\"end_time\"")   != null;
        var room_ok  = mem.indexOf(u8, body, "\"room_id\"")    != null;

        const valid = start_ok and end_ok and room_ok;
        const resp_body: []const u8 = if (valid)
            "{\"valid\":true,\"validator\":\"zig\"}"
        else
            "{\"valid\":false,\"reason\":\"missing required fields\"}";

        buildResponse(if (valid) 200 else 400, resp_body, &response) catch return;
        _ = conn.stream.write(response.items) catch {};
        return;
    }

    buildResponse(200, "{\"error\":\"unknown route\"}", &response) catch return;
    _ = conn.stream.write(response.items) catch {};
}

pub fn main() !void {
    const addr = net.Address.initIp4(.{ 0, 0, 0, 0 }, PORT);
    var server = try addr.listen(.{ .reuse_address = true });
    defer server.deinit();

    std.debug.print("sys_zig service listening on :{d}\n", .{PORT});

    while (true) {
        const conn = server.accept() catch continue;
        const thread = std.Thread.spawn(.{}, handleConnection, .{conn}) catch {
            conn.stream.close();
            continue;
        };
        thread.detach();
    }
}
