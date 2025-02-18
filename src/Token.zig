const std = @import("std");

// Internal Dependencies
const TokenState = @import("states.zig").TokenState;

// Token Obj
const Token = @This();

id: u64,
match_reverse: bool = false,
str: [*:0]const u8,
len: u32,
exact: bool = false,
follow_token_idx: ?u64 = null,
is_fragment: bool = false,

pub fn add_follow(self: *Token, follower: Token) void {
    self.follow_token_idx = follower.id;
    return;
}
pub fn fragment(self: *Token) void {
    self.is_fragment = true;
    return;
}
pub fn test_sate(self: Token, buffer: []const u8, peek_byte: u8, is_escaped: bool) TokenState {
    if (self.exact) {
        // exact matches can never include escaped chars
        if (is_escaped) {
            return TokenState.Invalid;
        }

        if (self.len >= buffer.len and std.mem.eql(u8, self.str[0..buffer.len], buffer)) {
            if (self.len == buffer.len) {
                return TokenState.Match;
            }
            return TokenState.Possible;
        }
        return TokenState.Invalid;
    } else {
        var buf_check_len = buffer.len;
        if (is_escaped) {
            buf_check_len -= 1;
        }

        var matches: bool = false;
        outer: for (buffer[0..buf_check_len]) |buf_char| {
            for (self.str[0..self.len]) |check_char| {
                if (buf_char == check_char) {
                    matches = true;
                    continue :outer;
                }
            }
            matches = false;
        }

        if ((self.match_reverse and matches) or (!self.match_reverse and !matches)) {
            return TokenState.Invalid;
        }

        const peek_matches = (std.mem.indexOfScalarPos(u8, self.str[0..self.len], 0, peek_byte)) != null;
        if ((self.match_reverse and !matches and peek_matches) or (!self.match_reverse and matches and !peek_matches)) {
            return TokenState.Match;
        }
        if ((self.match_reverse and !matches and !peek_matches) or (!self.match_reverse and matches and peek_matches)) {
            return TokenState.Possible;
        } else {
            return TokenState.Invalid;
        }
    }
}
