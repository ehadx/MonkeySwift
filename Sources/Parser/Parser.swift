//===-- Parser ------------------------------------------------*- Swift -*-===//
//
// This module implements the monkey parser.
// The parser will take the tokens produced by the lexer and turn them into a
// data structure that represent the source code, checking for correct syntax
// in the process.
//
//===----------------------------------------------------------------------===//

import Lexer

// What we want out of these constants is to later be able to answer: “does
// the * operator have a higher precedence than the == operator? Does a
// prefix operator have a higher preference than a call expression?”.
//
enum Precedence: Int {
  case LOWEST = 0
  case EQUALS      // ==
  case LESSGREATER // > or <
  case SUM         // +a
  case PRODUCT     // *
  case PREFIX      // -X or !X
  case CALL        // myFunction(X)
}

// associates token types with their precedence.
//
let precedences: [TokenType: Precedence] = [
  .EQ      : .EQUALS,
  .NOT_EQ  : .EQUALS,
  .LT      : .LESSGREATER,
  .GT      : .LESSGREATER,
  .PLUS    : .SUM,
  .MINUS   : .SUM,
  .SLASH   : .PRODUCT,
  .ASTERISK: .PRODUCT
]

// I'm planing to keep using the straightforward approach, but it's not
// possible anymore, so when it's possible to append parsing errors directly
// I will go with that, and when it's not I'll use this enum to represent
// parser error, throw it and then append the message from outside the parse
// function.
// The reason for all of this is that we can't store a function
// that returns and Optional.
// Later i should try to refactor the whole code into a more "Swift" way.
//
enum ParserError: Error {
  case error(_ errorMsg: String)
}

final class Parser {
  var lexer: Lexer              // An instance of the lexer

  // Both are important: we need to look at the curToken, which is the current
  // token under examination, to decide what to do next, and we also need
  // peekToken for this decision if curToken doesn’t give us enough information.
  //
  var curToken : Token! {       // Points to current token
    didSet {
      // I DONT KNOW IF I SHOULD MOVE THESE SINCE PARSER IS A CLASS NOW!
      prefixParseFns[.IDENT]   = parseIdentifier
      prefixParseFns[.INT]     = parseIntegerLiteral
      prefixParseFns[.BANG]    = parsePrefixExpression
      prefixParseFns[.MINUS]   = parsePrefixExpression

      infixParseFns[.PLUS]     = parseInfixExpression
      infixParseFns[.MINUS]    = parseInfixExpression
      infixParseFns[.SLASH]    = parseInfixExpression
      infixParseFns[.ASTERISK] = parseInfixExpression
      infixParseFns[.EQ]       = parseInfixExpression
      infixParseFns[.NOT_EQ]   = parseInfixExpression
      infixParseFns[.LT]       = parseInfixExpression
      infixParseFns[.GT]       = parseInfixExpression
    }
  }         
  var peekToken: Token!         // After the current token
  
  var errors: [String] = []     // Holds parsing errors

  private var prefixParseFns: [TokenType: PrefixParseFn] = [:]
  private var infixParseFns : [TokenType: InfixParseFn]  = [:]

  init(input: String) {
    lexer = Lexer(input: input)
    
    // Read two tokens, so curToken and peekToken are both set
    //
    nextToken()
    nextToken()
  }

  // Advances both curToken and peekToken.
  //
  func nextToken() {
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
  func parseProgram() -> Program? {
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
  private func parseStatement() -> Statement? {
    switch curToken.type {
    case .LET   : return parseLetStatement()
    case .RETURN: return parseReturnStatement()
    default:
      return parseExpressionStatement()
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
  private func parseLetStatement() -> LetStatement? {
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
  private func parseReturnStatement() -> ReturnStatement {
    let stmt = ReturnStatement(token: curToken)
    nextToken()

    // skipping again
    //
    while curToken.type != .SEMICOLON {
      nextToken()
    }
    return stmt
  }

  // we build our AST node and then try to fill its field by calling other
  // parsing functions, and then we check for an optional semicolon.
  // Yes, it’s optional. If the peekToken is a .SEMICOLON, we advance so it’s
  // the curToken. If it’s not there, that’s okay too, we don’t add an error
  // to the parser if it’s not there. That’s because we want expression
  // statements to have optional semicolons (which makes it easier to type
  // something like 5 + 5 into the REPL later on).
  // 
  private func parseExpressionStatement() -> ExpressionStatement {
    let token      = curToken!
    let expression = parseExpression(precedence: .LOWEST)

    if peekToken.type == .SEMICOLON {
      nextToken()
    }
    return ExpressionStatement(token: token, expression: expression)
  }

  private func parseExpression(precedence: Precedence) -> Expression? {
    guard let `prefix` = prefixParseFns[curToken.type] else {
      noPrefixParseFnError(curToken.type)
      return nil
    }
    do {
      var leftExp: Expression
      try leftExp = `prefix`()

      while peekToken.type != .SEMICOLON && precedence.rawValue < peekPrecedence().rawValue {
        guard let `infix` = infixParseFns[peekToken.type] else {
          return leftExp
        }
        nextToken()
        leftExp = `infix`(leftExp)
      }
      return leftExp
    } catch ParserError.error(let msg) {
      errors.append(msg)
    } catch {
      errors.append("\(error)")
    }
    return nil
  }

  private func parseInfixExpression(left: Expression) -> Expression {
    let token       = curToken!
    let `operator`  = token.literal
    let precedence  = curPrecedence()

    nextToken()
    let right = parseExpression(precedence: precedence)
    
    return InfixExpression(token: token, left: left, operator: `operator`, right: right)
  }

  private func parsePrefixExpression() -> Expression {
    let token      = curToken!
    let `operator` = token.literal

    nextToken()

    let right = parseExpression(precedence: .PREFIX)
    return PrefixExpression(token: token, operator: `operator`, right: right)
  }

  private func parseIdentifier() throws -> Expression {
    Identifier(token: curToken, value: curToken.literal)
  }

  private func parseIntegerLiteral() throws -> Expression {
    guard let value = Int64(curToken.literal) else {
      throw ParserError.error("could not parse \(curToken.literal) as integer")
    }
    return IntegerLiteral(token: curToken, value: value)
  }

  private func noPrefixParseFnError(_ tokenType: TokenType) {
    errors.append("no prefix parse function for \(tokenType) found")
  }

  // The expectPeek method is one of the “assertion functions” nearly all
  // parsers share. Their primary purpose is to enforce the correctness of
  // the order of tokens by checking the type of the next token.
  // Our expectPeek here checks the type of the peekToken and only if the
  // type is correct does it advance the tokens by calling nextToken.
  //
  private func expectPeek(_ type: TokenType) -> Bool {
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
  private func peekError(_ type: TokenType) {
    errors.append("""
      Expected next token to be \(type.rawValue). \
      got \(peekToken.type.rawValue) instead"
      """)
  }

  // returns the precedence associated with the token type of curToken.
  //
  private func curPrecedence() -> Precedence {
    guard let precendence = precedences[curToken.type] else {
      return .LOWEST
    }
    return precendence
  }

  // returns the precedence associated with the token type of peekToken.
  //
  private func peekPrecedence() -> Precedence {
    guard let precendence = precedences[peekToken.type] else {
      return .LOWEST
    }
    return precendence
  }
}
