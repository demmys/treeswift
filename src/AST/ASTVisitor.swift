public protocol ASTVisitor {
    // ProcedureAST
    func visit(node: FlowSwitch) throws
    func visit(node: ForFlow) throws
    func visit(node: ForInFlow) throws
    func visit(node: WhileFlow) throws
    func visit(node: RepeatWhileFlow) throws
    func visit(node: IfFlow) throws
    func visit(node: GuardFlow) throws
    func visit(node: DeferFlow) throws
    func visit(node: DoFlow) throws
    func visit(node: CatchFlow) throws
    func visit(node: CaseFlow) throws
    func visit(node: Operation) throws
    // DeclarationAST
    func visit(node: Module) throws
    func visit(node: TopLevelDeclaration) throws
    func visit(node: ImportDeclaration) throws
    func visit(node: PatternInitializerDeclaration) throws
    func visit(node: VariableBlockDeclaration) throws
    func visit(node: VariableBlock) throws
    func visit(node: TypealiasDeclaration) throws
    func visit(node: FunctionDeclaration) throws
    func visit(node: EnumDeclaration) throws
    func visit(node: StructDeclaration) throws
    func visit(node: ClassDeclaration) throws
    func visit(node: ProtocolDeclaration) throws
    func visit(node: InitializerDeclaration) throws
    func visit(node: DeinitializerDeclaration) throws
    func visit(node: ExtensionDeclaration) throws
    func visit(node: SubscriptDeclaration) throws
    func visit(node: OperatorDeclaration) throws
    // ExpressionAST
    func visit(node: Expression) throws
    func visit(node: BinaryExpressionBody) throws
    func visit(node: ConditionalExpressionBody) throws
    func visit(node: TypeCastingExpressionBody) throws
    func visit(node: ExpressionUnit) throws
    func visit(node: ExpressionCore) throws
    // PatternAST
    func visit(node: IdentityPattern) throws
    func visit(node: BooleanPattern) throws
    func visit(node: ConstantIdentifierPattern) throws
    func visit(node: VariableIdentifierPattern) throws
    func visit(node: ReferenceIdentifierPattern) throws
    func visit(node: WildcardPattern) throws
    func visit(node: TuplePattern) throws
    func visit(node: VariableBindingPattern) throws
    func visit(node: ConstantBindingPattern) throws
    func visit(node: OptionalPattern) throws
    func visit(node: TypeCastingPattern) throws
    func visit(node: EnumCasePattern) throws
    func visit(node: TypePattern) throws
    func visit(node: ExpressionPattern) throws
}

public protocol ASTNode {
    func accept(visitor: ASTVisitor) throws
}

// ProcedureAST
extension Procedure : ASTNode {
    public func accept(visitor: ASTVisitor) throws {
        switch self {
        case let .DeclarationProcedure(p): try p.accept(visitor)
        case let .OperationProcedure(p): try p.accept(visitor)
        case let .FlowProcedure(p): try p.accept(visitor)
        case let .FlowSwitchProcedure(p): try p.accept(visitor)
        }
    }
}

extension Operation {
    public func accept(visitor: ASTVisitor) throws { try visitor.visit(self) }
}

extension FlowSwitch {
    public func accept(visitor: ASTVisitor) throws { try visitor.visit(self) }
}

extension Flow {
    public func accept(visitor: ASTVisitor) throws {
        switch self {
        case let f as ForFlow: try visitor.visit(f)
        case let f as ForInFlow: try visitor.visit(f)
        case let f as WhileFlow: try visitor.visit(f)
        case let f as RepeatWhileFlow: try visitor.visit(f)
        case let f as IfFlow: try visitor.visit(f)
        case let f as GuardFlow: try visitor.visit(f)
        case let f as DeferFlow: try visitor.visit(f)
        case let f as DoFlow: try visitor.visit(f)
        case let f as CatchFlow: try visitor.visit(f)
        case let f as CaseFlow: try visitor.visit(f)
        default: assert(false, "<system error> Unexpected type of flow.")
        }
    }
}

// DeclarationAST
extension Module : ASTNode {
    public func accept(visitor: ASTVisitor) throws { try visitor.visit(self) }
}

extension TopLevelDeclaration : ASTNode {
    public func accept(visitor: ASTVisitor) throws { try visitor.visit(self) }
}

extension Declaration : ASTNode {
    public func accept(visitor: ASTVisitor) throws {
        switch self {
        case let d as ImportDeclaration: try visitor.visit(d)
        case let d as PatternInitializerDeclaration: try visitor.visit(d)
        case let d as VariableBlockDeclaration: try visitor.visit(d)
        case let d as TypealiasDeclaration: try visitor.visit(d)
        case let d as FunctionDeclaration: try visitor.visit(d)
        case let d as EnumDeclaration: try visitor.visit(d)
        case let d as StructDeclaration: try visitor.visit(d)
        case let d as ClassDeclaration: try visitor.visit(d)
        case let d as ProtocolDeclaration: try visitor.visit(d)
        case let d as InitializerDeclaration: try visitor.visit(d)
        case let d as DeinitializerDeclaration: try visitor.visit(d)
        case let d as ExtensionDeclaration: try visitor.visit(d)
        case let d as SubscriptDeclaration: try visitor.visit(d)
        case let d as OperatorDeclaration: try visitor.visit(d)
        default: assert(false, "<system error> Unexpected type of declaration.")
        }
    }
}

extension VariableBlock : ASTNode {
    public func accept(visitor: ASTVisitor) throws { try visitor.visit(self) }
}

// ExpressionAST
extension Expression : ASTNode {
    public func accept(visitor: ASTVisitor) throws { try visitor.visit(self) }
}

extension ExpressionBody : ASTNode {
    public func accept(visitor: ASTVisitor) throws {
        switch self {
        case let e as BinaryExpressionBody: try visitor.visit(e)
        case let e as ConditionalExpressionBody: try visitor.visit(e)
        case let e as TypeCastingExpressionBody: try visitor.visit(e)
        default: assert(false, "<system error> Unexpected type of declaration.")
        }
    }
}

extension ExpressionUnit : ASTNode {
    public func accept(visitor: ASTVisitor) throws { try visitor.visit(self) }
}

extension ExpressionCore : ASTNode {
    public func accept(visitor: ASTVisitor) throws { try visitor.visit(self) }
}

// PatternAST
extension Pattern : ASTNode {
    public func accept(visitor: ASTVisitor) throws {
        switch self {
        case let p as IdentityPattern: try visitor.visit(p)
        case let p as BooleanPattern: try visitor.visit(p)
        case let p as ConstantIdentifierPattern: try visitor.visit(p)
        case let p as VariableIdentifierPattern: try visitor.visit(p)
        case let p as ReferenceIdentifierPattern: try visitor.visit(p)
        case let p as WildcardPattern: try visitor.visit(p)
        case let p as TuplePattern: try visitor.visit(p)
        case let p as VariableBindingPattern: try visitor.visit(p)
        case let p as ConstantBindingPattern: try visitor.visit(p)
        case let p as OptionalPattern: try visitor.visit(p)
        case let p as TypeCastingPattern: try visitor.visit(p)
        case let p as EnumCasePattern: try visitor.visit(p)
        case let p as TypePattern: try visitor.visit(p)
        case let p as ExpressionPattern: try visitor.visit(p)
        default: assert(false, "<system error> Unexpected type of declaration.")
        }
    }
}
