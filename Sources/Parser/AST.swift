//===-- AST ---------------------------------------------------*- Swift -*-===//
//
// This file implements the abstract syntax tree that the parser in going to
// build.
// 
//===----------------------------------------------------------------------===//

import Lexer

// Every node in our AST has to implement the Node protocol, meaning it has
// to provide a tokenLiteral() method.
//
protocol Node {
  // will be used only for debugging and testing.
  // returns the literal value of the token it’s associated with.
  //
  func tokenLiteral() -> String
}

// not strictly necessary but help us by guiding the compiler and possibly
// causing it to throw errors when we use a Statement where an Expression
// should’ve been used, and vice versa.
//
protocol Statement  : Node {}
protocol Expression : Node {}

// This Program node is going to be the root node of every AST our parser
// produces.
//
struct Program : Node {
  // Every valid Monkey program is a series of statements.
  // Here we stores the statements of a program.
  //
  var statements: [Statement] = []

  func tokenLiteral() -> String {
    statements.count > 0 ? statements[0].tokenLiteral() : ""
  }
}

struct LetStatement : Statement {
  let token: Token          // .LET token
  var name : Identifier     // holds the identifier of the binding
  var value: Expression?    // for the expression that produces the value

  func tokenLiteral() -> String { token.literal }
}

struct Identifier : Expression {
  let token: Token          // .IDENT token
  var value: String

  func tokenLiteral() -> String { token.literal }
}

struct ReturnStatement : Statement {
  let token      : Token    // .RETURN token
  var returnValue: Expression?

  func tokenLiteral() -> String { token.literal }
}
