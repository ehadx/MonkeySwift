//===-- Parser ------------------------------------------------*- Swift -*-===//
//
// This module implements the monkey parser.
// The parser will take the tokens produced by the lexer and turn them into a
// data structure that represent the source code, checking for correct syntax
// in the process.
//
//===----------------------------------------------------------------------===//

public final class Parser {
  var lexer: Lexer              // An instance of the lexer

  // Both are important: we need to look at the curToken, which is the current
  // token under examination, to decide what to do next, and we also need
  // peekToken for this decision if curToken doesn’t give us enough information.
  //
  var curToken : Token!         // Points to current token
  var peekToken: Token!         // After the current token
  
  private var errorsArr: [String] = []      // Holds parsing errors
  public  var errors   : [String] { errorsArr }

  lazy var prefixParseFns: [Token.`Type`: PrefixParseFn] = [
    .ident    : parseIdentifier,
    .int      : parseIntegerLiteral,
    .bang     : parsePrefixExpression,
    .minus    : parsePrefixExpression,
    .true     : parseBoolean,
    .false    : parseBoolean,
    .leftParen: parseGroupedExpression,
    .if       : parseIfExpression,
    .function : parseFunctionLiteral,
  ]
  lazy var infixParseFns: [Token.`Type`: InfixParseFn]  = [
    .plus       : parseInfixExpression,
    .minus      : parseInfixExpression,
    .slash      : parseInfixExpression,
    .asterisk   : parseInfixExpression,
    .equal      : parseInfixExpression,
    .notEqual   : parseInfixExpression,
    .lessThan   : parseInfixExpression,
    .greaterThan: parseInfixExpression,
    .leftParen  : parseCallExpression,
  ]

  public init(_ input: String) {
    lexer = Lexer(input)

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

  // The expectPeek method is one of the “assertion functions” nearly all
  // parsers share. Their primary purpose is to enforce the correctness of
  // the order of tokens by checking the type of the next token.
  // Our expectPeek here checks the type of the peekToken and only if the
  // type is correct does it advance the tokens by calling nextToken.
  //
  func expectPeek(_ type: Token.`Type`) -> (Bool, String) {
    if peekToken.type == type {
      nextToken()
      return (true, "")
    } else {
      return (false, """
        Expected next token to be \(type). \
        got \(peekToken.type) instead"
        """) 
    }
  }

  func noPrefixParseFnError(_ tokenType: Token.`Type`) {
    errorsArr.append("no prefix parse function for \(tokenType) found")
  }

  // Constructs the root node of the AST, a Program. Then iterates over every
  // token in the input until it encounters an.eof token by repeatedly calling
  // nextToken.
  // In every iteration it calls parseStatement. If parseStatement returned
  // something other than nil, a Statement, its return value is added to
  // statements array of the AST root node. When nothing is left to parse the
  // Program root node is returned.
  //
  public func parseProgram() -> Program {
    var program = Program()
    while curToken.type != .eof {
      if let stmt = parseStatement() {
        program.statements.append(stmt)
      }
      nextToken()
    }
    return program
  }

  // TODO: better error handling to get rid of all useless optionals
  //
  enum ParseError: Error {
    case error(_ errorMsg: String)
  }
}

// Statement Parsing
//
extension Parser {
  // Runs the corresponding parsing method depending on the type of curToken
  //
  func parseStatement() -> Statement? {
    switch curToken.type {
    case .let   : return parseLetStatement()
    case .return: return parseReturnStatement()
    default:
      return parseExpressionStatement()
    }
  }

  // Constructs a LetStatement node with the token it’s currently sitting on
  // (a .let token) and then advances the tokens while making assertions
  // about the next token with calls to expectPeek.
  // First it expects a .IDENT token, which it then uses to construct an
  // Identifier node. Then it expects an equal sign.
  //
  func parseLetStatement() -> LetStatement? {
    let token       = curToken!
    var (peek, msg) = expectPeek(.ident)
    if !peek {
      errorsArr.append(msg)
      return nil
    }
    
    let name    = Identifier(token: curToken!, value: curToken.literal)
    (peek, msg) = expectPeek(.assign)
    if !peek {
      errorsArr.append(msg)
      return nil
    }
    nextToken()

    let value = parseExpression(.lowest)
    if peekToken.type == .semicolon {
      nextToken()
    }
    return LetStatement(token: token, name: name, value: value)
  }

  // Constructs a ReturnStatement, with the current token it’s sitting on,
  // It then brings the parser in place for the expression that comes next
  // by calling nextToken().
  //
  func parseReturnStatement() -> ReturnStatement {
    let token = curToken!
    nextToken()
    let returnVal = parseExpression(.lowest)
    if peekToken.type == .semicolon {
      nextToken()
    }
    return ReturnStatement(token: token, returnValue: returnVal)
  }

  // we build our AST node and then try to fill its field by calling other
  // parsing functions, and then we check for an optional semicolon.
  // Yes, it’s optional. If the peekToken is a .semicolon, we advance so it’s
  // the curToken. If it’s not there, that’s okay too, we don’t add an error
  // to the parser if it’s not there. That’s because we want expression
  // statements to have optional semicolons (which makes it easier to type
  // something like 5 + 5 into the REPL later on).
  // 
  func parseExpressionStatement() -> ExpressionStatement {
    let token      = curToken!
    let expression = parseExpression(.lowest)
    if peekToken.type == .semicolon {
      nextToken()
    }
    return ExpressionStatement(token: token, expression: expression)
  }

  func parseBlockStatement() -> BlockStatement {
    var block = BlockStatement(token: curToken)
    nextToken()

    while curToken.type != .rightBrace && curToken.type != .eof {
      if let stmt = parseStatement() {
        block.statements.append(stmt)
      }
      nextToken()
    }
    return block
  }
}

// Expression Parsing
//
extension Parser {
  func parseExpression(_ precedence: Precedence) -> Expression? {
    guard let `prefix` = prefixParseFns[curToken.type] else {
      noPrefixParseFnError(curToken.type)
      return nil
    }
    do {
      var leftExp: Expression
      try leftExp = `prefix`()
      while peekToken.type != .semicolon && precedence < Precedence(peekToken.type) {
        guard let `infix` = infixParseFns[peekToken.type] else {
          return leftExp
        }
        nextToken()
        try leftExp = `infix`(leftExp)
      }
      return leftExp
    } catch ParseError.error(let msg) {
      errorsArr.append(msg)
    } catch {
      errorsArr.append("\(error)")
    }
    return nil
  }

  func parseIdentifier() -> Expression {
    Identifier(token: curToken, value: curToken.literal)
  }

  func parseIntegerLiteral() throws -> Expression {
    guard let value = Int64(curToken.literal) else {
      throw ParseError.error("could not parse \(curToken.literal) as integer")
    }
    return IntegerLiteral(token: curToken, value: value)
  }

  func parsePrefixExpression() -> Expression {
    let token      = curToken!
    let `operator` = token.literal
    nextToken()
    let right = parseExpression(.prefix)
    return PrefixExpression(token: token, operator: `operator`, right: right)
  }

  func parseInfixExpression(left: Expression) -> Expression {
    let token       = curToken!
    let `operator`  = token.literal
    let precedence  = Precedence(curToken.type)
    nextToken()
    let right = parseExpression(precedence)
    return InfixExpression(token: token, left: left, operator: `operator`, right: right)
  }

  func parseBoolean() -> Expression {
    BooleanExpression(token: curToken, value: curToken.type == .true)
  }

  func parseGroupedExpression() throws -> Expression {
    nextToken()
    let exp = parseExpression(.lowest)!
    let (peek, msg) = expectPeek(.rightParen)
    if !peek {
      throw ParseError.error(msg);
    }
    return exp
  }

  func parseIfExpression() throws -> Expression {
    let token = curToken!
    var (peek, msg) = expectPeek(.leftParen)
    if !peek {
      throw ParseError.error(msg)
    }
    nextToken()

    let condition = parseExpression(.lowest)!
    (peek, msg) = expectPeek(.rightParen)
    if !peek {
      throw ParseError.error(msg)
    }

    (peek, msg) = expectPeek(.leftBrace) 
    if !peek {
      throw ParseError.error(msg)
    }

    let consequence = parseBlockStatement()
    var alternative: BlockStatement?
    if peekToken.type == .else {
      nextToken()

      (peek, msg) = expectPeek(.leftBrace)
      if !peek {
        throw ParseError.error(msg)
      }
      alternative = parseBlockStatement()
    }
    return IfExpression(
      token: token,condition: condition,
      consequence: consequence, alternative: alternative)
  }

  func parseFunctionLiteral() throws -> Expression {
    let token = curToken!
    var (peek, msg) = expectPeek(.leftParen)
    if !peek {
      throw ParseError.error(msg)
    }

    let params = try parseFunctionParameters()
    (peek, msg) = expectPeek(.leftBrace)
    if !peek {
      throw ParseError.error(msg)
    }
    let body = parseBlockStatement()
    return FunctionLiteral(token: token, parameters: params, body: body)
  }

  func parseFunctionParameters() throws -> [Identifier] {
    var idents: [Identifier] = []
    if peekToken.type == .rightParen {
      nextToken()
      return idents
    }
    nextToken()
    var ident = Identifier(token: curToken, value: curToken.literal)
    idents.append(ident)
    while peekToken.type == .comma {
      nextToken()
      nextToken()
      ident = Identifier(token: curToken, value: curToken.literal) 
      idents.append(ident) 
    }

    let (peek, msg) = expectPeek(.rightParen)
    if !peek {
      throw ParseError.error(msg)
    }
    return idents
  }

  func parseCallExpression(_ function: Expression) throws -> Expression {
    let token     = curToken!
    var arguments: [Expression] = []
    do {
      try arguments = parseCallArguments()
    } catch ParseError.error(let msg) {
      throw ParseError.error(msg)
    } catch {
      throw error
    }
    return CallExpression(token: token, arguments: arguments, function: function)
  }

  func parseCallArguments() throws -> [Expression] {
    var args: [Expression] = []
    if peekToken.type == .rightParen {
      nextToken()
      return args
    }
    nextToken()
    args.append(parseExpression(.lowest)!)
    while peekToken.type == .comma {
      nextToken()
      nextToken()
      args.append(parseExpression(.lowest)!)
    }

    let (peek, msg) = expectPeek(.rightParen)
    if !peek {
      throw ParseError.error(msg)
    }
    return args
  }
}
