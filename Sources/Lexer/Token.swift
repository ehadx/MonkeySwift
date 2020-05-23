//===-- Token -------------------------------------------------*- Swift -*-===//
//
// This file implements the tokens that the lexer is going to output.
//
//===----------------------------------------------------------------------===//

// Using string has the advantage of being easy to debug without a lot of
// boilerplate and helper functions: we can just print a string.
// Of course, using a string might not lead to the same performance as using
// an int or a byte would, but for this book a string is perfect.
//
public enum TokenType : String {
  //===--*- Special Types -*-----------===//
  case ILLEGAL   = "ILLEGAL"  // token/character we don't know about
  case EOF       = "EOF"      // end of file

  //===--*- Identifiers + Literals -*--===//
  case IDENT     = "IDENT"
  case INT       = "INT"

  //===--*- Operators -*---------------===//
  case ASSIGN    = "="
  case PLUS      = "+"
  case MINUS     = "-"
  case BANG      = "!"
  case ASTERISK  = "*"
  case SLASH     = "/"

  case LT        = "<"
  case GT        = ">"

  case EQ        = "=="
  case NOT_EQ    = "!="

  //===--*- Delimiters -*--------------===//
  case COMMA     = ","
  case SEMICOLON = ";"

  case LPAREN    = "("
  case RPAREN    = ")"
  case LBRACE    = "{"
  case RBRACE    = "}"

  //===--*- Keywords -*----------------===//
  case FUNCTION  = "FUNCTION"
  case LET       = "LET"
  case TRUE      = "TRUE"
  case FALSE     = "FALSE"
  case IF        = "IF"
  case ELSE      = "ELSE"
  case RETURN    = "RETURN"
}

public struct Token {
  public let type   : TokenType
  public let literal: String
}

private let keywords: [String:TokenType] = [
  "fn"    : .FUNCTION,
  "let"   : .LET     ,
  "true"  : .TRUE    ,
  "false" : .FALSE   ,
  "if"    : .IF      ,
  "else"  : .ELSE    ,
  "return": .RETURN  ,
]

// Checks the keywords table to see whether the given identifier is in fact
// a keyword. If it is, it returns the keyword’s TokenType constant. If it
// isn’t, we just get back .IDENT, which is the TokenType for all 
// user-defined identifiers.
//
internal func lookupIdent(_ ident: String) -> TokenType {
  keywords[ident, default: .IDENT]
}
