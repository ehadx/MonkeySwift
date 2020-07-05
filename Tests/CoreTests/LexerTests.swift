import XCTest
@testable import Core

final class LexerTests: XCTestCase {
  var lexer: Lexer!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    lexer = Lexer("""
      let five1 = 5;
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
      "foobar"
      "foo bar"
      [1, 2];
      {"foo": "bar"}
      ?
    """)
  }
  
  func testNextToken() {
    let tests = [
      Token(keyword:    "let")!, Token(ident  :  "five1") , Token(char   :       "=")!,
      Token(number :      "5") , Token(char   :      ";")!, Token(keyword:     "let")!,
      Token(ident  :    "ten") , Token(char   :      "=")!, Token(number :      "10") ,
      Token(char   :      ";")!, Token(keyword:    "let")!, Token(ident  :     "add") ,
      Token(char   :      "=")!, Token(keyword:     "fn")!, Token(char   :       "(")!,
      Token(ident  :      "x") , Token(char   :      ",")!, Token(ident  :       "y") ,
      Token(char   :      ")")!, Token(char   :      "{")!, Token(ident  :       "x") ,
      Token(char   :      "+")!, Token(ident  :      "y") , Token(char   :       ";")!,
      Token(char   :      "}")!, Token(char   :      ";")!, Token(keyword:     "let")!,
      Token(ident  : "result") , Token(char   :      "=")!, Token(ident  :     "add") ,
      Token(char   :      "(")!, Token(ident  :   "five") , Token(char   :       ",")!,
      Token(ident  :    "ten") , Token(char   :      ")")!, Token(char   :       ";")!,
      Token(char   :      "!")!, Token(char   :      "-")!, Token(char   :       "/")!,
      Token(char   :      "*")!, Token(number :      "5") , Token(char   :       ";")!,
      Token(number :      "5") , Token(char   :      "<")!, Token(number :      "10") ,
      Token(char   :      ">")!, Token(number :      "5") , Token(char   :       ";")!,
      Token(keyword:     "if")!, Token(char   :      "(")!, Token(number :       "5") ,
      Token(char   :      "<")!, Token(number :     "10") , Token(char   :       ")")!,
      Token(char   :      "{")!, Token(keyword: "return")!, Token(keyword:    "true")!,
      Token(char   :      ";")!, Token(char   :      "}")!, Token(keyword:    "else")!,
      Token(char   :      "{")!, Token(keyword: "return")!, Token(keyword:   "false")!,
      Token(char   :      ";")!, Token(char   :      "}")!, Token(number :      "10") ,
      Token(char   :     "==")!, Token(number :     "10") , Token(char   :       ";")!,
      Token(number :     "10") , Token(char   :     "!=")!, Token(number :       "9") ,
      Token(char   :      ";")!, Token(string : "foobar") , Token(string : "foo bar") ,
      Token(char   :      "[")!, Token(number :      "1") , Token(char   :       ",")!,
      Token(number :      "2") , Token(char   :      "]")!, Token(char   :       ";")!,
      Token(char   :      "{")!, Token(string :    "foo") , Token(char   :       ":")!,
      Token(string :    "bar") , Token(char   :      "}")!, Token(illegal:       "?") ,
      Token(char   :     "\0")!,
    ]
    for (i, test) in tests.enumerated() {
      let nextToken = lexer.nextToken()
      XCTAssertEqual(nextToken.type, test.type, """
        test[\(i)] - wrong tokenType. \
        expected=\(test.type), \
        got=\(nextToken.type)
        """
      )
      XCTAssertEqual(nextToken.literal, test.literal, """
        test[\(i)] - wrong literal. \
        expected=\(test.literal), \
        got=\(nextToken.literal)
        """
      )
    }
  }
}
