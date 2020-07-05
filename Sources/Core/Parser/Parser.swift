//===-- Parser ------------------------------------------------*- Swift -*-===//
//
// Implements the monkey parser.
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

  // The argument is “left side” of the infix operator that’s being parsed.
  //
  typealias InfixParseFn = (_ e: Expression) throws -> Expression

  // A prefix operator doesn’t have a “left side”, per definition.
  //
  typealias PrefixParseFn = () throws -> Expression

  lazy var prefixParseFns: [Token.`Type`: PrefixParseFn] = [
    .ident      : parseIdentifier,
    .int        : parseIntegerLiteral,
    .bang       : parsePrefixExpression,
    .minus      : parsePrefixExpression,
    .true       : parseBoolean,
    .false      : parseBoolean,
    .leftParen  : parseGroupedExpression,
    .if         : parseIfExpression,
    .function   : parseFunctionLiteral,
    .string     : parseStringLiteral,
    .leftBracket: parseArrayLiteral,
    .leftBrace  : parseHashLiteral,
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
    .leftParen  : parseCallExpression ,
    .leftBracket: parseIndexExpression,
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
  func expectPeek(_ type: Token.`Type`) throws {
    if peekToken.type == type {
      nextToken()
    } else {
      throw ParseError.unexpectedToken(type, got: peekToken)
    }
  }

  // Constructs the root node of the AST, a Program. Then iterates over every
  // token in the input until it encounters an.eof token by repeatedly calling
  // nextToken.
  // In every iteration it calls parseStatement. If parseStatement returned
  // its return value is added to statements array of the AST root node.
  // When nothing is left to parse the Program root node is returned.
  //
  public func parseProgram() -> Program {
    var program = Program()
    do {
      while curToken.type != .eof {
        let stmt = try parseStatement()
        program.statements.append(stmt)
        nextToken()
      }
      return program
      
      // TODO: better error handling
      //
    } catch ParseError.unexpectedToken(let expected, got: let got) {
      fatalError("unexpectedToken: '\(got.literal)' expected token '\(expected)' instead")
    } catch ParseError.noPrefixParseFn(let type) {
      fatalError("parsing '\(type)' is not supported yet")
    } catch ParseError.unparsableAsInt(for: let value) {
      fatalError("cannot parse '\(value)' as Int")
    } catch {
      fatalError("\(error)")
    }
  }

  public enum ParseError: Error {
    case unexpectedToken(_ type : Token.`Type`, got: Token)
    case noPrefixParseFn(  for  : Token.`Type`            )
    case unparsableAsInt(_ value: String                  )
  }
}

// Statement Parsing
//
extension Parser {
  // Runs the corresponding parsing method depending on the type of curToken
  //
  func parseStatement() throws -> Statement {
    switch curToken.type {
    case .let   : return try parseLetStatement()
    case .return: return try parseReturnStatement()
    default:
      return try parseExpressionStatement()
    }
  }

  // Constructs a LetStatement node with the token it’s currently sitting on
  // (a .let token) and then advances the tokens while making assertions
  // about the next token with calls to expectPeek.
  // First it expects a .IDENT token, which it then uses to construct an
  // Identifier node. Then it expects an equal sign.
  //
  func parseLetStatement() throws -> LetStatement {
    let token = curToken!
    try expectPeek(.ident)

    let name = Identifier(token: curToken!, value: curToken.literal)
    try expectPeek(.assign)
    nextToken()

    let value = try parseExpression(.lowest)
    if peekToken.type == .semicolon {
      nextToken()
    }
    return LetStatement(token: token, name: name, value: value)
  }

  // Constructs a ReturnStatement, with the current token it’s sitting on,
  // It then brings the parser in place for the expression that comes next
  // by calling nextToken().
  //
  func parseReturnStatement() throws -> ReturnStatement {
    let token = curToken!
    nextToken()
    let returnVal = try parseExpression(.lowest)
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
  func parseExpressionStatement() throws -> ExpressionStatement {
    let token      = curToken!
    let expression = try parseExpression(.lowest)
    if peekToken.type == .semicolon {
      nextToken()
    }
    return ExpressionStatement(token: token, expression: expression)
  }

  func parseBlockStatement() throws -> BlockStatement {
    var block = BlockStatement(token: curToken)
    nextToken()

    while curToken.type != .rightBrace && curToken.type != .eof {
      let stmt = try parseStatement()
      block.statements.append(stmt)
      nextToken()
    }
    return block
  }
}

// Expression Parsing
//
extension Parser {
  func parseExpression(_ precedence: Precedence) throws -> Expression {
    guard let `prefix` = prefixParseFns[curToken.type] else {
      throw ParseError.noPrefixParseFn(for: curToken.type)
    }
    var leftExp = try `prefix`() 
    while peekToken.type != .semicolon && precedence < Precedence(peekToken.type) {
      guard let `infix` = infixParseFns[peekToken.type] else {
        return leftExp
      }
      nextToken()
      leftExp = try `infix`(leftExp)
    }
    return leftExp
  }

  func parseIdentifier() -> Expression {
    Identifier(token: curToken, value: curToken.literal)
  }

  func parseIntegerLiteral() throws -> Expression {
    guard let value = Int64(curToken.literal) else {
      throw ParseError.unparsableAsInt(curToken.literal)
    }
    return IntegerLiteral(token: curToken, value: value)
  }

  func parsePrefixExpression() throws -> Expression {
    let token      = curToken!
    let `operator` = token.literal
    nextToken()
    let right = try parseExpression(.prefix)
    return PrefixExpression(token: token, operator: `operator`, right: right)
  }

  func parseInfixExpression(left: Expression) throws -> Expression {
    let token      = curToken!
    let `operator` = token.literal
    let precedence = Precedence(curToken.type)
    nextToken()
    let right = try parseExpression(precedence)
    return InfixExpression(token: token, left: left, operator: `operator`, right: right)
  }

  func parseBoolean() -> Expression {
    BooleanExpression(token: curToken, value: curToken.type == .true)
  }

  func parseGroupedExpression() throws -> Expression {
    nextToken()
    let exp = try parseExpression(.lowest)
    try expectPeek(.rightParen)
    return exp
  }

  func parseIfExpression() throws -> Expression {
    let token = curToken!
    try expectPeek(.leftParen)
    nextToken()

    let condition = try parseExpression(.lowest)
    try expectPeek(.rightParen)
    try expectPeek(.leftBrace)

    let consequence = try parseBlockStatement()
    var alternative: BlockStatement?
    if peekToken.type == .else {
      nextToken()
      try expectPeek(.leftBrace)
      alternative = try parseBlockStatement()
    }
    return IfExpression(
      token: token,condition: condition,
      consequence: consequence, alternative: alternative)
  }

  func parseFunctionLiteral() throws -> Expression {
    let token = curToken!
    try expectPeek(.leftParen)

    let params = try parseFunctionParameters()
    try expectPeek(.leftBrace)
    let body = try parseBlockStatement()
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

    try expectPeek(.rightParen)
    return idents
  }

  func parseCallExpression(_ function: Expression) throws -> Expression {
    let token     = curToken!
    let arguments = try parseExpressionList(.rightParen)
    return CallExpression(token: token, arguments: arguments, function: function)
  }

  func parseCallArguments() throws -> [Expression] {
    var args: [Expression] = []
    if peekToken.type == .rightParen {
      nextToken()
      return args
    }
    nextToken()
    args.append(try parseExpression(.lowest))
    while peekToken.type == .comma {
      nextToken()
      nextToken()
      args.append(try parseExpression(.lowest))
    }

    try expectPeek(.rightParen)
    return args
  }

  func parseStringLiteral() -> Expression {
    return StringLiteral(token: curToken, value: curToken.literal)
  }

  func parseArrayLiteral() throws -> Expression {
    let token    = curToken!
    let elements = try parseExpressionList(.rightBracket)
    return ArrayLiteral(token: token, elements: elements)
  }

  func parseExpressionList(_ end: Token.`Type`) throws -> [Expression] {
    var list: [Expression] = []
    if peekToken.type == end {
      nextToken()
      return list
    }
    nextToken()
    list.append(try parseExpression(.lowest))
    while peekToken.type == .comma {
      nextToken()
      nextToken()
      list.append(try parseExpression(.lowest))
    }

    try expectPeek(end)
    return list
  }

  func parseIndexExpression(_ left: Expression) throws -> Expression {
    let token = curToken!
    nextToken()
    let index = try parseExpression(.lowest)
    try expectPeek(.rightBracket)
    return IndexExpression(token: token, left: left, index: index)
  }

  func parseHashLiteral() throws -> Expression {
    var hash = HashLiteral(token: curToken)
    while peekToken.type != .rightBrace {
      nextToken()
      let key = try parseExpression(.lowest)
      try expectPeek(.colon)
      nextToken()
      let value = try parseExpression(.lowest)
      hash.store[key as! AnyHashable] = value
      if peekToken.type != .rightBrace {
        try expectPeek(.comma)
      }
    }
    try expectPeek(.rightBrace)
    return hash
  }
}
