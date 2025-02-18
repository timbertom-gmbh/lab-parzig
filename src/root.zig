const std = @import("std");
const testing = std.testing;

pub const Token = @import("Token.zig");
pub const Tokenizer = @import("Tokenizer.zig");

var current_token_index: u64 = 0;

pub fn make_exact(str: [*:0]const u8) Token {
    var strlen: u32 = 0;
    while (str[strlen] != 0) {
        strlen += 1;
    }

    const t = Token{
        .id = current_token_index,
        .str = str,
        .len = strlen,
        .exact = true,
    };
    current_token_index += 1;
    return t;
}

pub fn make_matcher(str: [*:0]const u8) Token {
    var strlen: u32 = 0;
    while (str[strlen] != 0) {
        strlen += 1;
    }

    const t = Token{
        .id = current_token_index,
        .str = str,
        .len = strlen,
    };
    current_token_index += 1;
    return t;
}

pub fn make_negative_matcher(str: [*:0]const u8) Token {
    var strlen: u32 = 0;
    while (str[strlen] != 0) {
        strlen += 1;
    }

    const t = Token{
        .id = current_token_index,
        .str = str,
        .len = strlen,
        .match_reverse = true,
    };
    current_token_index += 1;
    return t;
}
