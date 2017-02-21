

extension UTF8.CodeUnit: ExpressibleByStringLiteral {

    public init(stringLiteral value: StaticString) {
        assert(value.utf8CodeUnitCount == 1)
        self = value.utf8Start.pointee
    }
}

struct ByteScanner {
    typealias Byte = UTF8.CodeUnit

    var scanner: Scanner<Byte>
    var position: SourceLocation

    init(_ input: [Byte]) {
        self.scanner = Scanner(input)
        self.position = SourceLocation(line: 1, column: 1)
    }

    func peek(aheadBy n: Int = 0) -> Byte? {
        return scanner.peek(aheadBy: n)
    }

    @discardableResult
    mutating func pop() -> Byte {
        let byte = scanner.pop()

        if byte == "\n" {
            position.line   += 1
            position.column  = 1
        } else {
            position.column += 1
        }

        return byte
    }

    mutating func pop(_ n: Int) {

        for _ in 0..<n {
            pop()
        }
    }
}

extension ByteScanner {

    mutating func hasPrefix(_ prefix: String) -> Bool {

        for (index, char) in prefix.utf8.enumerated() {

            guard peek(aheadBy: index) == char else { return false }
        }

        return true
    }

    mutating func prefix(_ n: Int) -> String {

        var scalars: [UnicodeScalar] = []

        var index = 0
        while index < n, let next = peek(aheadBy: index) {
            defer { index += 1 }

            let scalar = UnicodeScalar(next)
            scalars.append(scalar)
        }

        return String(scalars.map(Character.init))
    }
}
