//===-- Parser ------------------------------------------------*- Swift -*-===//
//
// This module implements the monkey parser.
// The parser will take the tokens produced by the lexer and turn them into a
// data structure that represent the source code, checking for correct syntax
// in the process.
//
//===----------------------------------------------------------------------===//

import Lexer

struct Parser {
  var lexer: Lexer              // An instance of the lexer

  // Both are important: we need to look at the curToken, which is the current
  // token under examination, to decide what to do next, and we also need
  // peekToken for this decision if curToken doesn’t give us enough information.
  //
  var curToken : Token!         // Points to current token
  var peekToken: Token!         // After the current token
  
  var errors: [String] = []     // Holds parsing errors

  init(input: String) {
    self.lexer = Lexer(input: input)

    // Read two tokens, so curToken and peekToken are both set
    //
    nextToken()
    nextToken()
  }

  // Advances both curToken and peekToken.
  //
  mutating func nextToken() {
    curToken  = peekToken
    peekToken = lexer.nextToken()
  }

  // Constructs the root node of the AST, a Program. Then iterates over every
  // token in the input until it encounters an EOF token by repeatedly calling
  // nextToken.
  // In every iteration it calls parseStatement. If parseStatement returned
  // something other than nil, a Statement, its return value is added to
  // statements array of the AST root node. When nothing is left to parse the
  // Program root node is returned.
  //
  mutating func parseProgram() -> Program? {
    var program = Program()
    while curToken.type != .EOF {
      if let stmt = parseStatement() {
        program.statements.append(stmt)
      }
      nextToken()
    }
    return program
  }

  // Runs the corresponding parsing method depending on the type of curToken
  //
  private mutating func parseStatement() -> Statement? {
    switch curToken.type {
    case .LET   : return parseLetStatement()
    case .RETURN: return parseReturnStatement()
    default:
      return nil  
    }
  }

  // Constructs a LetStatement node with the token it’s currently sitting on
  // (a .LET token) and then advances the tokens while making assertions
  // about the next token with calls to expectPeek.
  // First it expects a .IDENT token, which it then uses to construct an
  // Identifier node. Then it expects an equal sign and finally it jumps
  // over the expression following the equal sign until it encounters a
  // semicolon.
  //
  private mutating func parseLetStatement() -> LetStatement? {
    let token = curToken!
    if !expectPeek(.IDENT) {
      return nil
    }

    let name = Identifier(token: curToken!, value: curToken.literal)
    if !expectPeek(.ASSIGN) {
      return nil
    }

    // We're skipping the expressions until we encounter a semicolon.
    // This should be replaced as soon as we know how to parse them.
    //
    while curToken.type != .SEMICOLON {
      nextToken()
    }
    return LetStatement(token: token, name: name)
  }

  // Constructs a ReturnStatement, with the current token it’s sitting on,
  // It then brings the parser in place for the expression that comes next
  // by calling nextToken() and finally skips over every expression until
  // it encounters a semicolon.
  //
  private mutating func parseReturnStatement() -> ReturnStatement {
    let stmt = ReturnStatement(token: curToken)
    nextToken()

    // skipping again
    //
    while curToken.type != .SEMICOLON {
      nextToken()
    }
    return stmt
  }

  // The expectPeek method is one of the “assertion functions” nearly all
  // parsers share. Their primary purpose is to enforce the correctness of
  // the order of tokens by checking the type of the next token.
  // Our expectPeek here checks the type of the peekToken and only if the
  // type is correct does it advance the tokens by calling nextToken.
  //
  private mutating func expectPeek(_ type: TokenType) -> Bool {
    if peekToken.type == type {
      nextToken()
      return true
    } else {
      peekError(type)
      return false
    }
  }

  // Adds an error to errors when the type of peekToken doesn’t match
  // the expectation.
  //
  private mutating func peekError(_ type: TokenType) {
    errors.append("""
      Expected next token to be \(type.rawValue). \
      got \(peekToken.type.rawValue) instead"
      """)
  }
}
