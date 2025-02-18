const Token = @import("Token.zig");

// TokenInstance Obj
const TokenInstance = @This();

content: []const u8,
token: *const Token,
