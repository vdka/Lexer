
struct Scanner<Element> {
    var pointer: UnsafePointer<Element>
    var elements: UnsafeBufferPointer<Element>
    let endAddress: UnsafePointer<Element>
    // assuming you don't mutate no copy _should_ occur
    let elementsCopy: [Element]
}

extension Scanner {
    init(_ data: [Element]) {
        self.elementsCopy = data
        self.elements = elementsCopy.withUnsafeBufferPointer { $0 }
        self.endAddress = elements.endAddress
        self.pointer = elements.baseAddress!
    }
}

extension Scanner {
    func peek(aheadBy n: Int = 0) -> Element? {
        guard pointer.advanced(by: n) < endAddress else { return nil }
        return pointer.advanced(by: n).pointee
    }

    /// - Precondition: index != bytes.endIndex. It is assumed before calling pop that you have
    @discardableResult
    mutating func pop() -> Element {
        assert(pointer < endAddress)
        defer { pointer = pointer.advanced(by: 1) }
        return pointer.pointee
    }

    /// - Precondition: index != bytes.endIndex. It is assumed before calling pop that you have
    @discardableResult
    mutating func attemptPop() throws -> Element {
        guard pointer < endAddress else { throw ScannerError.Reason.endOfStream }
        defer { pointer = pointer.advanced(by: 1) }
        return pointer.pointee
    }

    mutating func pop(_ n: Int) {
        assert(pointer.advanced(by: n - 1) < endAddress)
        pointer = pointer.advanced(by: n)
    }
}

protocol _Swift3Pls {}
extension UnicodeScalar: _Swift3Pls {}
extension Scanner where Element: _Swift3Pls {

    mutating func hasPrefix(_ prefix: String) -> Bool {

        for (index, el) in prefix.unicodeScalars.enumerated() {

            guard peek(aheadBy: index) as? UnicodeScalar == el else { return false }
        }

        return true
    }

    mutating func prefix(_ n: Int) -> String {

        var scalars: [UnicodeScalar] = []

        var index = 0
        while index < n, let next = peek(aheadBy: index) {
            defer { index += 1 }

            scalars.append(next as! UnicodeScalar)
        }

        return String(scalars.map(Character.init))
    }

    var isEmpty: Bool {
        return pointer >= endAddress
    }
}

struct ScannerError: Swift.Error {
    let position: UInt
    let reason: Reason

    enum Reason: Swift.Error {
        case endOfStream
    }
}

extension UnsafeBufferPointer {
    fileprivate var endAddress: UnsafePointer<Element> {

        return baseAddress!.advanced(by: endIndex)
    }
}
