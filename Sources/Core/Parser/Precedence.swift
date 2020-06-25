//===-- Precedence --------------------------------------------*- Swift -*-===//
//
// Implements the Precedence enum that will be used to determin if a certain
// operator does have a higher precedence than an other one or not.
//
//===----------------------------------------------------------------------===//

extension Parser {
  enum Precedence: Int {
    case lowest = 0
    case equals      // ==
    case lessGreater // > or <
    case sum         // +a
    case product     // *
    case `prefix`    // -X or !X
    case call        // myFunction(X)

    init(_ type: Token.`Type`) {
      switch type {
      case .equal   , .notEqual   : self = .equals
      case .lessThan, .greaterThan: self = .lessGreater
      case .plus    , .minus      : self = .sum
      case .slash   , .asterisk   : self = .product
      case .leftParen             : self = .call
      default:
        self = .lowest
      }
    }

    static func <(lhs: Precedence, rhs: Precedence) -> Bool {
      lhs.rawValue < rhs.rawValue
    }
  }
}
