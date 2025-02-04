pub const TokenType = enum(u8) {
    Comment = '%',
};

pub const Token = struct {
    token_type: TokenType,
    value: []u8,
};
