import XCTest
@testable import Core

final class ASTTests: XCTestCase {
  func testAsString() {
    let program = Program(
      statements: [
        LetStatement(
          token:                   Token(keyword:        "let")!,
          name : Identifier(token: Token(ident  :      "myVar") , value:      "myVar"),
          value: Identifier(token: Token(ident  : "anotherVar") , value: "anotherVar")
        )
      ]
    )
    XCTAssertEqual(program.asString(), "let myVar = anotherVar;", """
      program.asString() wrong. got=\(program.asString())
      """
    )
  }

  func testModify() {
    let token = Token(number: "1")    // dummy token
    let one   = { () -> Expression in IntegerLiteral(token: token, value: 1) }
    let two   = { () -> Expression in IntegerLiteral(token: token, value: 2) }
    let turnOneIntoTwo = { (_ node: Node) -> Node in
      guard var int = node as? IntegerLiteral, int.value == 1 else {
        return node
      }
      int.value = 2
      return int
    }
    struct Test {
      let input   : Node
      let expected: Node
    }
    let tests = [
      Test(input   : one(),
           expected: two()
      ),
      Test(input   : Program(statements: [ExpressionStatement(token: token, expression: one())]),
           expected: Program(statements: [ExpressionStatement(token: token, expression: two())])
      ),
      Test(input   : InfixExpression(token: token, left: one(), operator: "+", right: two()),
           expected: InfixExpression(token: token, left: two(), operator: "+", right: two())
      ),
      Test(input   : InfixExpression(token: token, left: two(), operator: "+", right: one()),
           expected: InfixExpression(token: token, left: two(), operator: "+", right: two())
      ),
      Test(input   : IndexExpression(token: token, left: one(), index: one()),
           expected: IndexExpression(token: token, left: two(), index: two())
      ),
      Test(
        input:
          IfExpression(
            token      : token,
            condition  : one(),
            consequence: BlockStatement(
              token: token, statements: [ExpressionStatement(token: token, expression: one())]
            ),
            alternative: BlockStatement(
              token: token, statements: [ExpressionStatement(token: token, expression: one())]
            )
          ),
        expected:
          IfExpression(
            token      : token,
            condition  : two(),
            consequence: BlockStatement(
              token: token, statements: [ExpressionStatement(token: token, expression: two())]
            ),
            alternative: BlockStatement(
              token: token, statements: [ExpressionStatement(token: token, expression: two())]
            )
          )
      ),
      Test(input   : ReturnStatement(token: token, returnValue: one()),
           expected: ReturnStatement(token: token, returnValue: two())
      ),
      Test(input   : LetStatement(token: token, name: Identifier(token: token, value: "n"), value: one()),
           expected: LetStatement(token: token, name: Identifier(token: token, value: "n"), value: two())
      ),
      Test(
        input   : FunctionLiteral(token: token, parameters: [], body: BlockStatement(
          token: token, statements: [ExpressionStatement(token: token, expression: one())]
        )),
        expected: FunctionLiteral(token: token, parameters: [], body: BlockStatement(
          token: token, statements: [ExpressionStatement(token: token, expression: two())]
        ))
      ),
      Test(input   : ArrayLiteral(token: token, elements: [one(), one()]),
           expected: ArrayLiteral(token: token, elements: [two(), two()])
      ),
      Test(input   : HashLiteral(token: token, store: [one() as! AnyHashable : one()]),
           expected: HashLiteral(token: token, store: [two() as! AnyHashable : two()])
      )
    ]
    for test in tests {
      let modified = modify(test.input, turnOneIntoTwo)
      switch modified {
      case let m as IntegerLiteral:
        XCTAssertEqual(m, test.expected as! IntegerLiteral, """
          not equal. got=\(String(describing: m)), want=\(String(describing: test.expected))
          """)
      case let m as Program:
        XCTAssertEqual(m, test.expected as! Program, """
          not equal. got=\(String(describing: m)), want=\(String(describing: test.expected))
          """)
      default:
        return
      }
    }
  }
}
