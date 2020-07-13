//===-- Token -------------------------------------------------*- Swift -*-===//
//
// This file implements the tokens that the lexer is going to output.
//
//===----------------------------------------------------------------------===//

public struct Token {
  public let type   : Token.`Type`
  public let literal: String

  init?(char: String) {
    guard let type = Type(char: char) else {
      return nil
    }
    self.type    = type
    self.literal = char
  }

  init?(keyword: String) {
    guard let type = Type(keyword: keyword) else {
      return nil
    }
    self.type    = type
    self.literal = keyword
  }

  init(ident: String) {
    self.type    = .ident
    self.literal = ident 
  }

  init(number: String) {
    self.type    = .int
    self.literal = number 
  }

  init(string: String) {
    self.type    = .string
    self.literal = string
  }

  init(illegal: String) {
    self.type    = .illegal
    self.literal = illegal 
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
    case string

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
    case colon

    case leftParen
    case rightParen
    case leftBrace
    case rightBrace
    case leftBracket
    case rightBracket

    //===--*- Keywords -*----------------===//
    case function
    case macro
    case `let`
    case `true`
    case `false`
    case `if`
    case `else`
    case `return`

    init?(char: String) {
      switch char {
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
      case ":"     : self = .colon
      case "("     : self = .leftParen
      case ")"     : self = .rightParen
      case "{"     : self = .leftBrace
      case "}"     : self = .rightBrace
      case "["     : self = .leftBracket
      case "]"     : self = .rightBracket
      default: 
        return nil
      }
    }

    init?(keyword: String) {
      switch keyword {
      case "fn"    : self = .function
      case "let"   : self = .let
      case "true"  : self = .true
      case "false" : self = .false
      case "if"    : self = .if
      case "else"  : self = .else
      case "return": self = .return
      case "macro" : self = .macro
      default:
        return nil
      }
    }
  }
}
