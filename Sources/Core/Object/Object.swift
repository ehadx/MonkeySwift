//===-- Object ------------------------------------------------*- Swift -*-===//
//
// This file implements the monkey object system.
//
//===----------------------------------------------------------------------===//

public enum ObjectType {
  case integer
  case boolean
  case string
  case array
  case hash
  case null
  case returnValue
  case error
  case function
  case builtin
}

// we’re going to represent every value we encounter when evaluating Monkey
// source code as an Object, Every value will be wrapped inside a struct, which
// fulfills this Object protocol.
//
public protocol Object {
  var type: ObjectType { get }
  func inspect() -> String
}

extension Object {
  static func ==(lhs: Self, rhs: Self) -> Bool { lhs.inspect() == rhs.inspect() }

  func hash(into: inout Hasher) {
    into.combine(inspect())
  }
}

struct Integer: Object, Hashable {
  let value: Int64
  let type = ObjectType.integer

  func inspect() -> String { String(value) }
}

struct Boolean: Object, Hashable {
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

struct StringObj: Object, Hashable {
  let type = ObjectType.string
  let value: String

  func inspect() -> String { value }
}

typealias BuiltinFunction = (_ args: Object...) -> Object

struct Builtin: Object {
  let type = ObjectType.builtin
  let fn: BuiltinFunction

  func inspect() -> String { "builtin function" }
}

struct ArrayObj: Object {
  let type = ObjectType.array
  let elements: [Object]

  func inspect() -> String {
    var buffer = ""
    var elems: [String] = []
    for e in elements {
      elems.append(e.inspect())
    }
    buffer += "["
    buffer += elems.joined(separator: ", ")
    buffer += "]"
    return buffer;
  }
}

struct Hash: Object {
  let type = ObjectType.hash
  var store: [AnyHashable: Object]

  func inspect() -> String {
    var buffer = ""
    var store: [String] = []
    for (key, value) in self.store {
      store.append("\((key as! Object).inspect()): \(value.inspect())")
    }
    buffer += "{"
    buffer += store.joined(separator: ", ")
    buffer += "}"
    return buffer
  }
}
