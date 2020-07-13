//===-- modify ------------------------------------------------*- Swift -*-===//
//
// Implements the modify function.
// modify allows us to traverse the AST and change properties in it;
//
//===----------------------------------------------------------------------===//

typealias ModifierFunc = (_ node: Node) -> Node

func modify(_ node: Node, _ modifier: ModifierFunc) -> Node {
  var modified: Node!
  switch node {
  case var n as Program:
    for (i, stmt) in n.statements.enumerated() {
      n.statements[i] = modify(stmt, modifier) as! Statement
    }
    modified = n

  case var n as ExpressionStatement:
    n.expression = modify(n.expression, modifier) as! Expression
    modified = n

  case var n as InfixExpression:
    n.left  = modify(n.left , modifier) as! Expression
    n.right = modify(n.right, modifier) as! Expression
    modified = n

  case var n as PrefixExpression:
    n.right = modify(n.right, modifier) as! Expression
    modified = n

  case var n as IndexExpression:
    n.left  = modify(n.left , modifier) as! Expression
    n.index = modify(n.index, modifier) as! Expression
    modified = n
  
  case var n as IfExpression:
    n.condition   = modify(n.condition  , modifier) as! Expression
    n.consequence = modify(n.consequence, modifier) as! BlockStatement
    if let alt = n.alternative {
      n.alternative = modify(alt, modifier) as? BlockStatement
    }
    modified = n

  case var n as BlockStatement:
    for (i, stmt) in n.statements.enumerated() {
      n.statements[i] = modify(stmt, modifier) as! Statement
    }
    modified = n
  
  case var n as ReturnStatement:
    n.returnValue = modify(n.returnValue, modifier) as! Expression
    modified = n
  
  case var n as LetStatement:
    n.value = modify(n.value, modifier) as! Expression
    modified = n
    
  case var n as FunctionLiteral:
    for (i, param) in n.parameters.enumerated() {
      n.parameters[i] = modify(param, modifier) as! Identifier
    }
    n.body = modify(n.body, modifier) as! BlockStatement
    modified = n
  
  case var n as ArrayLiteral:
    for (i, elem) in n.elements.enumerated() {
      n.elements[i] = modify(elem, modifier) as! Expression
    }
    modified = n

  case var n as HashLiteral:
    var newStore: [AnyHashable: Expression] = [:]
    for (key, value) in n.store {
      let expKey   = key as! Expression
      let newKey   = modify(expKey, modifier) as! Expression
      let newValue = modify(value , modifier) as! Expression
      newStore[newKey as! AnyHashable] = newValue 
    }
    n.store = newStore
    modified = n
    
  default:
    modified = node
    break
  }
  return modifier(modified)  
}
