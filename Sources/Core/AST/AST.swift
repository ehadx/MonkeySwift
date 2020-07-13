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

extension Node {
  public static func ==(lhs: Self, rhs: Self) -> Bool { lhs.asString() == rhs.asString() }
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

extension Expression {
  func hash(into: inout Hasher) {
    into.combine(asString())
  }
}

// This Program node is going to be the root node of every AST our parser
// produces.
//
public struct Program: Node, Equatable {
  // Every valid Monkey program is a series of statements.
  // Here we stores the statements of a program.
  //
  var statements: [Statement] = []
  public var count: Int { statements.count }

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

struct LetStatement: Statement, Equatable {
  let token: Token          // .let token
  var name : Identifier     // holds the identifier of the binding
  var value: Expression     // for the expression that produces the value

  func asString() -> String {
    var buffer = ""
    buffer += tokenLiteral() + " "
    buffer += name.asString()
    buffer += " = "
    buffer += value.asString()
    buffer += ";"
    return buffer
  }
}

struct Identifier: Expression, Hashable {
  let token: Token          // .ident token
  var value: String

  func asString() -> String { value }
}

struct ReturnStatement: Statement, Equatable {
  let token      : Token    // .let token
  var returnValue: Expression

  func asString() -> String {
    var buffer = ""
    buffer += tokenLiteral() + " "
    buffer += returnValue.asString()
    buffer += ";"
    return buffer
  }
}

struct ExpressionStatement: Statement, Equatable {
  let token     : Token     // The first token of the expression
  var expression: Expression

  func asString() -> String { expression.asString() }
}

struct IntegerLiteral: Expression, Hashable {
  let token: Token

  // contains the actual value the integer literal represents in the source
  // code.
  //
  var value: Int64

  func asString() -> String { token.literal }
}

struct PrefixExpression: Expression, Hashable {
  let token     : Token        // The prefix token
  let `operator`: String       // contains either "-" or "!"
  var right     : Expression   // the expression to the right of the operator.

  func asString() -> String {
    var buffer = ""
    buffer += "("
    buffer += `operator`
    buffer += right.asString()
    buffer += ")"
    return buffer
  }
}

struct InfixExpression: Expression, Hashable {
  let token     : Token
  var left      : Expression
  let `operator`: String
  var right     : Expression

  func asString() -> String {
    var buffer = ""
    buffer += "("
    buffer += left.asString()
    buffer += " " + `operator` + " "
    buffer += right.asString()
    buffer += ")"
    return buffer
  }
}

struct BooleanExpression: Expression, Hashable {
  let token: Token
  let value: Bool

  func asString() -> String { token.literal }
}

struct IfExpression: Expression, Hashable {
  let token      : Token
  var condition  : Expression
  var consequence: BlockStatement
  var alternative: BlockStatement?

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

struct BlockStatement: Statement, Equatable {
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

struct FunctionLiteral: Expression, Hashable {
  let token     : Token
  var parameters: [Identifier]
  var body      : BlockStatement

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

struct CallExpression: Expression, Hashable {
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

struct StringLiteral: Expression, Hashable {
  let token: Token
  let value: String

  func asString() -> String { token.literal }
}

struct ArrayLiteral: Expression, Hashable {
  let token   : Token
  var elements: [Expression]

  func asString() -> String {
    var buffer = ""
    var elems: [String] = []
    for e in elements {
      elems.append(e.asString())
    }
    buffer += "["
    buffer += elems.joined(separator: ", ")
    buffer += "]"
    return buffer;
  }
}

struct IndexExpression: Expression, Hashable {
  let token: Token
  var left : Expression
  var index: Expression

  func asString() -> String {
    var buffer = ""
    buffer += "("
    buffer += left.asString()
    buffer += "["
    buffer += index.asString()
    buffer += "]"
    buffer += ")"
    return buffer
  }
}

struct HashLiteral: Expression, Hashable {
  let token: Token
  var store: [AnyHashable: Expression] = [:]

  func asString() -> String {
    var buffer = ""
    var store: [String] = []
    for (key, value) in self.store {
      store.append("\((key as! Expression).asString()): \(value.asString())")
    }
    buffer += "{\(store.joined(separator: ", "))}"
    return buffer
  }
}

struct MacroLiteral: Expression, Hashable {
  let token     : Token
  var parameters: [Identifier]
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
