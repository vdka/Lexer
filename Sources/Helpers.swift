

// Combats Boilerplate
extension ExpressibleByStringLiteral where StringLiteralType == StaticString {

    public init(unicodeScalarLiteral value: StaticString) {
        self.init(stringLiteral: value)
    }

    public init(extendedGraphemeClusterLiteral value: StaticString) {
        self.init(stringLiteral: value)
    }
}
