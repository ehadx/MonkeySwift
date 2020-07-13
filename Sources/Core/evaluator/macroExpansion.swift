//===-- macroExpansion ----------------------------------------*- Swift -*-===//
//
// Implements define/expand macros functionality. 
//
// ===----------------------------------------------------------------------===//

public func defineMacros(_ program: inout Program, _ env: inout Enviroment) {
  for (i, var stmt) in program.statements.enumerated() {
    if isMacroDefinition(stmt) {
      addMacro(&stmt, &env)
      program.statements.remove(at: i)
    }
  }
}

func isMacroDefinition(_ node: Statement) -> Bool {
  guard let letStmt = node as? LetStatement else {
    return false
  }

  guard (letStmt.value as? MacroLiteral) != nil else {
    return false
  }

  return true
}

func addMacro(_ stmt: inout Statement, _ env: inout Enviroment) {
  let letStmt = stmt          as! LetStatement
  let macro   = letStmt.value as! MacroLiteral
  env[letStmt.name.value] = Macro(parameters: macro.parameters, body: macro.body, env: env)
}

public func expandMacros(_ program: Node, _ env: inout Enviroment) -> Node {
  return modify(program) {
    guard let call = $0 as? CallExpression else {
      return $0
    }
    
    guard let macro = isMacroCall(call, &env) else {
      return $0
    }

    let args     = quoteArgs(call)
    var evalEnv  = extendMacroEnv(macro, args)
    let evaluted = eval(macro.body, &evalEnv)

    guard let quote = evaluted as? Quote else {
      fatalError("we only support returning AST-nodes from macros")
      return $0
    }

    return quote.node
  }
}

func isMacroCall(_ exp: CallExpression, _ env: inout Enviroment) -> Macro? {
  guard let ident = exp.function as? Identifier else {
    return nil
  }

  guard let obj = env[ident.value] else {
    return nil
  }

  guard let macro = obj as? Macro else {
    return nil
  }

  return macro
}

func quoteArgs(_ exp: CallExpression) -> [Quote] {
  var args: [Quote] = []
  for arg in exp.arguments {
    args.append(Quote(node: arg))
  }
  return args
}

func extendMacroEnv(_ macro: Macro, _ args: [Quote]) -> Enviroment {
  let extended = Enviroment(outer: macro.env)
  for (i, param) in macro.parameters.enumerated() {
    extended[param.value] = args[i]
  }
  return extended
}
