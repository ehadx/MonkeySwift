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
private enum Precedence: Int {
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
private let precedences: [TokenType: Precedence] = [
  .EQ      : .EQUALS,
  .NOT_EQ  : .EQUALS,
  .LT      : .LESSGREATER,
  .GT      : .LESSGREATER,
  .PLUS    : .SUM,
  .MINUS   : .SUM,
  .SLASH   : .PRODUCT,
  .ASTERISK: .PRODUCT,
  .LPAREN  : .CALL
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
private enum ParserError: Error {
  case error(_ errorMsg: String)
}

public final class Parser {
  private var lexer: Lexer              // An instance of the lexer

  // Both are important: we need to look at the curToken, which is the current
  // token under examination, to decide what to do next, and we also need
  // peekToken for this decision if curToken doesn’t give us enough information.
  //
  private var curToken : Token!         // Points to current token
  private var peekToken: Token!         // After the current token
  
  public var errors: [String] = []      // Holds parsing errors

  private lazy var prefixParseFns: [TokenType: PrefixParseFn] = [
    .IDENT    : parseIdentifier,
    .INT      : parseIntegerLiteral,
    .BANG     : parsePrefixExpression,
    .MINUS    : parsePrefixExpression,
    .TRUE     : parseBoolean,
    .FALSE    : parseBoolean,
    .LPAREN   : parseGroupedExpression,
    .IF       : parseIfExpression,
    .FUNCTION : parseFunctionLiteral,
  ]
  private lazy var infixParseFns : [TokenType: InfixParseFn]  = [
    .PLUS     : parseInfixExpression,
    .MINUS    : parseInfixExpression,
    .SLASH    : parseInfixExpression,
    .ASTERISK : parseInfixExpression,
    .EQ       : parseInfixExpression,
    .NOT_EQ   : parseInfixExpression,
    .LT       : parseInfixExpression,
    .GT       : parseInfixExpression,
    .LPAREN   : parseCallExpression,
  ]

  public init(input: String) {
    lexer = Lexer(input: input)

    // Read two tokens, so curToken and peekToken are both set
    //
    nextToken()
    nextToken()
  }

  // Advances both curToken and peekToken.
  //
  private func nextToken() {
    curToken  = peekToken
    peekToken = lexer.nextToken()
  }

  // The expectPeek method is one of the “assertion functions” nearly all
  // parsers share. Their primary purpose is to enforce the correctness of
  // the order of tokens by checking the type of the next token.
  // Our expectPeek here checks the type of the peekToken and only if the
  // type is correct does it advance the tokens by calling nextToken.
  //
  private func expectPeek(_ type: TokenType) -> (Bool, String) {
    if peekToken.type == type {
      nextToken()
      return (true, "")
    } else {
      return (false, """
        Expected next token to be \(type.rawValue). \
        got \(peekToken.type.rawValue) instead"
        """) 
    }
  }

  private func noPrefixParseFnError(_ tokenType: TokenType) {
    errors.append("no prefix parse function for \(tokenType) found")
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

  // Constructs the root node of the AST, a Program. Then iterates over every
  // token in the input until it encounters an EOF token by repeatedly calling
  // nextToken.
  // In every iteration it calls parseStatement. If parseStatement returned
  // something other than nil, a Statement, its return value is added to
  // statements array of the AST root node. When nothing is left to parse the
  // Program root node is returned.
  //
  public func parseProgram() -> Program {
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
  // Identifier node. Then it expects an equal sign.
  //
  private func parseLetStatement() -> LetStatement? {
    let token       = curToken!
    var (peek, msg) = expectPeek(.IDENT)
    if !peek {
      errors.append(msg)
      return nil
    }
    
    let name    = Identifier(token: curToken!, value: curToken.literal)
    (peek, msg) = expectPeek(.ASSIGN)
    if !peek {
      errors.append(msg)
      return nil
    }
    nextToken()

    let value = parseExpression(precedence: .LOWEST)
    if peekToken.type == .SEMICOLON {
      nextToken()
    }
    return LetStatement(token: token, name: name, value: value)
  }

  // Constructs a ReturnStatement, with the current token it’s sitting on,
  // It then brings the parser in place for the expression that comes next
  // by calling nextToken().
  //
  private func parseReturnStatement() -> ReturnStatement {
    let token = curToken!
    nextToken()
    let returnVal = parseExpression(precedence: .LOWEST)
    if peekToken.type == .SEMICOLON {
      nextToken()
    }
    return ReturnStatement(token: token, returnValue: returnVal)
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
        try leftExp = `infix`(leftExp)
      }
      return leftExp
    } catch ParserError.error(let msg) {
      errors.append(msg)
    } catch {
      errors.append("\(error)")
    }
    return nil
  }

  private func parseIdentifier() -> Expression {
    Identifier(token: curToken, value: curToken.literal)
  }

  private func parseIntegerLiteral() throws -> Expression {
    guard let value = Int64(curToken.literal) else {
      throw ParserError.error("could not parse \(curToken.literal) as integer")
    }
    return IntegerLiteral(token: curToken, value: value)
  }

  private func parsePrefixExpression() -> Expression {
    let token      = curToken!
    let `operator` = token.literal
    nextToken()
    let right = parseExpression(precedence: .PREFIX)
    return PrefixExpression(token: token, operator: `operator`, right: right)
  }

  private func parseInfixExpression(left: Expression) -> Expression {
    let token       = curToken!
    let `operator`  = token.literal
    let precedence  = curPrecedence()
    nextToken()
    let right = parseExpression(precedence: precedence)
    return InfixExpression(token: token, left: left, operator: `operator`, right: right)
  }

  private func parseBoolean() -> Expression {
    Boolean(token: curToken, value: curToken.type == .TRUE)
  }

  private func parseGroupedExpression() throws -> Expression {
    nextToken()
    let exp = parseExpression(precedence: .LOWEST)!
    let (peek, msg) = expectPeek(.RPAREN)
    if !peek {
      throw ParserError.error(msg);
    }
    return exp
  }

  private func parseIfExpression() throws -> Expression {
    let token = curToken!
    var (peek, msg) = expectPeek(.LPAREN)
    if !peek {
      throw ParserError.error(msg)
    }
    nextToken()

    let condition = parseExpression(precedence: .LOWEST)!
    (peek, msg) = expectPeek(.RPAREN)
    if !peek {
      throw ParserError.error(msg)
    }

    (peek, msg) = expectPeek(.LBRACE) 
    if !peek {
      throw ParserError.error(msg)
    }

    let consequence = parseBlockStatement()
    var alternative: BlockStatement?
    if peekToken.type == .ELSE {
      nextToken()

      (peek, msg) = expectPeek(.LBRACE)
      if !peek {
        throw ParserError.error(msg)
      }
      alternative = parseBlockStatement()
    }
    return IfExpression(
      token: token,condition: condition,
      consequence: consequence, alternative: alternative)
  }

  private func parseBlockStatement() -> BlockStatement {
    var block = BlockStatement(token: curToken)
    nextToken()

    while curToken.type != .RBRACE && curToken.type != .EOF {
      if let stmt = parseStatement() {
        block.statements.append(stmt)
      }
      nextToken()
    }
    return block
  }

  private func parseFunctionLiteral() throws -> Expression {
    let token = curToken!
    var (peek, msg) = expectPeek(.LPAREN)
    if !peek {
      throw ParserError.error(msg)
    }

    let params = try parseFunctionParameters()
    (peek, msg) = expectPeek(.LBRACE)
    if !peek {
      throw ParserError.error(msg)
    }
    let body = parseBlockStatement()
    return FunctionLiteral(token: token, parameters: params, body: body)
  }

  private func parseFunctionParameters() throws -> [Identifier] {
    var idents: [Identifier] = []
    if peekToken.type == .RPAREN {
      nextToken()
      return idents
    }
    nextToken()
    var ident = Identifier(token: curToken, value: curToken.literal)
    idents.append(ident)
    while peekToken.type == .COMMA {
      nextToken()
      nextToken()
      ident = Identifier(token: curToken, value: curToken.literal) 
      idents.append(ident) 
    }

    let (peek, msg) = expectPeek(.RPAREN)
    if !peek {
      throw ParserError.error(msg)
    }
    return idents
  }

  private func parseCallExpression(function: Expression) throws -> Expression {
    let token     = curToken!
    var arguments: [Expression] = []
    do {
      try arguments = parseCallArguments()
    } catch ParserError.error(let msg) {
      throw ParserError.error(msg)
    } catch {
      throw error
    }
    return CallExpression(token: token, arguments: arguments, function: function)
  }

  private func parseCallArguments() throws -> [Expression] {
    var args: [Expression] = []
    if peekToken.type == .RPAREN {
      nextToken()
      return args
    }
    nextToken()
    args.append(parseExpression(precedence: .LOWEST)!)
    while peekToken.type == .COMMA {
      nextToken()
      nextToken()
      args.append(parseExpression(precedence: .LOWEST)!)
    }

    let (peek, msg) = expectPeek(.RPAREN)
    if !peek {
      throw ParserError.error(msg)
    }
    return args
  }
}
