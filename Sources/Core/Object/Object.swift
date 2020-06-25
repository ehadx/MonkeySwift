//===-- Object ------------------------------------------------*- Swift -*-===//
//
// This file implements the monkey object system.
//
//===----------------------------------------------------------------------===//

public enum ObjectType {
  case integer
  case boolean
  case null
  case returnValue
  case error
  case function
}

// we’re going to represent every value we encounter when evaluating Monkey
// source code as an Object, Every value will be wrapped inside a struct, which
// fulfills this Object protocol.
//
public protocol Object {
  var type: ObjectType { get }
  func inspect() -> String
}

struct Integer: Object {
  let value: Int64
  let type = ObjectType.integer

  func inspect() -> String { String(value) }
}

struct Boolean: Object, Equatable {
  let value: Bool
  let type = ObjectType.boolean

  func inspect() -> String { String(value) }

  static func == (lhs: Boolean, rhs: Boolean) -> Bool { lhs.value == rhs.value }
}

struct Null: Object {
  let type = ObjectType.null

  func inspect() -> String { "null" }
}

struct ReturnValue: Object {
  let value: Object
  let type = ObjectType.returnValue

  func inspect() -> String { value.inspect() }
}

struct ErrorObj: Object {
  let message: String
  let type = ObjectType.error

  func inspect() -> String { "Error: \(message)" }
}

struct Function: Object {
  let parameters: [Identifier]
  let body      : BlockStatement
  let env       : Enviroment
  let type = ObjectType.function

  func inspect() -> String {
    var buffer = ""
    var params: [String] = []

    for param in parameters {
      params.append(param.asString())
    }

    buffer += "fn"
    buffer += "("
    buffer += params.joined(separator: ", ")
    buffer += ") {\n"
    buffer += body.asString()
    buffer += "\n}"
    return buffer
  }
}
