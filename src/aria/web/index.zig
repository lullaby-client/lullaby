const std = @import("std");
const httpz = @import("httpz");

pub fn index(_: *httpz.Request, res: *httpz.Response) !void {
    res.body =
        \\<!DOCTYPE html>
    ;
}
