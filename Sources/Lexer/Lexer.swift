//===-- Lexer -------------------------------------------------*- Swift -*-===//
//
// This module implements the monkey lexer.
// The lexer will take source code as input and output the tokens that
// represent the source code. It will go through its input and output the
// next token it recognizes.
//
//===----------------------------------------------------------------------===//

public struct Lexer {
  // Again: in a production environment it makes sense to attach filenames
  // and line numbers to tokens, to better track down lexing and parsing
  // errors. But since that would add more complexity we’re not here to
  // handle, we’ll start small and just use a string and ignore filenames and
  // line numbers.
  //
  private let input: String

  // current position in input (points to current char)
  //
  private var position: Int

  // current reading position in input (after current char)
  //
  private var readPosition: Int

  // current char under examination
  // the lexer only supports ASCII characters instead of the full Unicode
  // range. Because this lets us keep things simple and concentrate on the
  // essential parts of our interpreter.
  // or maybe it does!!? swift Characters are unicode!
  // 
  private var char: Character

  public init(input: String) { 
    self.input = input
    position = 0
    readPosition = 0
    char = "\0"

    readChar()
  }

  // Gives us the next character and advance our position in the input string.
  //
  private mutating func readChar() {
    if readPosition >= input.count {      // we have reached the end of input
      // “we haven’t read anything yet” or “end of file”
      //
      char = "\0"
    } else {
      let readIndex = String.Index(utf16Offset: readPosition, in: input)
      char = input[readIndex]
    }

    position = readPosition

    // always points to the next position where we’re going to read
    // from next.
    //
    readPosition += 1
  }

  // Similar to readChar() execpt that it doesn’t increment position and
  // readPosition We only want to “peek” ahead in the input and not move 
  // around in it
  //
  private func peekChar() -> Character {
    if readPosition >= input.count {
      return "\0"
    } else {
      let readIndex = String.Index(utf16Offset: readPosition, in: input)
      return input[readIndex]
    }
  }

  // We look at the current character under examination and return a token 
  // depending on which character it is. Before returning the token we advance
  // our pointers into the input so when we call nextToken() again the char
  // field is already updated.
  //
  public mutating func nextToken() -> Token {
    var tok: Token

    skipWhitespace()

    switch char {
    case "=" :
      if peekChar() == "=" {      // the next token is also "="
        let ch = char
        readChar()
        tok = Token(type: .EQ, literal: String(ch) + String(char))
      } else {
        tok = Token(type: .ASSIGN, literal: String(char))
      }
    case "!" : 
      if peekChar() == "=" {
        let ch = char
        readChar()
        tok = Token(type: .NOT_EQ, literal: String(ch) + String(char))
      } else {
        tok = Token(type: .BANG, literal: String(char))
      }
    case "+" : tok = Token(type: .PLUS     , literal: String(char))
    case "-" : tok = Token(type: .MINUS    , literal: String(char))
    case "/" : tok = Token(type: .SLASH    , literal: String(char))
    case "*" : tok = Token(type: .ASTERISK , literal: String(char))
    case "<" : tok = Token(type: .LT       , literal: String(char))
    case ">" : tok = Token(type: .GT       , literal: String(char))
    case ";" : tok = Token(type: .SEMICOLON, literal: String(char))
    case "," : tok = Token(type: .COMMA    , literal: String(char))
    case "(" : tok = Token(type: .LPAREN   , literal: String(char))
    case ")" : tok = Token(type: .RPAREN   , literal: String(char))
    case "{" : tok = Token(type: .LBRACE   , literal: String(char))
    case "}" : tok = Token(type: .RBRACE   , literal: String(char))
    case "\0": tok = Token(type: .EOF      , literal: ""          )
    default:
      // check for identifiers or numbers whenever the char is not one of the
      // recognized characters.
      //
      if isLetter(char) {
        let literal = readIdentifier()
        let type = lookupIdent(literal)
        return Token(type: type, literal: literal)
      } else if isDigit(char) {
        let number = readNumber()
        return Token(type: .INT, literal: number)
      } else {
        tok = Token(type: .ILLEGAL, literal: String(char))
      }
    }

    readChar()
    return tok
  }

  // Reads the identifier/keyword until it encounters a non-letter-character
  //
  private mutating func readIdentifier() -> String {
    let position = self.position
    while isLetter(char) {
      readChar()
    }
    let start = String.Index(utf16Offset:      position, in: input)
    let end   = String.Index(utf16Offset: self.position, in: input)
    return String(input[start..<end])
  }

  // exactly the same as readIdentifier except for its usage of isDigit 
  // instead of isLetter.
  // We only read in integers. What about floats? Or numbers in hex
  // notation? Octal notation? We ignore them and just say that Monkey
  // doesn’t support this. Of course, the reason for this is again the
  // educational aim and limited scope of this book.
  //
  private mutating func readNumber() -> String {
    let position = self.position
    while isDigit(char) {
      readChar()
    }
    let start = String.Index(utf16Offset:      position, in: input)
    let end   = String.Index(utf16Offset: self.position, in: input)
    return String(input[start..<end])
  }

  // The isLetter helper function just checks whether the given argument is a
  // letter. That sounds easy enough, but what’s noteworthy about isLetter is
  // that changing this function has a larger impact on the language than one
  // would expect from such a small function.
  // As you can see, in our case it contains the check char == '_', which
  // means that we’ll treat _ as a letter and allow it in identifiers and
  // keywords. That means we can use variable names like foo_bar.
  // Other programming languages even allow ! and ? in identifiers. If you
  // want to allow that too, this is the place to sneak it in.
  //
  private func isLetter(_ char: Character) -> Bool { char.isLetter || char == "_" }

  // The isDigit function is as simple as isLetter. It just returns whether the
  // passed in byte is a Latin digit between 0 and 9.
  //
  private func isDigit(_ char: Character) -> Bool { "0" <= char && char <= "9" }

  private mutating func skipWhitespace() {
    while char.isWhitespace {
      readChar()
    }
  }
}
