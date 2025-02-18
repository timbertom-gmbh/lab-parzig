const parzig = @import("parzig_lib");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var tokenizer = try parzig.Tokenizer.init("example/csv_convert/script.parz");
    defer tokenizer.deinit();

    const ident_token = parzig.make_matcher("ABCDEFGHIJKLMNOPQRSTUVWXZYabcdefghijklmnopqrstuvwxyz_");

    // combined quoted string tokenizing ( e.g. "abc" )
    var str_start = parzig.make_exact("\"");
    var str_main_token = parzig.make_negative_matcher("\"");
    var str_end = parzig.make_exact("\"");
    str_end.fragment();
    str_main_token.fragment();
    str_main_token.add_follow(str_end);
    str_start.add_follow(str_main_token);

    tokenizer.tokens = &[_]parzig.Token{
        // keyword tokens
        parzig.make_exact("line"),  parzig.make_exact("every"),        parzig.make_exact("number"),
        parzig.make_exact("store"), parzig.make_exact("read"),         parzig.make_exact("until"),
        parzig.make_exact("write"), parzig.make_exact("insert"),       parzig.make_exact("true"),
        parzig.make_exact("false"),
        // synatx tokens
        parzig.make_exact("("),            parzig.make_exact(")"),
        parzig.make_exact("{"),     parzig.make_exact("}"),            parzig.make_exact("\n"),
        str_start,                  parzig.make_exact(":"),            parzig.make_exact("."),
        parzig.make_exact(","),
        // idents and stuff
            parzig.make_matcher("1234567890"), ident_token,
        str_start,                  str_main_token,                    str_end,
    };

    var has_token = true;
    while (has_token) {
        const instance = tokenizer.scan(allocator) catch |err| {
            if (err != error.EndOfStream)
                std.debug.print("Token scan error {any}\n", .{err});
            has_token = false;
            continue;
        };
        if (instance.token.exact) {
            std.debug.print("Found token: {s} negative={any}\n", .{ instance.token.str, instance.token.match_reverse });
        } else {
            std.debug.print("Found token: {s} negative={any} with content {s}\n", .{ instance.token.str, instance.token.match_reverse, instance.content });
        }
    }
}
