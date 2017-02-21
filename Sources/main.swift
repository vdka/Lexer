
enum LLVMTypeToken: CustomStringConvertible {
    case integer(width: Int)

    case half
    case float
    case double
    case fp128
    case x86_fp80
    case ppc_fp128

    case void

    case pointer

    // Vectors <4 x float>
    case langle
    case rangle

    // Arrays [4 x i8]
    case lbrack
    case rbrack

    // Structs
    //   unpacked: { i32, i32, i32 }
    //   packed:   <{ i8, i32 }>
    case lbrace
    case rbrace


    var description: String {
        switch self {
        case .integer(width: let width):
            return "i\(width)"

        case .double:
            return "double"

        case .float:
            return "float"

        case .half:
            return "half"

        case .fp128:
            return "fp128"

        case .x86_fp80:
            return "x86_fp80"

        case .ppc_fp128:
            return "ppc_fp128"

        case .void:
            return "void"

        case .pointer:
            return "*"

        case .langle:
            return "<"

        case .rangle:
            return ">"

        case .lbrack:
            return "["

        case .rbrack:
            return "]"

        case .lbrace:
            return "{"

        case .rbrace:
            return "}"
        }
    }
}

let file = "i8"

let digits = Set("1234567890".utf8)
let identChars = Set("_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".utf8)

var lexer = Lexer<LLVMTypeToken>(file) { lexer -> (token: LLVMTypeToken, location: SourceLocation)? in
    try lexer.skipWhitespace()

    guard let char = lexer.scanner.peek() else { return nil }

    // I don't think I am actualy after lastLocation
    let location = lexer.lastLocation

    switch char {
    case "i":
        let startLocation = lexer.lastLocation
        lexer.consume(1)
        guard let width = Int(lexer.consume(with: digits)) else {
            // Throw error.
            return nil
        }

        return (.integer(width: width), location)

    case _ where identChars.contains(char):
        let symbol = lexer.consume(with: identChars)
        switch symbol {
        case "void":
            return (.void, location)

        default: return nil
        }

    default:
        break
    }

    return nil
}

let res = try lexer.next()

print(res)
