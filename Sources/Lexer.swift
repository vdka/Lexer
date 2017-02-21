
let whitespace	= Array<UTF8.CodeUnit>(" \t\n".utf8)

struct Lexer<Token> {

    typealias Byte = UTF8.CodeUnit

    typealias Output = (token: Token, location: SourceLocation)

    var scanner: ByteScanner
    var buffer: [Output] = []
    var nextInternal: (inout Lexer<Token>) throws -> Output?

    var lastLocation: SourceLocation

    init(_ file: String, next: @escaping (inout Lexer<Token>) throws -> Output?) {

        self.scanner = ByteScanner(Array(file.utf8))
        self.buffer  = []
        self.nextInternal = next

        self.lastLocation = scanner.position
    }

    mutating func next() throws -> Output? {
        return try self.nextInternal(&self)
    }

    mutating func peek(aheadBy n: Int = 0) throws -> Output? {
        if n < buffer.count { return buffer[n] }

        for _ in buffer.count...n {
            guard let token = try next() else { return nil }
            buffer.append(token)
        }
        return buffer.last
    }

    @discardableResult
    mutating func pop() throws -> Output {
        if buffer.isEmpty {
            let token = try next()!
            lastLocation = token.location
            return token
        } else {
            let token = buffer.removeFirst()
            lastLocation = token.location
            return token
        }
    }

    @discardableResult
    mutating func consume(_ n: Int) -> String {

        var scalars: [UnicodeScalar] = []
        for _ in 0..<n {
            let char = scanner.pop()

            let scalar = UnicodeScalar(char)
            scalars.append(scalar)
        }

        return String(scalars.map(Character.init))
    }

    @discardableResult
    mutating func consume(with chars: Set<Byte>) -> String {

        var scalars: [UnicodeScalar] = []
        while let char = scanner.peek(), chars.contains(char) {
            scanner.pop()

            let scalar = UnicodeScalar(char)
            scalars.append(scalar)
        }

        return String(scalars.map(Character.init))
    }

    @discardableResult
    mutating func consume(upTo predicate: (Byte) -> Bool) -> String {

        var scalars: [UnicodeScalar] = []
        while let char = scanner.peek(), predicate(char) {
            scanner.pop()

            let scalar = UnicodeScalar(char)
            scalars.append(scalar)
        }
        return String(scalars.map(Character.init))
    }

    @discardableResult
    mutating func consume(upTo target: Byte) -> String {

        var scalars: [UnicodeScalar] = []
        while let char = scanner.peek(), char != target {
            scanner.pop()

            let scalar = UnicodeScalar(char)
            scalars.append(scalar)
        }

        return String(scalars.map(Character.init))    }
}

extension Lexer {

    mutating func skipWhitespace() throws {

        while let char = scanner.peek() {

            switch char {
            case "/":
                if scanner.peek(aheadBy: 1) == "*" { try skipBlockComment() }
                else if scanner.peek(aheadBy: 1) == "/" { skipLineComment() }
                try skipWhitespace()
                return

            case _ where whitespace.contains(char):
                scanner.pop()

            default:
                return
            }
        }
    }

    mutating func skipBlockComment() throws {
        assert(scanner.hasPrefix("/*"))

        scanner.pop(2)

        var depth: UInt = 1
        repeat {

            guard scanner.peek() != nil else {
                throw LexerError(message: "Unmatched block comment", location: lastLocation)
            }

            if scanner.hasPrefix("*/") { depth -= 1 }
            else if scanner.hasPrefix("/*") { depth += 1 }

            scanner.pop()

            if depth == 0 { break }
        } while depth > 0
        scanner.pop()
    }

    private mutating func skipLineComment() {
        assert(scanner.hasPrefix("//"))

        while let char = scanner.peek(), char != "\n" { scanner.pop() }
    }
}


struct LexerError: Swift.Error {
    var message: String?
    var location: SourceLocation
}
