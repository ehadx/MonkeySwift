//===-- Lexer -------------------------------------------------*- Swift -*-===//
//
// This file implements the monkey lexer.
// The lexer will take source code as input and output the tokens that
// represent the source code. It will go through its input and output the
// next token it recognizes.
//
//===----------------------------------------------------------------------===//

 public struct Lexer {
  // TODO: attach filename and line numbers to tokens
  //
  let input: String

  // current position in input (points to current char)
  //
  var position: Int

  // current reading position in input (after current char)
  //
  var readPosition: Int

  // current char under examination
  // 
  var char: Character

  public init(_ input: String) { 
    self.input = input
    position = 0
    readPosition = 0
    char = "\0"
    readChar()
  }

  // Gives us the next character and advance our position in the input string.
  //
  mutating func readChar() {
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

  // See what the next char is without incrementing the position
  //
  func peekChar() -> Character {
    if readPosition >= input.count {
      return "\0"
    } else {
      let readIndex = String.Index(utf16Offset: readPosition, in: input)
      return input[readIndex]
    }
  }

  // looks at the current character under examination and return a token 
  // depending on which character it is. Before returning the token we advance
  // our pointers into the input so when we call nextToken() again the char
  // field is already updated.
  //
  public mutating func nextToken() -> Token {
    var literal: String
    skipWhitespace()

    switch char {
    case "=", "!":
      if peekChar() == "=" {      // the next token is also "="
        literal = String(char) + "="
        readChar()
      } else {
        fallthrough
      }
    case "+", "-", "/", "*", "<", ">", ";", ",", "(", ")", "{", "}", "[", "]", ":", "\0":
      literal = String(char)
    case "\"":
      let stringToken = Token(string: readString())
      readChar()
      return stringToken
    default:
      // check for identifiers or numbers whenever the char is not one of the
      // recognized characters.
      //
      if Lexer.isLetter(char) {
        let literal = readIdentifier();
        guard let keywordToken = Token(keyword: literal) else {
          return Token(ident: literal)
        }
        return keywordToken
      }
      if Lexer.isDigit(char) {
        return Token(number: readNumber())
      }
      literal = String(char)
    }
    readChar()
    guard let charToken = Token(char: literal) else {
      return Token(illegal: literal)
    }
    return charToken
  }

  // Reads the identifier/keyword until it encounters a non-letter-character
  //
  mutating func readIdentifier() -> String {
    let position = self.position
    // allow numbers after the first letter
    //
    while Lexer.isLetter(char) || Lexer.isDigit(char) {
      readChar()
    }
    let start = String.Index(utf16Offset:      position, in: input)
    let end   = String.Index(utf16Offset: self.position, in: input)
    return String(input[start..<end])
  }

  // exactly the same as readIdentifier except for its usage of isDigit 
  // instead of isLetter.
  // TODO: support floats, doubles, hex, octal and binary notations.
  //
  mutating func readNumber() -> String {
    let position = self.position
    while Lexer.isDigit(char) {
      readChar()
    }
    let start = String.Index(utf16Offset:      position, in: input)
    let end   = String.Index(utf16Offset: self.position, in: input)
    return String(input[start..<end])
  }

  mutating func readString() -> String {
    let position = self.position + 1
    repeat {
      readChar()
    } while char != "\"" && char != "\0"
    let start = String.Index(utf16Offset:      position, in: input)
    let end   = String.Index(utf16Offset: self.position, in: input)
    return String(input[start..<end]) 
  }

  // characters that pass this test is considered valid in identifiers
  // and keywords.
  // latin numbers are valid but not as the 1st character
  //
  static func isLetter(_ char: Character) -> Bool {
    // ascii + unicode letters + _ + digits but not latin digits
    // TODO: support emojis
    //
    char.isLetter || char == "_" || char.isNumber && !isDigit(char)
  }

  // returns whether the passed in byte is a Latin digit between 0 and 9.
  //
  static func isDigit(_ char: Character) -> Bool { "0" <= char && char <= "9" }

  mutating func skipWhitespace() {
    while char.isWhitespace {
      readChar()
    }
  }
}
