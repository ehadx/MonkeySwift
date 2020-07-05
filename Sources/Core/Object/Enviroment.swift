//===-- Enviroment --------------------------------------------*- Swift -*-===//
//
// Keeps track of bindings and the values associated to them.
//
//===----------------------------------------------------------------------===//

public class Enviroment { 
  var store: [String: Object] = [:]
  let outer: Enviroment?

  public init(outer: Enviroment? = nil) {
    self.outer = outer
  }

  subscript(name: String) -> Object? {
    get {
      var object: Object?
      if let obj = store[name] {
        object = obj
      } else if let out = outer {
        object = out[name]
      }
      return object
    }

    set {
      store[name] = newValue
    }
  }
}

let builtins: [String: Builtin] = [
  "len": Builtin(
    fn: { (args: Object...) -> Object in
      if args.count != 1 {
        return ErrorObj(message: "wrong number of arguments. got=\(args.count), want=1")
      }
      if let arr = args[0] as? ArrayObj {
        return Integer(value: Int64(arr.elements.count))
      }
      if let str = args[0] as? StringObj {
        return Integer(value: Int64(str.value.count))
      }
      return ErrorObj(message: "argument to `len` not supported, got \(type(of: args[0]))")
    }
  ),
  "first": Builtin(
    fn: { (args: Object...) -> Object in
      if args.count != 1 {
        return ErrorObj(message: "wrong number of arguments. got=\(args.count), want=1")
      }
      guard let arr = args[0] as? ArrayObj else {
        return ErrorObj(message: "argument to `first` must be array, got \(type(of: args[0]))")
      }
      return arr.elements.first != nil ? arr.elements.first! : Null()
    }
  ),
  "last": Builtin(
    fn: { (args: Object...) -> Object in
      if args.count != 1 {
        return ErrorObj(message: "wrong number of arguments. got=\(args.count), want=1")
      }
      guard let arr = args[0] as? ArrayObj else {
        return ErrorObj(message: "argument to `last` must be array, got \(type(of: args[0]))")
      }
      return arr.elements.last != nil ? arr.elements.last! : Null()
    }
  ),
  "rest": Builtin(
    fn: { (args: Object...) -> Object in
      if args.count != 1 {
        return ErrorObj(message: "wrong number of arguments. got=\(args.count), want=1")
      }
      guard let arr = args[0] as? ArrayObj else {
        return ErrorObj(message: "argument to `rest` must be array, got \(type(of: args[0]))")
      }
      guard arr.elements.count > 0 else {
        return Null()
      }
      let newElems = Array(arr.elements[1...])
      return newElems.count > 0 ? ArrayObj(elements: newElems) : Null()
    }
  ),
  "push": Builtin(
    fn: { (args: Object...) -> Object in
      if args.count != 2 {
        return ErrorObj(message: "wrong number of arguments. got=\(args.count), want=2")
      }
      guard let arr = args[0] as? ArrayObj else {
        return ErrorObj(message: "argument to `rest` must be array, got \(type(of: args[0]))")
      }
      var newElems = arr.elements
      newElems.append(args[1])
      return ArrayObj(elements: newElems)
    }
  ),
  "puts": Builtin(
    fn: { (args: Object...) -> Object in
      for arg in args {
        print(arg.inspect())
      }
      return Null()
    }
  )
]
