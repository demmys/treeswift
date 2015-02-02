import Parser

enum Association {
    case Prefix, Postfix
    case Infix(Associativity, Int)
    case Assignment(Associativity, Int)
}

class Operator {
    let association: Association

    init(_ association: Association) {
        self.association = association
    }

    func apply(c: Context, x: Value) -> Value {
        assert(false, "Unimplemented operator")
    }

    func apply(c: Context, a: Value, b: Value) -> Value {
        assert(false, "Unimplemented operator")
    }
}

/*
 * Prefix operators
 */
class PrefixPositive : Operator {
    init() {
        super.init(.Prefix)
    }
}

class PrefixNegative : Operator {
    init() {
        super.init(.Prefix)
    }
}

class PrefixIncrement : Operator {
    init() {
        super.init(.Prefix)
    }
}

class PrefixDecrement : Operator {
    init() {
        super.init(.Prefix)
    }
}

/*
 * Postfix operators
 */
class PostfixIncrement : Operator {
    init() {
        super.init(.Postfix)
    }
}

class PostfixDecrement : Operator {
    init() {
        super.init(.Postfix)
    }
}

/*
 * Infix
 */
class InfixAdd : Operator {
    init() {
        super.init(.Infix(.Left, 140))
    }

    override func apply(c: Context, a: Value, b: Value) -> Value {
        c.builder.setInsertPoint(c.block)
        return c.builder.createAdd(a, b, c.getTemporaryName())
    }
}

class InfixSub : Operator {
    init() {
        super.init(.Infix(.Left, 140))
    }

    override func apply(c: Context, a: Value, b: Value) -> Value {
        c.builder.setInsertPoint(c.block)
        return c.builder.createSub(a, b, c.getTemporaryName())
    }
}

class InfixMul : Operator {
    init() {
        super.init(.Infix(.Left, 150))
    }
}

class InfixDiv : Operator {
    init() {
        super.init(.Infix(.Left, 150))
    }
}

class InfixLessThan : Operator {
    init() {
        super.init(.Infix(.None, 130))
    }

    override func apply(c: Context, a: Value, b: Value) -> Value {
        c.builder.setInsertPoint(c.block)
        return c.builder.createICmpSLT(a, b, c.getTemporaryName())
    }
}

class InfixGreaterThan : Operator {
    init() {
        super.init(.Infix(.None, 130))
    }
}

class InfixAddAssign : Operator {
    init() {
        super.init(.Assignment(.Right, 90))
    }
}

class InfixSubAssign : Operator {
    init() {
        super.init(.Assignment(.Right, 90))
    }
}

class InfixMulAssign : Operator {
    init() {
        super.init(.Assignment(.Right, 90))
    }
}

class InfixDivAssign : Operator {
    init() {
        super.init(.Assignment(.Right, 90))
    }
}
