//===-- REPL --------------------------------------------------*- Swift -*-===//
//
// This module implements the monkey language's REPL.
// REPL stands for “Read Eval Print Loop”.
// the REPL reads input, sends it to the interpreter for evaluation, prints
// the result/output of the interpreter and starts again.
//
//===----------------------------------------------------------------------===//

import Lexer
import Parser

private let prompt     = ">> "
private let monkeyFace = #"""
            __,__
   .--.  .-"     "-.  .--.
  / .. \/  .-. .-.  \/ .. \
 | |  '|  /   Y   \  |'  | |
 | \   \  \ 0 | 0 /  /   / |
  \ '- ,\.-"""""""-./, -' /
   ''-' /_   ^ ^   _\ '-''
       |  \._   _./  |
       \   \ '~' /   /
        '._ '-=-' _.'
           '-----
"""#

public func start() {
  while true {
    print(prompt, terminator: "")
    if let input = readLine() {
      let parser: Parser = Parser(input: input)
      let program = parser.parseProgram()
      if parser.errors.count != 0 {
        printParserErrors(errors: parser.errors)
        continue
      }
      print(program.asString())
    }
  }
}

private func printParserErrors(errors: [String]) {
  print(monkeyFace)
  print("Woops! We ran into some monkey business here!")
  print(" parser errors:")
  for error in errors {
    print("\t\(error)")
  }
}
