const std = @import("std");

// Internal Dependencies
const Token = @import("Token.zig");
const TokenInstance = @import("TokenInstance.zig");
const states = @import("states.zig");

// Tokenizer Obj
const Tokenizer = @This();

file: std.fs.File,
tokens: []const Token,
required_next_token_id: ?u64 = null,
escape_byte: u8 = 0x5c,

pub fn init(file_name: [*:0]const u8) !Tokenizer {
    const file = try std.fs.cwd().openFile(
        std.mem.span(file_name),
        .{ .mode = .read_only },
    );

    const res: Tokenizer = .{
        .file = file,
        .tokens = &[_]Token{},
    };
    return res;
}

pub fn deinit(self: Tokenizer) void {
    self.file.close();
}

pub fn scan(self: *Tokenizer, allocator: std.mem.Allocator) !TokenInstance {
    var max_length: u32 = 0;
    for (self.tokens) |token| {
        if (token.len > max_length) {
            max_length = token.len;
        }
    }

    const reader = self.file.reader();

    var has_possible_token: bool = true;
    var c: u32 = 0;
    var read_byte: u8 = 0;
    var peek_byte: u8 = 0;

    var buf = try std.ArrayList(u8).initCapacity(allocator, max_length);
    defer buf.deinit();

    var escaped_positions = std.ArrayList(u32).init(allocator);
    defer escaped_positions.deinit();

    //TODO(msp): make ArrayList of possible inexact matches and try to make exact matches if possible

    while (has_possible_token) {
        // read a bit ( up to 4 later for full utf-8 compat )
        read_byte = try reader.readByte();

        // left trim whitespaces
        if (c == 0 and (read_byte == 0x20 or read_byte == 0x0A))
            continue;

        // TODO(msp): This does only work if the escaped char is the last in the sequence. So thats bad.
        // discard escape byte and set flag to ignore next byte in match check
        if (read_byte == self.escape_byte) {
            read_byte = try reader.readByte();
            try escaped_positions.append(c);
        }

        try buf.append(read_byte);
        c += 1;

        if (buf.items[c - 1] > 0xC1) {
            read_byte = try reader.readByte();
            try buf.append(read_byte);
            c += 1;
        }

        // peek-a-byte
        peek_byte = try reader.readByte();
        try self.file.seekBy(-1);

        const check_slice = buf.allocatedSlice()[0..c];
        if (self.required_next_token_id) |token_id| {
            const token_or_null = self.get_token_by_id(token_id);
            if (token_or_null) |token| {
                const state = token.test_sate(check_slice, peek_byte, escaped_positions.items);
                if (state == .Match) {
                    if (token.follow_token_idx) |next_token_id| {
                        self.required_next_token_id = next_token_id;
                    } else {
                        self.required_next_token_id = null;
                    }
                    return make_token_content(&token, try buf.toOwnedSlice());
                }
                if (state == .Invalid) {
                    std.log.warn("invalid on buffer {any}", .{buf.items[0..c]});
                    return error.InvalidToken;
                }
                has_possible_token = true;
            } else {
                std.log.warn("missing token id: {d}", .{token_id});
                return error.MissingFollowToken;
            }
        } else {
            has_possible_token = false;
            for (self.tokens) |token| {
                if (token.is_fragment)
                    continue;

                const state = token.test_sate(check_slice, peek_byte, escaped_positions.items);
                if (state == .Match) {
                    if (token.follow_token_idx) |next_token_id| {
                        self.required_next_token_id = next_token_id;
                    } else {
                        self.required_next_token_id = null;
                    }
                    return make_token_content(&token, try buf.toOwnedSlice());
                }

                has_possible_token = has_possible_token or state == .Possible;
            }
        }
    }

    return error.InvalidToken;
}

fn get_token_by_id(self: *Tokenizer, id: u64) ?Token {
    for (self.tokens) |token| {
        if (token.id == id)
            return token;
    }
    return null;
}

fn make_token_content(base: *const Token, content: []const u8) TokenInstance {
    return TokenInstance{
        .token = base,
        .content = content,
    };
}
