// FileScope
import Foundation
typealias A = Int
let a = 0
var b = 0
func c() {}
enum B {}
struct C {}
class D {}
protocol E {}
extension D {}
prefix operator +++ {}
// case A
var type: Int
print("value")
"" + "operator"
let enumCase: Optional<Int> = .None
// $0

// ImplicitScope
import Darwin // NOTE: import at parent file scope
typealias F = Int
let d = 0
var e = 0
func f() {}
enum G {}
struct H {}
class I {}
protocol J {}
extension I {}
prefix operator ++++ {}
// case A
var type_: Int
print("value")
"" + "operator"
let enumCase_: Optional<Int> = .None
let implicitParameter: Int -> () = {
    let a = 0
    print($0)
}

// FlowScope
if true {
    // import CoreGraphics
    typealias A = Int
    let a = 0
    var b = 0
    func c() {}
    enum B {}
    struct C {}
    class D {}
    // protocol E {}
    // extension D {}
    // prefix operator +++ {}
    // case A
    var type: Int
    print("value")
    "" + "operator"
    let enumCase: Optional<Int> = .None
    let implicitParameter: Int -> () = {
        if true {
            print($0)
        }
    }
}
while a == 1 {
    // import CoreGraphics
    typealias A = Int
    let a = 0
    var b = 0
    func c() {}
    enum B {}
    struct C {}
    class D {}
    // protocol E {}
    // extension D {}
    // prefix operator +++ {}
    // case A
    var type: Int
    print("value")
    "" + "operator"
    let enumCase: Optional<Int> = .None
    let implicitParameter: Int -> () = {
        if true {
            print($0)
        }
    }
}
repeat {
    // import CoreGraphics
    typealias A = Int
    let a = 0
    var b = 0
    func c() {}
    enum B {}
    struct C {}
    class D {}
    // protocol E {}
    // extension D {}
    // prefix operator +++ {}
    // case A
    var type: Int
    print("value")
    "" + "operator"
    let enumCase: Optional<Int> = .None
    let implicitParameter: Int -> () = {
        if true {
            print($0)
        }
    }
} while a == 1
for ; a == 1; {
    // import CoreGraphics
    typealias A = Int
    let a = 0
    var b = 0
    func c() {}
    enum B {}
    struct C {}
    class D {}
    // protocol E {}
    // extension D {}
    // prefix operator +++ {}
    // case A
    var type: Int
    print("value")
    "" + "operator"
    let enumCase: Optional<Int> = .None
    let implicitParameter: Int -> () = {
        if true {
            print($0)
        }
    }
}
for i in [0] {
    // import CoreGraphics
    typealias A = Int
    let a = 0
    var b = 0
    func c() {}
    enum B {}
    struct C {}
    class D {}
    // protocol E {}
    // extension D {}
    // prefix operator +++ {}
    // case A
    var type: Int
    print("value")
    "" + "operator"
    let enumCase: Optional<Int> = .None
    let implicitParameter: Int -> () = {
        if true {
            print($0)
        }
    }
}
switch a {
case 0:
    // import CoreGraphics
    typealias A = Int
    let a = 0
    var b = 0
    func c() {}
    enum B {}
    struct C {}
    class D {}
    // protocol E {}
    // extension D {}
    // prefix operator +++ {}
    // case A
    var type: Int
    print("value")
    "" + "operator"
    let enumCase: Optional<Int> = .None
    let implicitParameter: Int -> () = {
        if true {
            print($0)
        }
    }
default:
    break
}

// FunctionScope
func g() {
    // import CoreGraphics
    typealias A = Int
    let a = 0
    var b = 0
    func c() {}
    enum B {}
    struct C {}
    class D {}
    // protocol E {}
    // extension D {}
    // prefix operator +++ {}
    // case A
    var type: Int
    print("value")
    "" + "operator"
    let enumCase: Optional<Int> = .None
    // let implicitParameter: Int -> () = {
    //     func a() {
    //         print($0)
    //     }
    // }
}
var h: Int {
    // import CoreGraphics
    typealias A = Int
    let a = 0
    var b = 0
    func c() {}
    enum B {}
    struct C {}
    class D {}
    // protocol E {}
    // extension D {}
    // prefix operator +++ {}
    // case A
    var type: Int
    print("value")
    "" + "operator"
    let enumCase: Optional<Int> = .None
    // let implicitParameter: Int -> () = {
    //     var a: Int {
    //         return $0
    //     }
    // }
    return 0
}
class K {
    init() {
        // import CoreGraphics
        typealias A = Int
        let a = 0
        var b = 0
        func c() {}
        enum B {}
        struct C {}
        class D {}
        // protocol E {}
        // extension D {}
        // prefix operator +++ {}
        // case A
        var type: Int
        print("value")
        "" + "operator"
        let enumCase: Optional<Int> = .None
        // let implicitParameter: Int -> () = {
        //     class A {
        //         init() {
        //             print($0)
        //         }
        //     }
        // }
    }
    deinit {
        // import CoreGraphics
        typealias A = Int
        let a = 0
        var b = 0
        func c() {}
        enum B {}
        struct C {}
        class D {}
        // protocol E {}
        // extension D {}
        // prefix operator +++ {}
        // case A
        var type: Int
        print("value")
        "" + "operator"
        let enumCase: Optional<Int> = .None
        // let implicitParameter: Int -> () = {
        //     class A {
        //         deinit {
        //             print($0)
        //         }
        //     }
        // }
    }
    subscript(a: Int) -> Int {
        // import CoreGraphics
        typealias A = Int
        let a = 0
        var b = 0
        func c() {}
        enum B {}
        struct C {}
        class D {}
        // protocol E {}
        // extension D {}
        // prefix operator +++ {}
        // case A
        var type: Int
        print("value")
        "" + "operator"
        let enumCase: Optional<Int> = .None
        // let implicitParameter: Int -> () = {
        //     class A {
        //         subscript(a: Int) -> Int {
        //             print($0)
        //             return 0
        //         }
        //     }
        // }
        return 0
    }
}

// ClosureScope
let x: Int -> () = {
    // import CoreGraphics
    typealias A = Int
    let a = 0
    var b = 0
    func c() {}
    enum B {}
    struct C {}
    class D {}
    // protocol E {}
    // extension D {}
    // prefix operator +++ {}
    // case A
    var type: Int
    print("value")
    "" + "operator"
    let enumCase: Optional<Int> = .None
    print($0)
}

// EnumScope
enum L {
    // import CoreGraphics
    typealias A = Int
    // let a = 0
    var b: Int { return 0 }
    func c() {}
    enum B {}
    struct C {}
    class D {}
    // protocol E {}
    // extension D {}
    // prefix operator +++ {}
    case E
    var type: Int { return 0 }
    // print("value")
    // let a = "" + "operator"
    // let enumCase: Optional<Int> = .None
    // let implicitParameter: Int -> () = {
    //     enum A {
    //         let a = print($0)
    //     }
    // }
}

// StructScope
struct M {
    // import CoreGraphics
    typealias A = Int
    let a = 0
    var b = 0
    func c() {}
    enum B {}
    struct C {}
    class D {}
    // protocol E {}
    // extension D {}
    // prefix operator +++ {}
    // case A
    var type: Int
    let d = print("value")
    let e = "" + "operator"
    let enumCase: Optional<Int> = .None
    // let implicitParameter: Int -> () = {
    //     struct A {
    //         let f = $0
    //     }
    // }
}

// ClassScope
class N {
    // import CoreGraphics
    typealias A = Int
    let a = 0
    var b = 0
    func c() {}
    enum B {}
    struct C {}
    class D {}
    // protocol E {}
    // extension D {}
    // prefix operator +++ {}
    // case A
    let type: Int = 0
    let d = print("value")
    let e = "" + "operator"
    let enumCase: Optional<Int> = .None
    // let implicitParameter: Int -> () = {
    //     class A {
    //         let f = $0
    //     }
    // }
}

// ProtocolScope
protocol O {
    // import CoreGraphics
    typealias E = Int
    // let a = 0
    var f: Int { get }
    func g()
    // enum F {}
    // struct G {}
    // class H {}
    // protocol I {}
    // extension J {}
    // prefix operator +++ {}
    // case K
    var type: Int { get }
    // let h = print("value")
    // let i = "" + "operator"
    // let enumCase: Optional<Int> = .None
    // let implicitParameter: Int -> () = {
    //     protocol A {
    //         let f = $0
    //     }
    // }
}

// ExtensionScope
extension N {
    // import CoreGraphics
    typealias E = Int
    // let a = 0
    var f: Int { return 0 }
    func g() {}
    enum F {}
    struct G {}
    class H {}
    // protocol I {}
    // extension J {}
    // prefix operator +++ {}
    // case K
    var type_: Int { return 0 }
    // let h = print("value")
    // let i = "" + "operator"
    // let enumCase: Optional<Int> = .None
    // let implicitParameter: Int -> () = {
    //     extension A {
    //         let f = $0
    //     }
    // }
}
