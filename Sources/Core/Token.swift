//===-- Token -------------------------------------------------*- Swift -*-===//
//
// This file implements the tokens that the lexer is going to output.
//
//===----------------------------------------------------------------------===//

public struct Token {
  public let type   : Token.`Type`
  public let literal: String

  init(_ literal: String) {
    self.type    = Type(literal)
    self.literal = literal
  }

}

extension Token {
  public enum `Type` {
    //===--*- Special Types -*-----------===//
    case illegal   // token/character we don't know about
    case eof       // end of file

    //===--*- Identifiers + Literals -*--===//
    case ident
    case int

    //===--*- Operators -*---------------===//
    case assign
    case plus
    case minus
    case bang
    case asterisk
    case slash

    case lessThan
    case greaterThan

    case equal
    case notEqual

    //===--*- Delimiters -*--------------===//
    case comma
    case semicolon

    case leftParen
    case rightParen
    case leftBrace
    case rightBrace

    //===--*- Keywords -*----------------===//
    case function
    case `let`
    case `true`
    case `false`
    case `if`
    case `else`
    case `return`

    init(_ literal: String) {
      switch literal {
      case "", "\0": self = .eof
      case "="     : self = .assign
      case "+"     : self = .plus
      case "-"     : self = .minus
      case "!"     : self = .bang
      case "*"     : self = .asterisk
      case "/"     : self = .slash
      case "<"     : self = .lessThan
      case ">"     : self = .greaterThan
      case "=="    : self = .equal
      case "!="    : self = .notEqual
      case ","     : self = .comma
      case ";"     : self = .semicolon
      case "("     : self = .leftParen
      case ")"     : self = .rightParen
      case "{"     : self = .leftBrace
      case "}"     : self = .rightBrace
      case "fn"    : self = .function
      case "let"   : self = .let
      case "true"  : self = .true
      case "false" : self = .false
      case "if"    : self = .if
      case "else"  : self = .else
      case "return": self = .return
      default: 
        // TODO: maybe try a different approach
        //
        if Type.isValid(identifier: literal) {
          self = .ident
        } else if Type.isValid(number: literal) {
          self = .int
        } else {
          self = .illegal
        }
      }
    }

    static func isValid(identifier: String) -> Bool {
      for (pos, char) in identifier.enumerated() {
        if pos == 0 && !Lexer.isLetter(char) {
          return false
        }
        // allow numbers after the first letter
        //
        if (!Lexer.isLetter(char) && !Lexer.isDigit(char)) {
          return false
        }
      }
      return true
    }

    static func isValid(number: String) -> Bool {
      for char in number {
        if !Lexer.isDigit(char) {
          return false
        }
      }
      return true
    }
  }
}
