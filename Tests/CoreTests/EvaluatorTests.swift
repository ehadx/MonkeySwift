import XCTest
@testable import Core

final class EvaluatorTests : XCTestCase {
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
        testNullObject(evaluated!)
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
      Test(input: "5 + true"                     , expected: "type mismatch: integer + boolean"   ),
      Test(input: "5 + true; 5;"                 , expected: "type mismatch: integer + boolean"   ),
      Test(input: "-true"                        , expected: "unknown operator: -boolean"         ),
      Test(input: "true + false"                 , expected: "unknown operator: boolean + boolean"),
      Test(input: "5; true + false; 5"           , expected: "unknown operator: boolean + boolean"),
      Test(input: "if (10 > 1) { true + false; }", expected: "unknown operator: boolean + boolean"),
      Test(input: "foobar"                       , expected: "identifier foobar not found!"       ),
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

  private func testEval(_ input: String) -> Object? {
    let parser  = Parser(input)
    let program = parser.parseProgram()
    var env     = Enviroment()
    return eval(program, &env)
  }

  private func testIntegerObject(_ obj: Object?, _ expected: Int64) {
    guard let result = obj as? Integer else {
      XCTFail("object is not Integer. got=\(type(of: obj)) (\(String(describing: obj)))")
      return
    }
    XCTAssertEqual(result.value, expected, """
      object has wrong value. got=\(result.value), want=\(expected)
      """)
  }

  private func testBooleanObject(_ obj: Object?, _ expected: Bool) {
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
}
