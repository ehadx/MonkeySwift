import XCTest
@testable import Core

final class ASTTests : XCTestCase {
  func testAsString() {
    let program = Program(
      statements: [
        LetStatement(
          token: Token("let"),
          name : Identifier(token: Token("myVar")     , value: "myVar"),
          value: Identifier(token: Token("anotherVar"), value: "anotherVar")
        )
      ])
    XCTAssertEqual(program.asString(), "let myVar = anotherVar;", """
      program.asString() wrong. got=\(program.asString())
      """
    )
  }
}
