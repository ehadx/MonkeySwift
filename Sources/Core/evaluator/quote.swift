//===-- quote -------------------------------------------------*- Swift -*-===//
//
// Implements quote/unquote functionality.
//
//===----------------------------------------------------------------------===//

func quote(_ node: Node, _ env: inout Enviroment) -> Object {
  let node = evalUnquoteCalls(node, &env)
  return Quote(node: node)
}

func evalUnquoteCalls(_ quoted: Node, _ env: inout Enviroment) -> Node {
  return modify(quoted) {
    guard isUnquoteCall($0) else {
      return $0
    }

    guard let call = $0 as? CallExpression else {
      return $0
    }

    guard call.arguments.count == 1 else {
      return $0
    }

    let unquoted = eval(call.arguments[0], &env)
    return convertObjectToASTNode(unquoted)
  }
}

func convertObjectToASTNode(_ obj: Object) -> Node {
  switch obj {
  case let o as Integer: return    IntegerLiteral(token: Token(number : String(o.value)) , value: o.value)
  case let o as Boolean: return BooleanExpression(token: Token(keyword: String(o.value))!, value: o.value)
  case let o as Quote  : return    o.node
  default:
    fatalError("\(type(of: obj)) cannot be converted to an AST Node")
    return IntegerLiteral(token: Token(number: "0"), value: 0) // dummy
  }
}

func isUnquoteCall(_ node: Node) -> Bool {
  guard let callExpression = node as? CallExpression else {
    return false
  }
  return callExpression.function.tokenLiteral() == "unquote"
}
