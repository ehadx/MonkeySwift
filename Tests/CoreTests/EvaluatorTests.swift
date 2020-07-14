import XCTest
@testable import Core

final class EvaluatorTests: XCTestCase {
  override func setUp() {
    super.setUp()
    continueAfterFailure = false
  }

  func testEvalIntegerExpression() {
    struct Test {
      let input   : String
      let expected: Int64
    }
    let tests = [
      Test(input: "5"                              , expected:   5),
      Test(input: "10 "                            , expected:  10),
      Test(input: "-5 "                            , expected:  -5),
      Test(input: "-10"                            , expected: -10),
      Test(input: "5 + 5 + 5 + 5 - 10"             , expected:  10),
      Test(input: "2 * 2 * 2 * 2 * 2"              , expected:  32),
      Test(input: "-50 + 100 + -50"                , expected:   0),
      Test(input: "5 * 2 + 10"                     , expected:  20),
      Test(input: "5 + 2 * 10"                     , expected:  25),
      Test(input: "20 + 2 * -10"                   , expected:   0),
      Test(input: "50 / 2 * 2 + 10"                , expected:  60),
      Test(input: "2 * (5 + 10)"                   , expected:  30),
      Test(input: "3 * 3 * 3 + 10"                 , expected:  37),
      Test(input: "3 * (3 * 3) + 10"               , expected:  37),
      Test(input: "(5 + 10 * 2 + 15 / 3) * 2 + -10", expected:  50),
    ]
    for test in tests {
      let evaluated = testEval(test.input)
      testIntegerObject(evaluated, test.expected)
    }
  }

  func testEvalBooleanExpression() {
    struct Test {
      let input   : String
      let expected: Bool
    }
    let tests = [
      Test(input: "true"            , expected:  true),
      Test(input: "false"           , expected: false),
      Test(input: "1 < 2"           , expected:  true),
      Test(input: "1 > 2"           , expected: false),
      Test(input: "1 > 1"           , expected: false),
      Test(input: "1 == 1"          , expected:  true),
      Test(input: "1 != 1"          , expected: false),
      Test(input: "1 != 2"          , expected:  true),
      Test(input: "true == true"    , expected:  true),
      Test(input: "false == false"  , expected:  true),
      Test(input: "true == false"   , expected: false),
      Test(input: "true != false"   , expected:  true),
      Test(input: "false != true"   , expected:  true),
      Test(input: "(1 < 2) == true" , expected:  true),
      Test(input: "(1 < 2) == false", expected: false),
      Test(input: "(1 > 2) == true" , expected: false),
      Test(input: "(1 > 2) == false", expected:  true),
    ]
    for test in tests {
      let evaluated = testEval(test.input)
      testBooleanObject(evaluated, test.expected)
    }
  }
  
  func testBangOperator() {
    struct Test {
      let input   : String
      let expected: Bool
    }
    let tests = [
      Test(input: "!true"  , expected: false),
      Test(input: "!false" , expected:  true),
      Test(input: "!5"     , expected: false),
      Test(input: "!!true" , expected:  true),
      Test(input: "!!false", expected: false),
      Test(input: "!!5"    , expected:  true)
    ]
    for test in tests {
      let evaluated = testEval(test.input)
      testBooleanObject(evaluated, test.expected)
    } 
  }

  func testIfElseExpression() {
    struct Test {
      let input   : String
      let expected: Any
    }
    let tests = [
      Test(input: "if (true) { 10 }"             , expected:     10),
      Test(input: "if (false) { 10 }"            , expected: Null()),
      Test(input: "if (1) { 10 }"                , expected:     10),
      Test(input: "if (1 < 2) { 10 }"            , expected:     10),
      Test(input: "if (1 > 2) { 10 }"            , expected: Null()),
      Test(input: "if (1 > 2) { 10 } else { 20 }", expected:     20),
      Test(input: "if (1 < 2) { 10 } else { 20 }", expected:     10),
    ]
    for test in tests {
      let evaluated = testEval(test.input)
      if let integer = test.expected as? Int {
        testIntegerObject(evaluated, Int64(integer))
      } else {
        testNullObject(evaluated)
      }
    }
  }

  func testReturnStatements() {
    struct Test {
      let input   : String
      let expected: Int64
    }
    let tests = [
      Test(input: "return 10;"         , expected: 10),
      Test(input: "return 10; 9;"      , expected: 10),
      Test(input: "return 2 * 5; 9;"   , expected: 10),
      Test(input: "9; return 2 * 5; 9;", expected: 10),
      Test(input: """
        if (10 > 1) {
          if (10 > 1) {
            return 10;
          }
          return 1;
        }
      """, expected: 10)
    ]
    for test in tests {
      let evaluated = testEval(test.input)
      testIntegerObject(evaluated, test.expected)
    }
  }

  func testErrorHandling() {
    struct Test {
      let input   : String
      let expected: String
    }
    let tests = [
      Test(input: "5 + true"                          , expected: "type mismatch: integer + boolean"   ),
      Test(input: "5 + true; 5;"                      , expected: "type mismatch: integer + boolean"   ),
      Test(input: "-true"                             , expected: "unknown operator: -boolean"         ),
      Test(input: "true + false"                      , expected: "unknown operator: boolean + boolean"),
      Test(input: "5; true + false; 5"                , expected: "unknown operator: boolean + boolean"),
      Test(input: "if (10 > 1) { true + false; }"     , expected: "unknown operator: boolean + boolean"),
      Test(input: "\"Hello\" - \"World\""             , expected: "unknown operator: string - string"  ),
      Test(input: "foobar"                            , expected: "identifier foobar not found!"       ),
      Test(input: #"{"name": "Monkey"}[fn(x) { x }];"#, expected: "unusable as hash key: Function"     ),
      Test(input: """
        if (10 > 1) {
          if (10 > 1) {
            return true + false;
          }
          return 1;
        }
      """, expected: "unknown operator: boolean + boolean"),
    ]
    for test in tests {
      let evaluated = testEval(test.input)
      guard let errObj = evaluated as? ErrorObj else {
        XCTFail("""
          no error object returned. \
          got=\(type(of: evaluated))(\(String(describing: evaluated)))
          """)
        continue
      }
      XCTAssertEqual(errObj.message, test.expected, """
        wrong error message. expected=\(test.expected), got=\(errObj.message)
        """)
    }
  }

  func testLetStatements() {
    struct Test {
      let input   : String
      let expected: Int64
    }
    let tests = [
      Test(input: "let a = 5; a;"                              , expected:  5),
      Test(input: "let a = 5 * 5; a;"                          , expected: 25),
      Test(input: "let a = 5; let b = a; b;"                   , expected:  5),
      Test(input: "let a = 5; let b = a; let c = a + b + 5; c;", expected: 15),
    ]
    for test in tests {
      testIntegerObject(testEval(test.input), test.expected)
    }
  }

  func testFunctionObject() {
    let evaluated = testEval("fn (x) { x + 2; };")
    guard let fn = evaluated as? Function else {
      XCTFail("object is not Function. got=\(type(of: evaluated)) (\(String(describing: evaluated)))")
      return
    }
    XCTAssertEqual(fn.parameters.count, 1, "function has wrong parameters. Parameters=\(fn.parameters)")
    XCTAssertEqual(fn.parameters[0].asString(), "x", "parameter is not 'x'. got=\(fn.parameters[0])")
    XCTAssertEqual(fn.body.asString(), "(x + 2)", "body is not (x + 2). got=\(fn.body.asString())")
  }

  func testFunctionApplication() {
    struct Test {
      let input   : String
      let expected: Int64
    }
    let tests = [
      Test(input: "let identity = fn(x) { x; }; identity(5);"            , expected:  5),
      Test(input: "let identity = fn(x) { return x; }; identity(5);"     , expected:  5),
      Test(input: "let double = fn(x) { x * 2; }; double(5);"            , expected: 10),
      Test(input: "let add = fn(x, y) { x + y; }; add(5, 5);"            , expected: 10),
      Test(input: "let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", expected: 20),
      Test(input: "fn(x) { x; }(5)"                                      , expected:  5),
    ]
    for test in tests {
      testIntegerObject(testEval(test.input), test.expected)
    }
  }

  func testEnclosingEnviroments() {
    let evaluated = testEval("""
      let first = 10;
      let second = 10;
      let third = 10;
      let ourFunc = fn(first) {
        let second = 20;
        first + second + third;
      };

      ourFunc(20) + first + second;
    """)
    testIntegerObject(evaluated, 70)
  }

  func testStringLiteral() {
    let evaluated = testEval("\"Hello World!\"");
    guard let str = evaluated as? StringObj else {
      XCTFail("object is not String. got=\(type(of: evaluated)) (\(String(describing: evaluated)))")
      return
    }
    XCTAssertEqual(str.value, "Hello World!", "String has wrong value. got=\(str.value)")
  }

  func testStringConcatenation() {
    let evaluated = testEval("\"Hello\" + \" \" + \"World!\"")
    guard let str = evaluated as? StringObj else {
      XCTFail("object is not String. got=\(type(of: evaluated)) (\(String(describing: evaluated)))")
      return
    }
    XCTAssertEqual(str.value, "Hello World!", "String has wrong value. got=\(str.value)") 
  }

  func testBuiltinFunctions() {
    struct Test {
      let input   : String
      let expected: Any
    }
    let tests = [
      Test(input: "len(\"\")"            , expected:  0),
      Test(input: "len(\"four\")"        , expected:  4),
      Test(input: "len(\"hello world\")" , expected: 11),
      Test(input: "len(1)"               , expected: "argument to `len` not supported, got Integer"),
      Test(input: "len(\"one\", \"two\")", expected: "wrong number of arguments. got=2, want=1"    ),
    ]
    for test in tests {
      let evaluated = testEval(test.input)
      if let int = test.expected as? Int {
        testIntegerObject(evaluated, Int64(int))
      } else if let string = test.expected as? String {
        guard let error = evaluated as? ErrorObj else {
          XCTFail("object is not Error. got=\(type(of: evaluated)) (\(String(describing: evaluated)))")
          return
        }
        XCTAssertEqual(error.message, string, """
          wrong error message. expected=\(string), got=\(error.message)
          """)
      }
    }
  }

  func testArrayLiteral() {
    let evaluated = testEval("[1, 2 * 2, 3 + 3]")
    guard let result = evaluated as? ArrayObj else {
      XCTFail("object is not Array. got=\(type(of: evaluated)) (\(String(describing: evaluated)))")
      return
    }
    XCTAssertEqual(result.elements.count, 3, "array has wrong num of elements. got=\(result.elements.count)")
    testIntegerObject(result.elements[0], 1)
    testIntegerObject(result.elements[1], 4)
    testIntegerObject(result.elements[2], 6)
  }

  func testArrayIndexExpressions() {
    struct Test {
      let input   : String
      let expected: Any
    }
    let tests = [
      Test(input: "[1, 2, 3][0]"                                                  , expected:      1),
      Test(input: "[1, 2, 3][1]"                                                  , expected:      2),
      Test(input: "[1, 2, 3][2]"                                                  , expected:      3),
      Test(input: "let i = 0; [1][i];"                                            , expected:      1),
      Test(input: "[1, 2, 3][1 + 1]"                                              , expected:      3),
      Test(input: "let myArray = [1, 2, 3]; myArray[2]"                           , expected:      3),
      Test(input: "let myArray = [1, 2, 3]; myArray[0] + myArray[1] + myArray[2];", expected:      6),
      Test(input: "let myArray = [1, 2, 3]; let i = myArray[0]; myArray[i]"       , expected:      2),
      Test(input: "[1, 2, 3][3]"                                                  , expected: Null()),
      Test(input: "[1, 2, 3][-1]"                                                 , expected: Null()),
    ]
    for test in tests {
      let evaluated = testEval(test.input)
      guard let integer = evaluated as? Integer else {
        testNullObject(evaluated)
        return
      }
      testIntegerObject(integer, Int64(test.expected as! Int))
    }
  }

  func testHashLiteral() {
    let evaluated = testEval("""
      let two = "two";
      {
        "one": 10 - 9,
        two: 1 + 1,
        "thr" + "ee": 6 / 2, 4: 4,
        true: 5,
        false: 6
      } 
    """)
    guard let result = evaluated as? Hash else {
      XCTFail("Eval didn't return Hash. got=\(type(of: evaluated)) (\(String(describing: evaluated)))")
      return
    }
    let expected: [AnyHashable: Int64] = [
      StringObj(value:   "one"): 1,
      StringObj(value:   "two"): 2,
      StringObj(value: "three"): 3,
        Integer(value:       4): 4,
        Boolean(value:    true): 5,
        Boolean(value:   false): 6,
    ]
    XCTAssertEqual(result.store.count, expected.count, "Hash has wrong num of store. got=\(result.store.count)")
    for (expectedKey, expectedValue) in expected {
      guard let value = result.store[expectedKey] else {
        XCTFail("no value for given key in store")
        return
      }
      testIntegerObject(value, expectedValue)
    }
  }

  func testHashIndexExpressions() {
    struct Test {
      let input   : String
      let expected: Any
    }
    let tests = [
      Test(input: #"{"foo": 5}["foo"]"#               , expected:      5),
      Test(input: #"{"foo": 5}["bar"]"#               , expected: Null()),
      Test(input: #"let key = "foo"; {"foo": 5}[key]"#, expected:      5),
      Test(input: #"{}["foo"]"#                       , expected: Null()),
      Test(input: "{5: 5}[5]"                         , expected:      5),
      Test(input: "{true: 5}[true]"                   , expected:      5),
      Test(input: "{false: 5}[false]"                 , expected:      5),
    ]
    for test in tests {
      let evaluated = testEval(test.input)
      guard let int = evaluated as? Integer else {
        testNullObject(evaluated)
        return
      }
      testIntegerObject(int, Int64(test.expected as! Int))
    }
  }

  func testQuoteUnquote() {
    struct Test {
      let input   : String
      let expected: String
    }
    let tests = [
      Test(input: "quote(5)"                              , expected: "5"                ),
      Test(input: "quote(5 + 8) "                         , expected: "(5 + 8)"          ),
      Test(input: "quote(foobar)"                         , expected: "foobar"           ),
      Test(input: "quote(foobar + barfoo)"                , expected: "(foobar + barfoo)"),
      Test(input: "quote(unquote(4))"                     , expected: "4"                ),
      Test(input: "quote(unquote(4 + 4))"                 , expected: "8"                ),
      Test(input: "quote(8 + unquote(4 + 4))"             , expected: "(8 + 8)"          ),
      Test(input: "quote(unquote(4 + 4) + 8)"             , expected: "(8 + 8)"          ),
      Test(input: "let foobar = 8; quote(foobar)"         , expected: "foobar"           ),
      Test(input: "let foobar = 8; quote(unquote(foobar))", expected: "8"                ),
      Test(input: "quote(unquote(true))"                  , expected: "true"             ),
      Test(input: "quote(unquote(true == false))"         , expected: "false"            ),
      Test(input: "quote(unquote(quote(4 + 4)))"          , expected: "(4 + 4)"          ),
      Test(
        input: """
          let quotedInfixExpression = quote(4 + 4);
          quote(unquote(4 + 4) + unquote(quotedInfixExpression))
        """,
        expected: "(8 + (4 + 4))"
      )
    ]
    for test in tests {
      let evaluated = testEval(test.input)
      guard let quote = evaluated as? Quote else {
        XCTFail("expected Quote. got=\(type(of: evaluated)) (\(String(describing: evaluated)))")
        return
      }
      XCTAssertNotNil(quote.node, "quote.node is nil")
      XCTAssertEqual(quote.node.asString(), test.expected, """
        not equal. got=\(quote.node.asString()), want=\(test.expected)
        """)
    }
  }

  private func testEval(_ input: String) -> Object {
    let parser  = Parser(input)
    let program = parser.parseProgram()
    var env     = Enviroment()
    return eval(program, &env)
  }

  private func testIntegerObject(_ obj: Object, _ expected: Int64) {
    guard let result = obj as? Integer else {
      XCTFail("object is not Integer. got=\(type(of: obj)) (\(String(describing: obj)))")
      return
    }
    XCTAssertEqual(result.value, expected, """
      object has wrong value. got=\(result.value), want=\(expected)
      """)
  }

  private func testBooleanObject(_ obj: Object, _ expected: Bool) {
    guard let result = obj as? Boolean else {
      XCTFail("object is not Boolean. got=\(type(of: obj)) (\(String(describing: obj)))")
      return
    }
    XCTAssertEqual(result.value, expected, """
      object has wrong value. got=\(result.value), want=\(expected)
      """) 
  }

  private func testNullObject(_ obj: Object) {
    guard obj is Null else {
      XCTFail("obj is not Null. got=\(type(of: obj)) (\(obj))")
      return
    }
  }

  static var allTests = [
    ("testEvalIntegerExpression", testEvalIntegerExpression),
    ("testEvalBooleanExpression", testEvalBooleanExpression),
    ("testBangOperator"         , testBangOperator         ),
    ("testIfElseExpression"     , testIfElseExpression     ),
    ("testReturnStatements"     , testReturnStatements     ),
    ("testErrorHandling"        , testErrorHandling        ),
    ("testLetStatements"        , testLetStatements        ),
    ("testFunctionObject"       , testFunctionObject       ),
    ("testFunctionApplication"  , testFunctionApplication  ),
    ("testEnclosingEnviroments" , testEnclosingEnviroments ),
    ("testStringLiteral"        , testStringLiteral        ),
    ("testStringConcatenation"  , testStringConcatenation  ),
    ("testBuiltinFunctions"     , testBuiltinFunctions     ),
    ("testArrayLiteral"         , testArrayLiteral         ),
    ("testArrayIndexExpressions", testArrayIndexExpressions),
    ("testHashLiteral"          , testHashLiteral          ),
    ("testHashIndexExpressions" , testHashIndexExpressions ),
    ("testQuoteUnquote"         , testQuoteUnquote         ),
  ]
}
