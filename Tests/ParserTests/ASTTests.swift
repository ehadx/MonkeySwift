import XCTest
@testable import Lexer
@testable import Parser

final class ASTTests : XCTestCase {
  func testAsString() {
    let program = Program(
      statements: [
        LetStatement(
          token: Token(type: .LET, literal: "let"),
          name: Identifier(
            token: Token(type: .IDENT, literal: "myVar"),
            value: "myVar"),
          value: Identifier(
            token: Token(type: .IDENT, literal: "anotherVar"),
            value: "anotherVar"))
      ])
    XCTAssertEqual(program.asString(), "let myVar = anotherVar;", """
      program.asString() wrong. got=\(program.asString())
      """)
  }
}
