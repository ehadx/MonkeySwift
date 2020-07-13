import XCTest
@testable import Core

final class MacroExpansionTests: XCTestCase {
  override func setUp() {
    super.setUp()
    continueAfterFailure = false
  }

  func testDefineMacros() {
    var program = testParseProgram("""
      let number = 1;
      let function = fn(x, y) { x + y };
      let mymacro = macro(x, y) { x + y; };
    """)
    var env = Enviroment()
    defineMacros(&program, &env)
    XCTAssertEqual(program.statements.count, 2, "Wrong number of statements. got=\(program.statements.count)")
    XCTAssertNil(env["number"  ], "number should not be defined")
    XCTAssertNil(env["function"], "function should not be defined")
    guard let obj = env["mymacro"] else {
      XCTFail("macro not in environment.")
      return
    }
    guard let macro = obj as? Macro else {
      XCTFail("object is not Macro. got=\(type(of: obj)) (\(String(describing: obj)))")
      return
    }
    XCTAssertEqual(macro.parameters.count, 2, "Wrong number of macro parameters. got=\(macro.parameters.count)")
    XCTAssertEqual(macro.parameters[0].asString(), "x", "parameter is not 'x'. got=\(macro.parameters[0].asString())")
    XCTAssertEqual(macro.parameters[1].asString(), "y", "parameter is not 'y'. got=\(macro.parameters[1].asString())")
    XCTAssertEqual(macro.body.asString(), "(x + y)", "body is not (x + y). got=\(macro.body.asString())")
  }

  func testExpandMacros() {
    let tests: [(input: String, expected: String)] = [
      (
        input: """
          let infixExpression = macro() { quote(1 + 2); };
          infixExpression();
        """,
        expected: "(1 + 2)"
      ),
      (
        input: """
          let reverse = macro(a, b) { quote(unquote(b) - unquote(a)); };
          reverse(2 + 2, 10 - 5);
        """,
        expected: "(10 - 5) - (2 + 2)"
      ),
      (
        input: """
          let unless = macro(condition, consequence, alternative) {
            quote(if (!(unquote(condition))) {
              unquote(consequence);
            } else {
              unquote(alternative);
            });
          };

          unless(10 > 5, puts("not greater"), puts("greater"));
        """,
        expected: #"if (!(10 > 5)) { puts("not greater") } else { puts("greater") }"#
      )
    ]
    for test in tests {
      let expected = testParseProgram(test.expected)
      var program  = testParseProgram(test.input)
      var env      = Enviroment()
      defineMacros(&program, &env)
      let expanded = expandMacros(program, &env)
      XCTAssertEqual(expanded.asString(), expected.asString(), """
        not equal. want=\(expanded.asString()), got=\(expected.asString())
        """)
    }
  }

  private func testParseProgram(_ input: String) -> Program {
    let parser = Parser(input)
    return parser.parseProgram()
  }
}
