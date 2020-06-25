//===-- AST ---------------------------------------------------*- Swift -*-===//
//
// This file implements the abstract syntax tree that the parser in going to
// build.
// 
//===----------------------------------------------------------------------===//

// Every node in our AST has to implement the Node protocol, meaning it has
// to provide a tokenLiteral() method.
//
public protocol Node {
  // will be used only for debugging and testing.
  // returns the literal value of the token it’s associated with.
  //
  func tokenLiteral() -> String    // maybe should be a computed property

  // With this in place, we can now just call asString() on a Program and get
  // our whole program back as a string.
  // That makes the structure of Program easily testable.
  //
  func asString() -> String        // this one too?
}

protocol TokenNode: Node {
  var token: Token { get }
}

extension TokenNode {
  func tokenLiteral() -> String { token.literal }
}

// not strictly necessary but help us by guiding the compiler and possibly
// causing it to throw errors when we use a Statement where an Expression
// should’ve been used, and vice versa.
//
protocol Statement : TokenNode {}
protocol Expression: TokenNode {}

// The argument is “left side” of the infix operator that’s being parsed.
//
typealias InfixParseFn = (_ e: Expression) throws -> Expression

// A prefix operator doesn’t have a “left side”, per definition.
//
typealias PrefixParseFn = () throws -> Expression

// This Program node is going to be the root node of every AST our parser
// produces.
//
public struct Program: Node {
  // Every valid Monkey program is a series of statements.
  // Here we stores the statements of a program.
  //
  var statements: [Statement] = []

  public func tokenLiteral() -> String {
    statements.count > 0 ? statements[0].tokenLiteral() : ""
  }

  public func asString() -> String {
    var buffer = ""
    for statement in statements {
      buffer += statement.asString()
    }
    return buffer
  }
}

struct LetStatement: Statement {
  let token: Token          // .let token
  var name : Identifier     // holds the identifier of the binding
  var value: Expression?    // for the expression that produces the value

  func asString() -> String {
    var buffer = ""
    buffer += tokenLiteral() + " "
    buffer += name.asString()
    buffer += " = "

    if value != nil {
      buffer += value!.asString()
    }

    buffer += ";"
    return buffer
  }
}

struct Identifier: Expression {
  let token: Token          // .ident token
  var value: String

  func asString() -> String { value }
}

struct ReturnStatement: Statement {
  let token      : Token    // .let token
  var returnValue: Expression?

  func asString() -> String {
    var buffer = ""
    buffer += tokenLiteral() + " "

    if returnValue != nil {
      buffer += returnValue!.asString()
    }

    buffer += ";"
    return buffer
  }
}

struct ExpressionStatement: Statement {
  let token     : Token     // The first token of the expression
  let expression: Expression?

  func asString() -> String {
    expression != nil ? expression!.asString() : ""
  }
}

struct IntegerLiteral: Expression {
  let token: Token

  // contains the actual value the integer literal represents in the source
  // code.
  //
  let value: Int64

  func asString() -> String { token.literal }
}

struct PrefixExpression: Expression {
  let token     : Token        // The prefix token
  let `operator`: String       // contains either "-" or "!"
  let right     : Expression?  // the expression to the right of the operator.

  func asString() -> String {
    var buffer = ""
    buffer += "("
    buffer += `operator`
    buffer += right!.asString()
    buffer += ")"
    return buffer
  }
}

struct InfixExpression: Expression {
  let token     : Token
  let left      : Expression
  let `operator`: String
  let right     : Expression?

  func asString() -> String {
    var buffer = ""
    buffer += "("
    buffer += left.asString()
    buffer += " " + `operator` + " "
    buffer += right!.asString()
    buffer += ")"
    return buffer
  }
}

struct BooleanExpression: Expression {
  let token: Token
  let value: Bool

  func asString() -> String { token.literal }
}

struct IfExpression: Expression {
  let token      : Token
  let condition  : Expression
  let consequence: BlockStatement
  let alternative: BlockStatement?

  func asString() -> String {
    var buffer = ""
    buffer += "if"
    buffer += condition.asString()
    buffer += " "
    buffer += consequence.asString()
    if alternative != nil {
      buffer += "else "
      buffer += alternative!.asString()
    }
    return buffer
  }
}

struct BlockStatement: Statement {
  let token     : Token         // the { token
  var statements: [Statement] = []

  func asString() -> String {
    var buffer = ""
    for s in statements {
      buffer += s.asString()
    }
    return buffer
  }
}

struct FunctionLiteral: Expression {
  let token     : Token
  let parameters: [Identifier]
  let body      : BlockStatement

  func asString() -> String {
    var buffer = ""
    var params: [String] = []
    for param in parameters {
      params.append(param.asString())
    }
    buffer += tokenLiteral()
    buffer += "("
    buffer += params.joined(separator: ", ")
    buffer += ")"
    buffer += body.asString()
    return buffer
  }
}

struct CallExpression: Expression {
  let token    : Token
  var arguments: [Expression] = []
  let function : Expression

  func asString() -> String {
    var buffer = ""
    var args: [String] = []
    for arg in arguments {
      args.append(arg.asString())
    }
    buffer += function.asString()
    buffer += "("
    buffer += args.joined(separator: ", ")
    buffer += ")"
    return buffer
  }
}
