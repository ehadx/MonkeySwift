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
  var env      = Enviroment()
  var macroEnv = Enviroment() 
  while true {
    print(prompt, terminator: "")
    if let input = readLine() {
      let parser    = Parser(input)
      var program   = parser.parseProgram()
      if program.count == 0 {
        continue
      }
      defineMacros(&program, &macroEnv)
      let expanded  = expandMacros(program, &macroEnv)
      let evaluated = eval(expanded, &env)
      print("-> \(evaluated.inspect())")
    }
  }
}
