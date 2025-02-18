pub const TokenState = enum {
    Unknown,
    Match,
    Possible,
    Invalid,
};

pub const ScanError = error{
    InvalidToken,
    EndOfScript,
    MissingFollowToken,
};
