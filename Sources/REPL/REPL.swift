//===-- REPL --------------------------------------------------*- Swift -*-===//
//
// This module implements the monkey language's REPL.
// REPL stands for “Read Eval Print Loop”.
// the REPL reads input, sends it to the interpreter for evaluation, prints
// the result/output of the interpreter and starts again.
//
//===----------------------------------------------------------------------===//

import Lexer

private let prompt = ">> "

public func start() {
  while true {
    print(prompt, terminator: "")

    if let input = readLine() {
      var lexer = Lexer(input: input)
      var token = lexer.nextToken()

      while token.type != .EOF {
        print("{Type:\(token.type)} Literal:\(token.literal)}")
        token = lexer.nextToken()
      }
    }
  }
}
