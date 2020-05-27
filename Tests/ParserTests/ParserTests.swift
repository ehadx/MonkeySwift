import XCTest
import Lexer
@testable import Parser

final class ParserTests : XCTestCase {
  var parser: Parser!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
  }

  func testLetStatements() {
    parser = Parser(input: """
      let x = 5;
      let y = 10;
      let foobar = 838383;
    """)
    let program = parser.parseProgram()
    let error = checkParserErrors()

    if error == true {
      return
    }

    XCTAssertNotNil(program, "parseProgram returned nil", file: "Parser/Parser.swift", line: 35)

    XCTAssertEqual(program!.statements.count, 3, """
      statements does not contain 3 statements. \
      got=\(program!.statements.count)"
      """)

    let tests = [ "x", "y", "foobar" ]
    for (i, expectedIdent) in tests.enumerated() {
      let stmt = program!.statements[i]
      testLetStatement(statement: stmt, name: expectedIdent)
    }
  }

  private func testLetStatement(statement: Statement, name: String) {
    XCTAssertEqual(statement.tokenLiteral(), "let", """
      token literal not 'let'. got=\(statement.tokenLiteral())
      """)

    let letStmt = statement as! LetStatement

    XCTAssertTrue(type(of: letStmt) == LetStatement.self, """
      statement is not LetStatement. got=\(type(of: letStmt))
      """)

    XCTAssertEqual(letStmt.name.value, name, """
      letStmt.value.name not \(name). got=\(letStmt.name.value)
      """)

    XCTAssertEqual(letStmt.name.tokenLiteral(), name, """
      letStmt.name not \(name). got=\(letStmt.name.tokenLiteral())
      """)
  }

  private func checkParserErrors() -> Bool {
    var errors = parser.errors
    if errors.isEmpty {
      return false
    }
    continueAfterFailure = true
    XCTFail("Parser has \(errors.count) errors")
    for error in errors {
      XCTFail("parser error \(error)")
    }
    return true
  }
}
