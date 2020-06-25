import XCTest
@testable import Core

final class LexerTests : XCTestCase {
  var lexer: Lexer!

  override func setUp() {
    super.setUp()
    continueAfterFailure = true
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
    """)
  }
  
  func testNextToken() {
    let tests = [
      "let", "five1" , "="    , "5"  , ";"  , "let"   , "ten" , "="     , "10", ";"   ,
      "let", "add"   , "="    , "fn" , "("  , "x"     , ","   , "y"     , ")" , "{"   , 
      "x"  ,  "+"    , "y"    , ";"  , "}"  , ";"     , "let" , "result", "=" , "add" ,
      "("  , "five"  , ","    , "ten", ")"  , ";"     , "!"   , "-"     , "/" , "*"   ,
      "5"  , ";"     , "5"    , "<"  , "10" , ">"     , "5"   , ";"     , "if", "("   ,
      "5"  , "<"     , "10"   , ")"  , "{"  , "return", "true", ";"     , "}" , "else",
      "{"  , "return", "false", ";"  , "}"  , "10"    , "=="  , "10"    , ";" , "10"  ,
      "!=" , "9"     , ";"    , "\0" ,
    ]
    for (i, test) in tests.enumerated() {
      let expected  = Token(test)
      let nextToken = lexer.nextToken()
      XCTAssertEqual(nextToken.type, expected.type, """
        test[\(i)] - wrong tokenType. \
        expected=\(expected.type), \
        got=\(nextToken.type)
        """
      )
      XCTAssertEqual(nextToken.literal, expected.literal, """
        test[\(i)] - wrong literal. \
        expected=\(expected.literal), \
        got=\(nextToken.literal)
        """
      )
    }
  }
}
