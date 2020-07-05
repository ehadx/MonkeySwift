//===-- REPL --------------------------------------------------*- Swift -*-===//
//
// This module implements the monkey language's REPL.
// REPL stands for “Read Eval Print Loop”.
// the REPL reads input, sends it to the interpreter for evaluation, prints
// the result/output of the interpreter and starts again.
//
//===----------------------------------------------------------------------===//

import Core

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
  print(monkeyFace)
  var env = Enviroment()
  while true {
    print(prompt, terminator: "")
    if let input = readLine() {
      let parser    = Parser(input)
      let program   = parser.parseProgram()
      if program.count == 0 {
        continue
      }
      let evaluated = eval(program, &env)
      print(evaluated.inspect())
    }
  }
}
