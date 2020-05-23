import XCTest
@testable import Lexer

final class LexerTests : XCTestCase {
  var lexer: Lexer!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    lexer = Lexer(input: """
      let five = 5;
      let ten = 10;

      let add = fn(x, y) {
        x + y;
      };

      let result = add(five, ten);
      
      !-/*5;

      5 < 10 > 5;

      if (5 < 10) {
        return true;
      } else {
        return false;
      }

      10 == 10;
      
      10 != 9;
    """)
  }
  
  func testNextToken() {
    let tests = [
      Token(type: .LET      , literal: "let"  ), Token(type: .IDENT    , literal: "five"  ),
      Token(type: .ASSIGN   , literal: "="    ), Token(type: .INT      , literal: "5"     ),
      Token(type: .SEMICOLON, literal: ";"    ), Token(type: .LET      , literal: "let"   ),
      Token(type: .IDENT    , literal: "ten"  ), Token(type: .ASSIGN   , literal: "="     ),
      Token(type: .INT      , literal: "10"   ), Token(type: .SEMICOLON, literal: ";"     ),
      Token(type: .LET      , literal: "let"  ), Token(type: .IDENT    , literal: "add"   ),
      Token(type: .ASSIGN   , literal: "="    ), Token(type: .FUNCTION , literal: "fn"    ),
      Token(type: .LPAREN   , literal: "("    ), Token(type: .IDENT    , literal: "x"     ),
      Token(type: .COMMA    , literal: ","    ), Token(type: .IDENT    , literal: "y"     ),
      Token(type: .RPAREN   , literal: ")"    ), Token(type: .LBRACE   , literal: "{"     ),
      Token(type: .IDENT    , literal: "x"    ), Token(type: .PLUS     , literal: "+"     ),
      Token(type: .IDENT    , literal: "y"    ), Token(type: .SEMICOLON, literal: ";"     ),
      Token(type: .RBRACE   , literal: "}"    ), Token(type: .SEMICOLON, literal: ";"     ),
      Token(type: .LET      , literal: "let"  ), Token(type: .IDENT    , literal: "result"),
      Token(type: .ASSIGN   , literal: "="    ), Token(type: .IDENT    , literal: "add"   ),
      Token(type: .LPAREN   , literal: "("    ), Token(type: .IDENT    , literal: "five"  ),
      Token(type: .COMMA    , literal: ","    ), Token(type: .IDENT    , literal: "ten"   ),
      Token(type: .RPAREN   , literal: ")"    ), Token(type: .SEMICOLON, literal: ";"     ),
      Token(type: .BANG     , literal: "!"    ), Token(type: .MINUS    , literal: "-"     ),
      Token(type: .SLASH    , literal: "/"    ), Token(type: .ASTERISK , literal: "*"     ),
      Token(type: .INT      , literal: "5"    ), Token(type: .SEMICOLON, literal: ";"     ),
      Token(type: .INT      , literal: "5"    ), Token(type: .LT       , literal: "<"     ),
      Token(type: .INT      , literal: "10"   ), Token(type: .GT       , literal: ">"     ),
      Token(type: .INT      , literal: "5"    ), Token(type: .SEMICOLON, literal: ";"     ),
      Token(type: .IF       , literal: "if"   ), Token(type: .LPAREN   , literal: "("     ),
      Token(type: .INT      , literal: "5"    ), Token(type: .LT       , literal: "<"     ),
      Token(type: .INT      , literal: "10"   ), Token(type: .RPAREN   , literal: ")"     ),
      Token(type: .LBRACE   , literal: "{"    ), Token(type: .RETURN   , literal: "return"),
      Token(type: .TRUE     , literal: "true" ), Token(type: .SEMICOLON, literal: ";"     ),
      Token(type: .RBRACE   , literal: "}"    ), Token(type: .ELSE     , literal: "else"  ),
      Token(type: .LBRACE   , literal: "{"    ), Token(type: .RETURN   , literal: "return"),
      Token(type: .FALSE    , literal: "false"), Token(type: .SEMICOLON, literal: ";"     ),
      Token(type: .RBRACE   , literal: "}"    ), Token(type: .INT      , literal: "10"    ),
      Token(type: .EQ       , literal: "=="   ), Token(type: .INT      , literal: "10"    ),
      Token(type: .SEMICOLON, literal: ";"    ), Token(type: .INT      , literal: "10"    ),
      Token(type: .NOT_EQ   , literal: "!="   ), Token(type: .INT      , literal: "9"     ),
      Token(type: .SEMICOLON, literal: ";"    ), Token(type: .EOF      , literal: ""      ),
    ]

    for (i, expectedToken) in tests.enumerated() {
      let nextToken = lexer.nextToken()

      XCTAssertEqual(nextToken.type, expectedToken.type, """
        test[\(i)] - wrong tokenType. \
        expected=\(expectedToken.type.rawValue), \
        got=\(nextToken.type.rawValue)
        """,
        file: "Lexer/Lexer.swift", line: 82)

      XCTAssertEqual(nextToken.literal, expectedToken.literal, """
        test[\(i)] - wrong literal. \
        expected=\(expectedToken.literal), \
        got=\(nextToken.literal)
        """,
        file: "Lexer/Lexer.swift", line: 82)
    }
  }
}
