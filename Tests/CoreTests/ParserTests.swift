import XCTest
@testable import Core

class ParserTests: XCTestCase {
  var parser: Parser!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
  }

  func testLetStatements() {
    struct Test {
      let input        : String
      let expectedIdent: String
      let expectedValue: Any
    }
    let tests = [
      Test(input: "let x = 5;"   , expectedIdent: "x"  , expectedValue: 5   ),
      Test(input: "let y = true;", expectedIdent: "y"  , expectedValue: true),
      Test(input: "let foo = y;" , expectedIdent: "foo", expectedValue: "y" ),
    ]
    for test in tests {
      parser = Parser(test.input)
      let program = parser.parseProgram()
      XCTAssertEqual(program.statements.count, 1, """
        statements does not contain 1 statements. \
        got=\(program.statements.count)"
        """)
      let stmt = program.statements[0]
      testLetStatement(stmt, test.expectedIdent)
      let letStmt = stmt as! LetStatement;
      testLiteralExpression(letStmt.value, test.expectedValue)
    }
  }

  private func testLetStatement(_ statement: Statement, _ name: String) {
    XCTAssertEqual(statement.tokenLiteral(), "let", """
      token literal not 'let'. got=\(statement.tokenLiteral())
      """)
    guard let letStmt = statement as? LetStatement else {
      XCTFail("statement is not LetStatement. got=\(type(of: statement))")
      return
    }
    XCTAssertEqual(letStmt.name.value, name, """
      letStmt.value.name not \(name). got=\(letStmt.name.value)
      """)
    XCTAssertEqual(letStmt.name.tokenLiteral(), name, """
      letStmt.name not \(name). got=\(letStmt.name.tokenLiteral())
      """)
  }

  func testReturnStatements() {
    struct Test {
      let input        : String
      let expectedValue: Any
    }
    let tests = [
      Test(input: "return 5;"   , expectedValue: 5    ),
      Test(input: "return true;", expectedValue: true ),
      Test(input: "return foo;" , expectedValue: "foo")
    ]
    for test in tests {
      parser      = Parser(test.input);
      let program = parser.parseProgram()
      XCTAssertEqual(program.statements.count, 1, """
        statements does not contain 1 statements. \
        got=\(program.statements.count)
        """)
      let stmt = program.statements[0]
      guard let returnStmt = stmt as? ReturnStatement else {
        XCTFail("stmt is not ReturnStatement. got=\(type(of: stmt))")
        return
      }
      XCTAssertEqual(returnStmt.tokenLiteral(), "return", """
        returnStmt.TokenLiteral not 'return', got \(returnStmt.tokenLiteral())
        """)
      testLiteralExpression(returnStmt.returnValue, test.expectedValue)
    }
  }

  func testIdentifierExpression() {
    parser      = Parser("foobar;")
    let program = parser.parseProgram()
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
    parser = Parser("5;")
    let program = parser.parseProgram()
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
      XCTFail("exp is not IntegerLiteral. got=\(type(of: stmt.expression))")
      return
    }
    continueAfterFailure = true
    XCTAssertEqual(literal.value, 5, "literal.Value not 5. got=\(literal.value)")
    XCTAssertEqual(literal.tokenLiteral(), "5", """
      literal.tokenLiteral not 5. got=\(literal.tokenLiteral())
      """)
  }

  func testParsingPrefixExpressions() {
    struct Test {
      let input     : String
      let `operator`: String
      let value     : Any
    }
    let tests = [
      Test(input: "!5;"    , operator: "!", value: 5    ),
      Test(input: "-15;"   , operator: "-", value: 15   ),
      Test(input: "!foo;"  , operator: "!", value: "foo"),
      Test(input: "-foo;"  , operator: "-", value: "foo"),
      Test(input: "!true;" , operator: "!", value: true ),
      Test(input: "!false;", operator: "!", value: false),
    ]
    for test in tests {
      parser      = Parser(test.input)
      let program = parser.parseProgram()
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
      XCTAssertEqual(exp.operator, test.operator, """
        exp.operator is not '\(test.operator)'. got=\(exp.operator)
        """)
      testLiteralExpression(exp.right, test.value)
    }
  }

  func testParsingInfixExpressions() {
    struct Test {
      let input     : String
      let leftVal   : Any
      let `operator`: String
      let rightVal  : Any
    }
    let tests = [
      Test(input: "5+5;"          , leftVal: 5    , operator: "+" , rightVal:     5),
      Test(input: "5-5;"          , leftVal: 5    , operator: "-" , rightVal:     5),
      Test(input: "5*5;"          , leftVal: 5    , operator: "*" , rightVal:     5),
      Test(input: "5/5;"          , leftVal: 5    , operator: "/" , rightVal:     5),
      Test(input: "5>5;"          , leftVal: 5    , operator: ">" , rightVal:     5),
      Test(input: "5<5;"          , leftVal: 5    , operator: "<" , rightVal:     5),
      Test(input: "5==5;"         , leftVal: 5    , operator: "==", rightVal:     5),
      Test(input: "5!=5;"         , leftVal: 5    , operator: "!=", rightVal:     5),
      Test(input: "foo + bar;"    , leftVal: "foo", operator: "+" , rightVal: "bar"),
      Test(input: "foo - bar;"    , leftVal: "foo", operator: "-" , rightVal: "bar"),
      Test(input: "foo * bar;"    , leftVal: "foo", operator: "*" , rightVal: "bar"),
      Test(input: "foo / bar;"    , leftVal: "foo", operator: "/" , rightVal: "bar"),
      Test(input: "foo > bar;"    , leftVal: "foo", operator: ">" , rightVal: "bar"),
      Test(input: "foo < bar;"    , leftVal: "foo", operator: "<" , rightVal: "bar"),
      Test(input: "foo == bar;"   , leftVal: "foo", operator: "==", rightVal: "bar"),
      Test(input: "foo != bar;"   , leftVal: "foo", operator: "!=", rightVal: "bar"),
      Test(input: "true == true"  , leftVal: true , operator: "==", rightVal: true ),
      Test(input: "true != false" , leftVal: true , operator: "!=", rightVal: false),
      Test(input: "false == false", leftVal: false, operator: "==", rightVal: false),
    ]
    for test in tests {
      parser      = Parser(test.input)
      let program = parser.parseProgram()
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
      testInfixExpression(exp, test.leftVal, test.operator, test.rightVal)
    }
  }

  private func testInfixExpression(_ exp: Expression, _ left: Any, _ operator: String, _ right: Any) {
    guard let opExp = exp as? InfixExpression else {
      XCTFail("exp is not OperatorExpression. got=\(type(of: exp))(\(exp))")
      return
    }
    testLiteralExpression(opExp.left, left)
    XCTAssertEqual(opExp.operator, `operator`, """
      exp.operator is not '\(`operator`)'. got=\(opExp.operator)
      """)
    testLiteralExpression(opExp.right, right)
  }

  func testOperatorPrecedenceParsing() {
    struct Test {
      let input   : String
      let expected: String
    }
    let tests = [
      Test(input: "-a * b"                     , expected: "((-a) * b)"),
      Test(input: "!-a"                        , expected: "(!(-a))"),
      Test(input: "a + b + c"                  , expected: "((a + b) + c)"),
      Test(input: "a + b - c"                  , expected: "((a + b) - c)"),
      Test(input: "a * b * c"                  , expected: "((a * b) * c)"),
      Test(input: "a * b / c"                  , expected: "((a * b) / c)"),
      Test(input: "a + b / c"                  , expected: "(a + (b / c))"),
      Test(input: "a + b * c + d / e - f"      , expected: "(((a + (b * c)) + (d / e)) - f)"),
      Test(input: "3 + 4; -5 * 5"              , expected: "(3 + 4)((-5) * 5)"),
      Test(input: "5 > 4 == 3 < 4"             , expected: "((5 > 4) == (3 < 4))"),
      Test(input: "5 < 4 != 3 > 4"             , expected: "((5 < 4) != (3 > 4))"),
      Test(input: "3 + 4 * 5 == 3 * 1 + 4 * 5" , expected: "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"),
      Test(input: "3 + 4 * 5 == 3 * 1 + 4 * 5" , expected: "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"),
      Test(input: "true"                       , expected: "true" ),
      Test(input: "false"                      , expected: "false"),
      Test(input: "3 > 5 == false"             , expected: "((3 > 5) == false)" ),
      Test(input: "3 < 5 == true"              , expected: "((3 < 5) == true)"  ),
      Test(input: "1 + (2 + 3) + 4"            , expected: "((1 + (2 + 3)) + 4)"),
      Test(input: "(5 + 5) * 2"                , expected: "((5 + 5) * 2)"),
      Test(input: "2 / (5 + 5)"                , expected: "(2 / (5 + 5))"),
      Test(input: "(5 + 5) * 2 * (5 + 5)"      , expected: "(((5 + 5) * 2) * (5 + 5))"),
      Test(input: "-(5 + 5)"                   , expected: "(-(5 + 5))"),
      Test(input: "!(true == true)"            , expected: "(!(true == true))"),
      Test(input: "a + add(b * c) + d"         , expected: "((a + add((b * c))) + d)"),
      Test(input: "add(a + b + c * d / f + g)" , expected: "add((((a + b) + ((c * d) / f)) + g))"),
      Test(input: "a * [1, 2, 3, 4][b * c] * d", expected: "((a * ([1, 2, 3, 4][(b * c)])) * d)"),
      Test(
        input   : "add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))",
        expected: "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"
      ),
      Test(
        input   : "add(a * b[2], b[1], 2 * [1, 2][1])",
        expected: "add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))"
      )
    ]
    for test in tests {
      parser      = Parser(test.input)
      let program = parser.parseProgram()
      let actual = program.asString()
      XCTAssertEqual(actual, test.expected, "expected=\(test.expected), got=\(actual)")
    }
  }

  func testBooleanExpression() {
    struct Test {
      let input: String
      let expected: Bool
    }
    let tests = [
      Test(input: "true;" , expected: true ),
      Test(input: "false;", expected: false)
    ]
    for test in tests {
      parser      = Parser(test.input)
      let program = parser.parseProgram()
      XCTAssertEqual(program.statements.count, 1, """
        program has not enough statements. got=\(program.statements.count)
        """)
      guard let stmt = program.statements[0] as? ExpressionStatement else {
        XCTFail("""
          program.statements[0] is not ExpressionStatement. \
          got=\(type(of: program.statements[0]))
          """)
        return
      }
      guard let boolean = stmt.expression as? BooleanExpression else {
        XCTFail("exp not Boolean. got=\(type(of: stmt.expression))")
        return
      }
      XCTAssertEqual(boolean.value, test.expected, """
        boolean.value not \(test.expected). got=\(boolean.value)
        """)
    }
  }

  func testIfExpression() {
    parser      = Parser("if (x < y) { x }")
    let program = parser.parseProgram()
    XCTAssertEqual(program.statements.count, 1, """
      program does not contain 1 statement. got=\(program.statements.count)
      """)
    guard let stmt = program.statements[0] as? ExpressionStatement else {
      XCTFail("""
        program.statements[0] is not ExpressionStatement. \
        got=\(type(of: program.statements[0]))
        """)
      return
    }
    guard let exp = stmt.expression as? IfExpression else {
      XCTFail("stmt.expression is not IfExpression. got=\(type(of: stmt.expression))")
      return
    }
    testInfixExpression(exp.condition, "x", "<", "y")
    XCTAssertEqual(exp.consequence.statements.count, 1, """
      consequence is not 1 statements. got=\(exp.consequence.statements.count)
      """)
    guard let consequence = exp.consequence.statements[0] as? ExpressionStatement else {
      XCTFail("""
        consequece.statements[0] is not ExpressionStatement. \
        got=\(type(of: exp.consequence.statements[0]))
        """)
      return
    }
    testIdentifier(consequence.expression, "x")
    XCTAssertNil(exp.alternative, """
      exp.alternative.statements was no nil. got=\(String(describing: exp.alternative))
      """)
  }

  func testIfElseExpression() {
    parser      = Parser("if (x < y) { x } else { y }")
    let program = parser.parseProgram()
    XCTAssertEqual(program.statements.count, 1, """
      program does not contain 1 statement. got=\(program.statements.count)
      """)
    guard let stmt = program.statements[0] as? ExpressionStatement else {
      XCTFail("""
        program.statements[0] is not ExpressionStatement. \
        got=\(type(of: program.statements[0]))
        """)
      return
    }
    guard let exp = stmt.expression as? IfExpression else {
      XCTFail("stmt.expression is not IfExpression. got=\(type(of: stmt.expression))")
      return
    }
    testInfixExpression(exp.condition, "x", "<", "y")
    XCTAssertEqual(exp.consequence.statements.count, 1, """
      consequence is not 1 statements. got=\(exp.consequence.statements.count)
      """)
    guard let consequence = exp.consequence.statements[0] as? ExpressionStatement else {
      XCTFail("""
        consequece.statements[0] is not ExpressionStatement. \
        got=\(type(of: exp.consequence.statements[0]))
        """)
      return
    }
    testIdentifier(consequence.expression, "x")
    XCTAssertEqual(exp.alternative!.statements.count, 1, """
      alternative is not 1 statements. got=\(exp.alternative!.statements.count)
      """)
    guard let alternative = exp.alternative!.statements[0] as? ExpressionStatement else {
      XCTFail("""
        alternative.statements[0] is not ExpressionStatement. \
        got=\(type(of: exp.alternative!.statements[0]))
        """)
      return
    }
    testIdentifier(alternative.expression, "y")
  }

  func testFunctionLiteralParsing() {
    parser      = Parser("fn(x, y) { x + y }")
    let program = parser.parseProgram()
    XCTAssertEqual(program.statements.count, 1, """
      program does not contain 1 statement. got=\(program.statements.count)
      """)
    guard let stmt = program.statements[0] as? ExpressionStatement else {
      XCTFail("""
        program.statements[0] is not ExpressionStatement. \
        got=\(type(of: program.statements[0]))
        """)
      return
    }
    guard let function = stmt.expression as? FunctionLiteral else {
      XCTFail("stmt.expression is not FunctionLiteral. got=\(type(of: stmt.expression))")
      return
    }
    XCTAssertEqual(function.parameters.count, 2, """
      function literal params are not 2. got=\(function.parameters.count)
      """)
    testLiteralExpression(function.parameters[0], "x")
    testLiteralExpression(function.parameters[1], "y")
    XCTAssertEqual(function.body.statements.count, 1, """
      function.body.statements has not 1 statement. got=\(function.body.statements.count)
      """)
    guard let bodyStmt = function.body.statements[0] as? ExpressionStatement else {
      XCTFail("""
        function body stmt is not ExpressionStatement. \
        got=\(type(of: function.body.statements[0]))
        """)
      return
    }
    testInfixExpression(bodyStmt.expression, "x", "+", "y")
  }

  func testFunctionParameterParsing() {
    struct Test {
      let input        : String
      let expecedParams: [String]
    }
    let tests = [
      Test(input: "fn() {};"        , expecedParams: []             ),
      Test(input: "fn(x) {};"       , expecedParams: ["x"]          ),
      Test(input: "fn (x, y, z) {};", expecedParams: ["x", "y", "z"])
    ]
    for test in tests {
      parser      = Parser(test.input)
      let program = parser.parseProgram()
      let stmt = program.statements[0] as! ExpressionStatement
      let function = stmt.expression as! FunctionLiteral
      XCTAssertEqual(function.parameters.count, test.expecedParams.count, """
        length parameters wrong. want \(test.expecedParams.count), \
        got=\(function.parameters.count)
        """)
      for (i, ident) in test.expecedParams.enumerated() {
        testLiteralExpression(function.parameters[i], ident)
      }
    }
  }

  func testCallExpressionParsing() {
    parser      = Parser("add(1, 2 * 3, 4 + 5);")
    let program = parser.parseProgram()
    XCTAssertEqual(program.statements.count, 1, """
      program does not contain 1 statement. got=\(program.statements.count)
      """)
    guard let stmt = program.statements[0] as? ExpressionStatement else {
      XCTFail("""
        program.statements[0] is not ExpressionStatement. \
        got=\(type(of: program.statements[0]))
        """)
      return
    }
    guard let exp = stmt.expression as? CallExpression else {
      XCTFail("stmt.expression is not CallExpression. got=\(type(of: stmt.expression))")
      return
    }
    testIdentifier(exp.function, "add")
    XCTAssertEqual(exp.arguments.count, 3, "wrong length of arguments. got=\(exp.arguments.count)")
    testLiteralExpression(exp.arguments[0], 1)
    testInfixExpression(exp.arguments[1], 2, "*", 3)
    testInfixExpression(exp.arguments[2], 4, "+", 5)
  }

  func testCallExpressionParameterParsing() {
    struct Test {
      let input        : String
      let expectedIdent: String
      let expectedArgs : [String]
    }
    let tests = [
      Test(input: "add();"               , expectedIdent: "add", expectedArgs: []),
      Test(input: "add(1);"              , expectedIdent: "add", expectedArgs: ["1"]),
      Test(input: "add(1, 2 * 3, 4 + 5);", expectedIdent: "add", expectedArgs: ["1", "(2 * 3)", "(4 + 5)"])
    ]
    for test in tests {
      parser      = Parser(test.input)
      let program = parser.parseProgram()
      let stmt    = program.statements[0] as! ExpressionStatement
      guard let exp = stmt.expression as? CallExpression else {
        XCTFail("stmt.expression is not CallExpression. got=\(type(of: stmt.expression))")
        return
      }
      testIdentifier(exp.function       , test.expectedIdent)
      XCTAssertEqual(exp.arguments.count, test.expectedArgs.count, """
        wrong number of arguments. want=\(test.expectedArgs.count), got=\(exp.arguments.count)
        """)
      for (i, arg) in test.expectedArgs.enumerated() {
        continueAfterFailure = true
        XCTAssertEqual(exp.arguments[i].asString(), arg, """
          argument \(i) wrong. want=\(arg), got=\(exp.arguments[i].asString())
          """)
      }
    }
  }

  func testStringLiteralExpression() {
    parser      = Parser("\"hello world\"")
    let program = parser.parseProgram()
    let stmt = program.statements[0] as! ExpressionStatement
    guard let literal = stmt.expression as? StringLiteral else {
      XCTFail("exp not StringLiteral. got=\(type(of: stmt.expression))")
      return
    }
    XCTAssertEqual(literal.value, "hello world", "literal.value not hello world. got=\(literal.value)")
  }

  func testParsingArrayLiterals() {
    parser      = Parser("[1, 2*2, 3+3];")
    let program = parser.parseProgram()
    let stmt = program.statements[0] as! ExpressionStatement
    guard let array = stmt.expression as? ArrayLiteral else {
      XCTFail("exp not ast.ArrayLiteral. got=\(type(of: stmt.expression))")
      return
    }
    XCTAssertEqual(array.elements.count, 3, "array.elements.count not 3. got=\(array.elements.count)")
    testIntegerLiteral(array.elements[0], 1)
    testInfixExpression(array.elements[1], 2, "*", 2)
    testInfixExpression(array.elements[2], 3, "+", 3)
  }

  func testParsingIndexExpressions() {
    parser      = Parser("myArray[1 + 1]")
    let program = parser.parseProgram()
    let stmt    = program.statements[0] as! ExpressionStatement
    guard let indexExp = stmt.expression as? IndexExpression else {
      XCTFail("exp not IndexExpression. got=\(type(of: stmt.expression))")
      return
    }
    testIdentifier(indexExp.left, "myArray")
    testInfixExpression(indexExp.index, 1, "+", 1)
  }

  func testParsingHashLiteralsStringKeys() {
    parser      = Parser(#"{"one": 1, "two": 2, "three": 3}"#)
    let program = parser.parseProgram()
    let stmt    = program.statements[0] as! ExpressionStatement
    guard let hash = stmt.expression as? HashLiteral else { 
      XCTFail("exp not HashLiteral. got=\(type(of: stmt.expression))")
      return
    }
    XCTAssertEqual(hash.store.count, 3, "hash.store has wrong length. got=\(hash.store.count)")
    let expected = [
      "one"  : 1,
      "two"  : 2,
      "three": 3
    ]
    for (key, value) in hash.store {
      guard let literal = key as? StringLiteral else {
        XCTFail("key is not ast.StringLiteral. got=\(type(of: key))")
        return
      }
      let expectedValue = expected[literal.asString()]!
      testIntegerLiteral(value, Int64(expectedValue))
    }
  }

  func testParsingEmptyHashLiteral() {
    parser      = Parser("{}")
    let program = parser.parseProgram()
    let stmt    = program.statements[0] as! ExpressionStatement
    guard let hash = stmt.expression as? HashLiteral else { 
      XCTFail("exp not HashLiteral. got=\(type(of: stmt.expression))")
      return
    }
    XCTAssertEqual(hash.store.count, 0, "hash.store has wrong length. got=\(hash.store.count)")
  }

  func testParsingHashLiteralsWithExpressions() {
    parser      = Parser(#"{"one": 0 + 1, "two": 10 - 8, "three": 15 / 5}"#)
    let program = parser.parseProgram()
    let stmt    = program.statements[0] as! ExpressionStatement
    guard let hash = stmt.expression as? HashLiteral else { 
      XCTFail("exp not HashLiteral. got=\(type(of: stmt.expression))")
      return
    }
    XCTAssertEqual(hash.store.count, 3, "hash.store has wrong length. got=\(hash.store.count)")
    let tests = [
      "one"  : { (exp: Expression) in self.testInfixExpression(exp,  0, "+", 1) },
      "two"  : { (exp: Expression) in self.testInfixExpression(exp, 10, "-", 8) },
      "three": { (exp: Expression) in self.testInfixExpression(exp, 15, "/", 5) }
    ]
    for (key, value) in hash.store {
      guard let literal = key as? StringLiteral else {
        XCTFail("key is not ast.StringLiteral. got=\(type(of: key))")
        return
      }
      guard let testFunc = tests[literal.asString()] else {
        XCTFail("No test function for key \(literal.asString()) found")
        return
      }
      testFunc(value)
    }
  }

  private func testLiteralExpression(_ exp: Expression, _ expected: Any) {
    if let intVal = expected as? Int {
      testIntegerLiteral(exp, Int64(intVal))
    } else if let int64Val = expected as? Int64 {
      testIntegerLiteral(exp, int64Val)
    } else if let stringVal = expected as? String {
      testIdentifier(exp, stringVal)
    } else if let boolVal = expected as? Bool {
      testBooleanLiteral(exp, boolVal)
    } else {
      XCTFail("type of exp not handled. got=\(type(of: expected))")
    }
  }

  private func testIntegerLiteral(_ exp: Expression?, _ value: Int64) {
    XCTAssertNotNil(exp, "exp is nil")
    guard let integer = exp! as? IntegerLiteral else {
      XCTFail("exp not IntegerLiteral. got=\(type(of: exp!))")
      return
    }
    XCTAssertEqual(integer.value, value, "integer.value not \(value). got=\(integer.value)")
    XCTAssertEqual(integer.tokenLiteral(), "\(value)", """
      integer.tokenLiteral not \(value). got=\(integer.tokenLiteral())
      """)
  }

  private func testIdentifier(_ exp: Expression, _ value: String) {
    guard let ident = exp as? Identifier else {
      XCTFail("exp not Identifier. got=\(type(of: exp))")
      return
    }
    XCTAssertEqual(ident.value, value, "ident.value not \(value). got=\(ident.value)")
    XCTAssertEqual(ident.tokenLiteral(), value, """
      ident.tokenLiteral not \(value). got=\(ident.tokenLiteral())
      """)
  }

  private func testBooleanLiteral(_ exp: Expression, _ value: Bool) {
    guard let bool = exp as? BooleanExpression else {
      XCTFail("exp not BooleanExpression. got=\(type(of: exp))")
      return
    }
    XCTAssertEqual(bool.value, value, "bool.value not \(value). got=\(bool.value)")
    XCTAssertEqual(bool.tokenLiteral(), "\(value)", """
      bool.tokenLiteral not \(value). got=\(bool.tokenLiteral())
      """)
  }
}
