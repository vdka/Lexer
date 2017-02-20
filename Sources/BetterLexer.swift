
struct Lexer<Token> {

    var scanner: ByteScanner
    var buffer: [(kind: Token, location: SourceLocation)] = []

    var lastLocation: SourceLocation

    init(_ file: String) {

        self.scanner = ByteScanner(Array(file.utf8))
        self.lastLocation = scanner.position
    }

    mutating func peek(aheadBy n: Int = 0) throws -> (kind: Token, location: SourceLocation)? {
        if n < buffer.count { return buffer[n] }

        for _ in buffer.count...n {
            guard let token = try next() else { return nil }
            buffer.append(token)
        }
        return buffer.last
    }

    @discardableResult
    mutating func pop() throws -> (kind: Token, location: SourceLocation) {
        if buffer.isEmpty {
            let token = try next()!
            lastLocation = token.location
            return token
        }
        else {
            let token = buffer.removeFirst()
            lastLocation = token.location
            return token
        }
    }

    internal mutating func next() throws -> (kind: Token, location: SourceLocation)? {
        try skipWhitespace()

        guard let char = scanner.peek() else { return nil }

        let location = scanner.position

        switch char {
        case _ where identChars.contains(char):
            let symbol = consume(with: identChars + digits)
            if let keyword = Token.Keyword(rawValue: symbol) { return (.keyword(keyword), location) }
            else if symbol == "_" { return (.underscore, location) }
            else { return (.identifier(symbol), location) }

        case _ where opChars.contains(char):
            let symbol = consume(with: opChars)
            if let keyword = Token.Keyword(rawValue: symbol) { return (.keyword(keyword), location) }
            else if symbol == "=" { return (.equals, location) }
            else { return (.operator(symbol), location) }

        // TODO(vdka): Correctly consume (and validate) number literals (real and integer)
        case _ where digits.contains(char):
            let number = consume(with: digits)
            return (.integer(number), location)

        case "\"":
            scanner.pop()
            let string = consume(upTo: "\"")
            guard case "\""? = scanner.peek() else { throw error(.unterminatedString) }
            scanner.pop()
            return (.string(string), location)

        case "(":
            scanner.pop()
            return (.lparen, location)

        case ")":
            scanner.pop()
            return (.rparen, location)

        case "[":
            scanner.pop()
            return (.lbrack, location)

        case "]":
            scanner.pop()
            return (.rbrack, location)

        case "{":
            scanner.pop()
            return (.lbrace, location)

        case "}":
            scanner.pop()
            return (.rbrace, location)

        case ":":
            scanner.pop()
            return (.colon, location)

        case ",":
            scanner.pop()
            return (.comma, location)

        case ".":
            scanner.pop()
            return (.dot, location)

        case "#":
            scanner.pop()
            let identifier = consume(upTo: { !whitespace.contains($0) })
            guard let directive = Token.Directive(rawValue: identifier) else {
                throw error(.unknownDirective)
            }

            return (.directive(directive), location)

        default:
            let suspect = consume(upTo: whitespace.contains)

            throw error(.invalidToken(suspect))
        }
    }

    @discardableResult
    private mutating func consume(with chars: [Byte]) -> ByteString {
        
        var str: ByteString = ""
        while let char = scanner.peek(), chars.contains(char) {
            scanner.pop()
            str.append(char)
        }
        
        return str
    }
    
    @discardableResult
    private mutating func consume(with chars: ByteString) -> ByteString {
        
        var str: ByteString = ""
        while let char = scanner.peek(), chars.bytes.contains(char) {
            scanner.pop()
            str.append(char)
        }
        
        return str
    }
    
    @discardableResult
    private mutating func consume(upTo predicate: (Byte) -> Bool) -> ByteString {
        
        var str: ByteString = ""
        while let char = scanner.peek(), predicate(char) {
            scanner.pop()
            str.append(char)
        }
        return str
    }
    
    @discardableResult
    private mutating func consume(upTo target: Byte) -> ByteString {
        
        var str: ByteString = ""
        while let char = scanner.peek(), char != target {
            scanner.pop()
            str.append(char)
        }
        return str
    }
    
}
