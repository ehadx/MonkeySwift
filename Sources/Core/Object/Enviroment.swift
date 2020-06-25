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
