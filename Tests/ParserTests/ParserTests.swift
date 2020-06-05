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
    let program = parser.parseProgram()!
    
    if checkParserErrors() {
      return
    }

    XCTAssertNotNil(program, "parseProgram returned nil", file: "Parser/Parser.swift", line: 35)

    XCTAssertEqual(program.statements.count, 3, """
      statements does not contain 3 statements. \
      got=\(program.statements.count)"
      """)

    continueAfterFailure = true
    let tests = [ "x", "y", "foobar" ]
    for (i, expectedIdent) in tests.enumerated() {
      let stmt = program.statements[i]
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

  func testReturnStatement() {
    parser = Parser(input: """
      return 5;
      return 10;
      return 993322;
    """)
    let program = parser.parseProgram()!
    
    if checkParserErrors() {
      return
    }

    XCTAssertEqual(program.statements.count, 3, """
      statements does not contain 3 statements. \
      got=\(program.statements.count)
      """)

    continueAfterFailure = true
    for stmt in program.statements {
      guard let returnStmt = stmt as? ReturnStatement else {
        XCTFail("stmt is not ReturnStatement. got=\(type(of: stmt))")
        continue
      }
      XCTAssertEqual(returnStmt.tokenLiteral(), "return", """
        returnStmt.TokenLiteral not 'return', got \(returnStmt.tokenLiteral())
        """)
    }
  }

  func testIdentifierExpression() {
    parser = Parser(input: "foobar;")
    let program = parser.parseProgram()!
    
    if checkParserErrors() {
      return
    }

    XCTAssertEqual(program.statements.count, 1, """
      program has not enough statements. got=\(program.statements.count)
      """)
    
    guard let stmt = program.statements[0] as? ExpressionStatement else {
      XCTFail("""
        program.Statements[0] is not ast.ExpressionStatement. \
        got=\(type(of: program.statements[0]))
        """)
      return
    }

    guard let ident = stmt.expression as? Identifier else {
      XCTFail("exp not *ast.Identifier. got=\(type(of: stmt.expression))")
      return
    }

    continueAfterFailure = true
    XCTAssertEqual(ident.value, "foobar", "ident.Value not foobar. got=\(ident.value)")
    XCTAssertEqual(ident.tokenLiteral(), "foobar", """
      ident.tokenLiteral not foobar. got=\(ident.tokenLiteral())
      """)
  }

  func testIntegerLiteralExpression() {
    parser = Parser(input: "5;")
    let program = parser.parseProgram()!

    if checkParserErrors() {
      return
    }

    XCTAssertEqual(program.statements.count, 1, """
      program has not enough statements. got=\(program.statements.count)
      """)
    
    guard let stmt = program.statements[0] as? ExpressionStatement else {
      XCTFail("""
        program.Statements[0] is not ExpressionStatement. \
        got=\(type(of: program.statements[0]))
        """)
      return
    }

    guard let literal = stmt.expression as? IntegerLiteral else {
      XCTFail("""
        program.Statements[0] is not IntegerLiteral. \
        got=\(type(of: stmt.expression))
        """)
      return
    }

    continueAfterFailure = true
    XCTAssertEqual(literal.value, 5, "literal.Value not 5. got=\(literal.value)")
    XCTAssertEqual(literal.tokenLiteral(), "5", """
      literal.tokenLiteral not 5. got=\(literal.tokenLiteral())
      """)
  }

  func testParsingPrefixExpressions() {
    struct PrefixTest {
      let input     : String
      let `operator`: String
      let intValue  : Int64
    }
    let prefixTests = [
      PrefixTest(input: "!5;" , operator: "!", intValue: 5 ),
      PrefixTest(input: "-15;", operator: "-", intValue: 15),
    ]

    for test in prefixTests {
      parser = Parser(input: test.input)
      let program = parser.parseProgram()!

      if checkParserErrors() {
        return
      }

      XCTAssertEqual(program.statements.count, 1, """
        program does not contain 1 statement. got=\(program.statements.count)
        """)
      
      guard let stmt = program.statements[0] as? ExpressionStatement else {
        XCTFail("""
          program.statement[0] is not ExpressionStatement. \
          got=\(type(of: program.statements[0]))
          """)
        return
      }

      guard let exp = stmt.expression as? PrefixExpression else {
        XCTFail("stmt is not PrefixExpression. got=\(type(of: stmt.expression))")
        return
      }

      XCTAssertEqual(exp.`operator`, test.`operator`, """
        exp.operator is not '\(test.`operator`)'. got=\(exp.`operator`)
        """)

      if !testIntegerLiteral(exp.right, test.intValue) {
        return
      }
    }
  }

  private func testIntegerLiteral(_ exp: Expression?, _ value: Int64) -> Bool {
    XCTAssertNotNil(exp, "exp is nil")

    continueAfterFailure = true
    guard let integer = exp! as? IntegerLiteral else {
      XCTFail("exp not IntegerLiteral. got=\(type(of: exp!))")
      return false
    }

    if integer.value != value {
      XCTFail("integer.value not \(value). got=\(integer.value)")
      return false
    }

    if integer.tokenLiteral() != "\(value)" {
      XCTFail("integ.tokenLiteral not \(value). got=\(integer.tokenLiteral())")
      return false
    }

    return true
  }

  func testParsingInfixExpressions() {
    struct InfixTest {
      let input     : String
      let leftVal   : Int64
      let `operator`: String
      let rightVal  : Int64
    }

    let tests = [
      InfixTest(input: "5+5;" , leftVal: 5, operator: "+" , rightVal: 5),
      InfixTest(input: "5-5;" , leftVal: 5, operator: "-" , rightVal: 5),
      InfixTest(input: "5*5;" , leftVal: 5, operator: "*" , rightVal: 5),
      InfixTest(input: "5/5;" , leftVal: 5, operator: "/" , rightVal: 5),
      InfixTest(input: "5>5;" , leftVal: 5, operator: ">" , rightVal: 5),
      InfixTest(input: "5<5;" , leftVal: 5, operator: "<" , rightVal: 5),
      InfixTest(input: "5==5;", leftVal: 5, operator: "==", rightVal: 5),
      InfixTest(input: "5!=5;", leftVal: 5, operator: "!=", rightVal: 5),
    ]

    for test in tests {
      parser = Parser(input: test.input)
      let program = parser.parseProgram()!

      if checkParserErrors() {
        return
      }

      XCTAssertEqual(program.statements.count, 1, """
        program does not contain 1 statement. got=\(program.statements.count)
        """)
      
      guard let stmt = program.statements[0] as? ExpressionStatement else {
        XCTFail("""
          program.statement[0] is not ExpressionStatement. \
          got=\(type(of: program.statements[0]))
          """)
        return
      }

      guard let exp = stmt.expression as? InfixExpression else {
        XCTFail("stmt is not InfixExpression. got=\(type(of: stmt.expression))")
        return
      }

      if !testIntegerLiteral(exp.left, test.leftVal) {
        return
      }
      
      XCTAssertEqual(exp.operator, test.operator, """
        exp.operator is not '\(test.operator)'. got=\(exp.operator)
        """)

      if !testIntegerLiteral(exp.right, test.rightVal) {
        return
      }
    }
  }

  func testOperatorPrecedenceParsing() {
    struct Test {
      let input   : String
      let expected: String
    }

    let tests = [
      Test(input: "-a * b"                    , expected: "((-a) * b)"),
      Test(input: "!-a"                       , expected: "(!(-a))"),
      Test(input: "a + b + c"                 , expected: "((a + b) + c)"),
      Test(input: "a + b - c"                 , expected: "((a + b) - c)"),
      Test(input: "a * b * c"                 , expected: "((a * b) * c)"),
      Test(input: "a * b / c"                 , expected: "((a * b) / c)"),
      Test(input: "a + b / c"                 , expected: "(a + (b / c))"),
      Test(input: "a + b * c + d / e - f"     , expected: "(((a + (b * c)) + (d / e)) - f)"),
      Test(input: "3 + 4; -5 * 5"             , expected: "(3 + 4)((-5) * 5)"),
      Test(input: "5 > 4 == 3 < 4"            , expected: "((5 > 4) == (3 < 4))"),
      Test(input: "5 < 4 != 3 > 4"            , expected: "((5 < 4) != (3 > 4))"),
      Test(input: "3 + 4 * 5 == 3 * 1 + 4 * 5", expected: "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"),
      Test(input: "3 + 4 * 5 == 3 * 1 + 4 * 5", expected: "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))")
    ]

    for test in tests {
      parser = Parser(input: test.input)
      let program = parser.parseProgram()!

      if checkParserErrors() {
        return
      }

      let actual = program.asString()
      continueAfterFailure = true
      XCTAssertEqual(actual, test.expected, "expected=\(test.expected), got=\(actual)")
    }
  }

  private func checkParserErrors() -> Bool {
    let errors = parser.errors
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
