import Darwin
import Util

public protocol SourceTrackable {
    var sourceInfo: SourceInfo { get }
}

public struct SourceInfo : SourceTrackable {
    public static let PHANTOM: SourceInfo = SourceInfo()
    public var sourceInfo: SourceInfo {
        return self
    }
    public var seekNo: Int
    public var lineNo: Int
    public var charNo: Int

    private init() {
        seekNo = 0
        lineNo = 0
        charNo = 0
    }
    public init(seekNo: Int, lineNo: Int, charNo: Int) {
        self.seekNo = seekNo
        self.lineNo = lineNo
        self.charNo = charNo
    }
}

public enum ErrorKind : CustomStringConvertible {
    case Fatal, Error, Warning

    public var description: String {
        switch self {
        case .Fatal:
            return "fatal"
        case .Error:
            return "error"
        case .Warning:
            return "warning"
        }
    }
}

public typealias Error = (ErrorKind, ErrorMessage, SourceInfo?)

public enum ErrorReport : ErrorType {
    case Fatal
    case Full
    case Found
}

public class ErrorReporter {
    private static var _instance = ErrorReporter()
    public static var instance: ErrorReporter {
        return _instance
    }
    private var errors: [Error] = []
    private var bundledErrors: [(String, [Error])] = []
    private var errorCount: Int = 0

    private init() {}

    public func reset() {
        ErrorReporter._instance = ErrorReporter()
    }

    public func hasErrors() -> Bool {
        return errorCount > 0
    }

    public func bundle(fileName: String) {
        bundledErrors.append((fileName, errors))
        errors = []
    }

    public func fatal(
        message: ErrorMessage, _ source: SourceTrackable?
    ) -> ErrorReport {
        errors.append((.Fatal, message, source?.sourceInfo))
        return .Fatal
    }
    public func error(message: ErrorMessage, _ source: SourceTrackable?) throws {
        errors.append((.Error, message, source?.sourceInfo))
        ++errorCount
        if errorCount > 15 {
            throw ErrorReport.Full
        }
    }
    public func warning(message: ErrorMessage, _ source: SourceTrackable?) {
        errors.append((.Warning, message, source?.sourceInfo))
    }

    public func report() {
        for (fileName, errors) in bundledErrors {
            for (kind, msg, info) in errors {
                if let i = info {
                    print("\(fileName):\(i.lineNo):\(i.charNo) \(kind): \(msg)", toStream: &STDERR)
                    if let file = File(name: fileName, mode: "r") {
                        if file.seek(i.seekNo - i.charNo, whence: .SeekSet) {
                            if let line = file.readLine() {
                                print(line, terminator: "", toStream: &STDERR)
                                printMarker(i.charNo)
                                continue
                            }
                        }
                    }
                    print("(system error: failed to load the source)", toStream: &STDERR)
                } else {
                    print("\(fileName): \(kind): \(msg)", toStream: &STDERR)
                }
            }
        }
        reset()
    }

    private func printMarker(charNo: Int) {
        for var i = 0; i < charNo - 1; ++i {
            print(" ", terminator: "", toStream: &STDERR)
        }
        print("^", toStream: &STDERR)
    }
}

public enum ErrorMessage : CustomStringConvertible {
    case Dummy
    case FileNotFound(String)
    case FileCanNotRead(String)
    case MultipleMain(String, String)
    // ScopeManager
    case InvalidScopeToImport
    case NoSuchModule(String)
    case UnresolvedScopeRemains
    case LeavingModuleScope
    case InvalidScope(Inst.Type)
    case AlreadyExist(RefKind, String)
    case InvalidRefScope(RefKind)
    case NotExist(RefKind, RefIdentifier)
    case ImplicitParameterIsNotImplemented
    // Inst
    case NoNestedType(parent: String, child: String)
    // TokenStream
    case UnexpectedEOF
    case InvalidToken
    case ReservedToken
    // GrammarParser
    case DuplicateAccessLevelModifier
    // AttributesParser
    case ExpectedAttributeIdentifier
    case ExpectedUnownedSafeModifierRightParenthesis
    case ExpectedUnownedUnsafeModifierRightParenthesis
    case ExpectedModifiedUnowned
    case ExpectedSetModifier
    case ExpectedRightParenthesisAfterSet
    // DeclarationParser
    case ModifierBeforeImport
    case ModifierBeforeTypealias
    case ExpectedEnum
    case ModifierBeforeEnum
    case ModifierBeforeStruct
    case ModifierBeforeClass
    case ModifierBeforeProtocol
    case ModifierBeforeDeinit
    case AttributeBeforeExtension
    case ModifierBeforeExtension
    case AttributeBeforeOperator
    case ModifierBeforeOperator
    case ExpectedDeclaration
    case ExpectedModuleDeclaration
    case ExpectedTypeIdentifier
    case ExpectedPath
    case MultipleVariableWithBlock
    case ExpectedVariableIdentifier
    case ExpectedVariableSpecifierWithBlock
    case ExpectedIdentifierPatternWithVariableBlock
    case ExpectedSetterAfterGetter
    case ExpectedGetterAfterSetter
    case ExpectedRightBraceAfterVariableBlock
    case ExpectedSetterVariableName
    case ExpectedRightParenthesisAfterSetterVariable
    case ExpectedDidSetter
    case ExpectedRightBraceAfterDidSetterWillSetter
    case ExpectedWillSetter
    case ExpectedDidSetterWillSetter
    case ExpectedTypealiasName
    case ExpectedTypealiasAssignment
    case DuplicateOperatorModifier
    case ProcedureInModulableFunctionDeclaration
    case ExpectedFunctionName
    case ExpectedLeftParenthesisForParameter
    case ExpectedRightParenthesisAfterParameter
    case ExpectedParameter
    case ExpectedInternalParameterName
    case UnexpectedParameterType
    case ExpectedParameterNameTypeAnnotation
    case InOutParameterWithDefaultArgument
    case ExplicitDefaultArgumentInModuleDeclaration
    case VariadicParameterWithAnotherKind
    case ExpectedEnumName
    case ExpectedLeftBraceForEnumCase
    case RawValueStyleEnumWithUnionStyle
    case UnionStyleEnumWithRawValueStyle
    case IndirectWithRawValueStyle
    case ExpectedEnumCaseClause
    case ExpectedEnumCaseName
    case AssociatedValueWithRawValueStyle
    case RawValueAssignmentWithUnionStyle
    case RawValueAssignmentInModuleDeclaration
    case ExpectedLiteralForRawValue
    case ExpectedConstantName
    case ExpectedVariableName
    case ExpectedStructName
    case ExpectedLeftBraceForDeclarationBody
    case ExpectedRightBraceAfterDeclarationBody
    case ExpectedClassName
    case ExpectedProtocolName
    case ExpectedTypeAnnotationForConstantOrVariable
    case ExpectedFunctionResultArrow
    case ExpectedGetterSetterKeyword
    case ExpectedSetKeyword
    case ExpectedGetKeyword
    case ExpectedGetSetKeyword
    case ExpectedAssociatedTypeName
    case ExpectedExtendedType
    case ExpectedLeftBraceForExtension
    case ExpectedRightBraceAfterExtension
    case ExpectedLeftBraceForSubscript
    case ExpectedOperator
    case ExpectedOperatorName
    case ReservedOperator
    case ExpectedLeftBraceForOperator
    case ExpectedRightBraceForOperator
    case ExpectedPrecedence
    case ExpectedAssociativity
    // ExpressionParser
    case ExpectedColonAfterCondition
    case ExpectedRightBracketAfterSubscript
    case DotOperatorAfterOptionalChaining
    case UnexpectedTokenForMember
    case ExpectedImplicitMember
    case ExpectedExpression
    case UnexpectedEOFWhileArray
    case ExpectedRightBracketAfterDictionary
    case ExpectedColonForDictionary
    case ExpectedRightBracketAfterArray
    case ExpectedMember
    case ExpectedSuperMember
    case NotClosedLeftParenthesis
    case ExpectedInForClosureSignature
    case ExpectedParameterName
    case ExpectedUnownedSafeUnsafeModifierRightParenthesis
    case ExpectedRightBraceAfterClosure
    case ExpectedTupleLabel
    case ExpectedRightParenthesisAfterTuple
    // GenericsParser
    case ExpectedGraterThanAfterGenericParameter
    case ExpectedGenericParameterName
    case ExpectedIdentifierForRequirement
    case ExpectedDoubleEqual
    case ExpectedRequirementSymbol
    // PatternParser
    case ExpectedDeclarativePattern
    case ExpectedEnumCasePatternIdentifier
    case NestedBindingPattern
    // ProcedureParser
    case ContinuousProcedure
    case ExpectedSemicolonAfterForInit
    case ExpectedSemicolonAfterForCondition
    case UnexpectedRightParenthesis
    case ExpectedRightParenthesisAfterForSetting
    case ExpectedForVariableInit
    case ExpectedInForForPattern
    case ExpectedWhileForRepeatWhile
    case ExpectedElseForGuard
    case ExpectedCondition
    case ExpectedEqualForPatternMatch
    case ExpectedMatchingPattern
    case ExpectedEqualForOptionalBinding
    case ExpectedLeftBraceForFlowSwitch
    case ExpectedRightBraceAfterFlowSwitch
    case ExpectedColonAfterCasePattern
    case EmptyCaseFlow
    case ExpectedColonAfterDefault
    case LabelWithUnexpectedFlow
    case ExpectedEqualForAssignment
    case ExpectedLeftBraceForProceduresBlock
    case ExpectedRightBraceAfterProceduresBlock
    // TypeParser
    case ExpectedType
    case ExpectedRightBracketAfterDictionaryType
    case ExpectedSymbolForAggregator
    case ExpectedRightParenthesisAfterTupleType
    case ExpectedLessThanForProtocolCompositionType
    case ExpectedTypeIdentifierForProtocolCompositionType
    case ExpectedGraterThanAfterProtocolCompositionType
    case ExpectedMetatypeType
    // TypeInference
    case UnwrappingNotAOptionalType
    case TypeNotMatch

    public var description: String {
        switch self {
        case .Dummy:
            return "dummy error"
        case let .FileNotFound(name):
            return "No such a file: \(name)"
        case let .FileCanNotRead(name):
            return "File cannot read: \(name)"
        case let .MultipleMain(first, second):
            return "Top level procedure was found in both of \(first) and \(second). Only one file can act as main program."
        // TokenStream
        case .UnexpectedEOF:
            return "Unexpected end of file"
        case .InvalidToken:
            return "Invalid token"
        case .ReservedToken:
            return "Reserved token"
        // GrammarParser
        case DuplicateAccessLevelModifier:
            return "Duplicate access level modifier"
        // ScopeManager
        case .InvalidScopeToImport:
            return "'import' is only valid at file scope or module."
        case let .NoSuchModule(name):
            return "No such module '\(name)'"
        case .UnresolvedScopeRemains:
            return "<system error> unresolved scope remains"
        case .LeavingModuleScope:
            return "<system error> leaving module scope"
        case let .InvalidScope(type):
            let target: String
            switch type {
            case is TypeInst.Type: target = "a type"
            case is ConstantInst.Type: target = "a constant"
            case is VariableInst.Type: target = "a variable"
            case is FunctionInst.Type: target = "a function"
            case is OperatorInst.Type: target = "an operator"
            case is EnumInst.Type: target = "an enum"
            case is EnumCaseInst.Type: target = "an enum case"
            case is StructInst.Type: target = "a struct"
            case is ClassInst.Type: target = "a class"
            case is ProtocolInst.Type: target = "a protocol"
            default: target = "<error type>"
            }
            return "You cannot declare \(target) in this scope"
        case let .AlreadyExist(kind, name):
            let target: String
            switch kind {
            case .Type: target = "Type"
            case .Value : target = "Value"
            case .Operator: target = "Operator"
            case .EnumCase: target = "Enum case"
            case .ImplicitParameter: target = "Implicit parameter"
            }
            return "\(target) with name '\(name)' already exists"
        case let .InvalidRefScope(kind):
            let target: String
            switch kind {
            case .Type: target = "a type"
            case .Value: target = "a constant or a variable"
            case .Operator: target = "an operator"
            case .EnumCase: target = "an enum case"
            case .ImplicitParameter: target = "an implicit parameter"
            }
            return "You cannot refer \(target) in this scope"
        case let .NotExist(kind, id):
            let target: String
            switch kind {
            case .Type: target = "Type"
            case .Value : target = "Value"
            case .Operator: target = "Operator"
            case .EnumCase: target = "Enum case"
            case .ImplicitParameter: target = "Implicit parameter"
            }
            return "\(target) '\(id)' not exists in this scope"
        case .ImplicitParameterIsNotImplemented:
            return "Implicit parameter is not implemented."
        // Inst
        case let .NoNestedType(parent: p, child: c):
            return "Type '\(p)' has no nested type '\(c)'"
        // AttributesParser
        case .ExpectedAttributeIdentifier:
            return "Expected identifier for attribute"
        case .ExpectedUnownedSafeModifierRightParenthesis:
            return "Expected ')' after 'safe' for unowned modifier"
        case .ExpectedUnownedUnsafeModifierRightParenthesis:
            return "Expected ')' after 'unsafe' for unowned modifier"
        case .ExpectedModifiedUnowned:
            return "Expected 'safe' or 'unsafe' after '('"
        case .ExpectedSetModifier:
            return "Expected 'set' after '('"
        case .ExpectedRightParenthesisAfterSet:
            return "Expected ')' after 'set' for access modifier"
        // DeclarationParser
        case .ModifierBeforeImport:
            return "Unexpected modifier before 'import'."
        case .ModifierBeforeTypealias:
            return "Unexpected declaration modifier before 'typealias'."
        case .ExpectedEnum:
            return "Expected enum declaration after 'indirect'."
        case .ModifierBeforeEnum:
            return "Unexpected declaration modifier before 'enum'."
        case .ModifierBeforeStruct:
            return "Unexpected declaration modifier before 'struct'."
        case .ModifierBeforeClass:
            return "Unexpected declaration modifier before 'class'."
        case .ModifierBeforeProtocol:
            return "Unexpected declaration modifier before 'protocol'."
        case .ModifierBeforeDeinit:
            return "Unexpected modifier before 'deinit'."
        case .AttributeBeforeExtension:
            return "Unexpected attribute before 'extension'."
        case .ModifierBeforeExtension:
            return "Unexpected declaration modifier before 'extension'."
        case .AttributeBeforeOperator:
            return "Unexpected attribute before operator declaration."
        case .ModifierBeforeOperator:
            return "Unexpected modifier before operator declaration 'prefix'."
        case .ExpectedDeclaration:
            return "Expected declaration."
        case .ExpectedModuleDeclaration:
            return "Expected module declaration."
        case .ExpectedTypeIdentifier:
            return "Expected identifier for type name."
        case .ExpectedPath:
            return "Expected path to import."
        case .MultipleVariableWithBlock:
            return "When the variable has blocks, you can define only one variable in a declaration."
        case .ExpectedVariableIdentifier:
            return "Expected identifier or declarative pattern for variable declaration."
        case .ExpectedVariableSpecifierWithBlock:
            return "Expected type annotation or initializer for variable declaration with block."
        case .ExpectedIdentifierPatternWithVariableBlock:
            return "Only identifier pattern can appear in the variable declaration with blocks."
        case .ExpectedSetterAfterGetter:
            return "Expected setter clause after getter clause"
        case .ExpectedGetterAfterSetter:
            return "Expected getter clause after setter clause."
        case .ExpectedRightBraceAfterVariableBlock:
            return "Expected '}' at the end of variable block clause"
        case .ExpectedSetterVariableName:
            return "Expected variable name for setter parameter"
        case .ExpectedRightParenthesisAfterSetterVariable:
            return "Expected ')' after setter parameter name"
        case .ExpectedDidSetter:
            return "Expected did-setter clause after getter clause"
        case .ExpectedRightBraceAfterDidSetterWillSetter:
            return "Expected '}' at the end of will-setter, did-setter clause"
        case .ExpectedWillSetter:
            return "Expected will-setter clause after getter clause"
        case .ExpectedDidSetterWillSetter:
            return "Expected will-setter or did-setter."
        case .ExpectedTypealiasName:
            return "Expected identifier for typealias name."
        case .ExpectedTypealiasAssignment:
            return "Expected '=' for typealias declaration"
        case .DuplicateOperatorModifier:
            return "Duplicate operator modifier"
        case .ProcedureInModulableFunctionDeclaration:
            return "Function declaration in modulable scope cannot have a body procedures."
        case .ExpectedFunctionName:
            return "Expected function or operator name."
        case .ExpectedLeftParenthesisForParameter:
            return "Expected '(' for parameter clause."
        case .ExpectedRightParenthesisAfterParameter:
            return "Expected ')' at the end of parameter."
        case .ExpectedParameter:
            return "Expected parameter."
        case .ExpectedInternalParameterName:
            return "Expected internal parameter name."
        case .UnexpectedParameterType:
            return "<system error> Unexpected parameter type."
        case .ExpectedParameterNameTypeAnnotation:
            return "Expected type annotation after parameter name."
        case .InOutParameterWithDefaultArgument:
            return "'inout' parameter cannot have a default argument."
        case .ExplicitDefaultArgumentInModuleDeclaration:
            return "Do not explicitly write the value of default argument. Just write 'default'."
        case .VariadicParameterWithAnotherKind:
            return "Variadic parameter cannot declare as 'let', 'var' or 'inout'."
        case .ExpectedEnumName:
            return "Expected enum name."
        case .ExpectedLeftBraceForEnumCase:
            return "Expected '{' for enum case declarations."
        case .RawValueStyleEnumWithUnionStyle:
            return "Cannot use raw value style enum case with union style enum context."
        case .UnionStyleEnumWithRawValueStyle:
            return "Cannot use union style enum case with raw value style enum context."
        case .IndirectWithRawValueStyle:
            return "'indirect' keyword is only valid in union style enum context."
        case .ExpectedEnumCaseClause:
            return "Expected 'case' for enum case clause"
        case .ExpectedEnumCaseName:
            return "Expected identifier for enum case name"
        case .AssociatedValueWithRawValueStyle:
            return "enum case with associated type is only valid in union style enum context."
        case .RawValueAssignmentWithUnionStyle:
            return "enum case with raw value assignment is only valid in raw value style enum context."
        case .RawValueAssignmentInModuleDeclaration:
            return "Do not explicitly write a raw value assignmentation of raw value style enum declaration in module."
        case .ExpectedLiteralForRawValue:
            return "Expected literal for raw value"
        case .ExpectedConstantName:
            return "Expected constant name"
        case .ExpectedVariableName:
            return "Expected variable name"
        case .ExpectedStructName:
            return "Expected struct name"
        case .ExpectedLeftBraceForDeclarationBody:
            return "Expected '{' for declaration body."
        case .ExpectedRightBraceAfterDeclarationBody:
            return "Expected '}' after declaration body."
        case .ExpectedClassName:
            return "Expected class name"
        case .ExpectedProtocolName:
            return "Expected protocol name"
        case .ExpectedTypeAnnotationForConstantOrVariable:
            return "Expected type annotation for constant or variable declaration"
        case .ExpectedFunctionResultArrow:
            return "Expected '->' for subscript result type."
        case .ExpectedGetterSetterKeyword:
            return "Expected getter or setter keyword clause."
        case .ExpectedSetKeyword:
            return "Expected 'set' keyword"
        case .ExpectedGetKeyword:
            return "Expected 'get' keyword"
        case .ExpectedGetSetKeyword:
            return "Expected 'get' or 'set' keyword."
        case .ExpectedAssociatedTypeName:
            return "Expected associated type name."
        case .ExpectedExtendedType:
            return "Expected extended type name."
        case .ExpectedLeftBraceForExtension:
            return "Expected '{' for extension body."
        case .ExpectedRightBraceAfterExtension:
            return "Expected '}' for extension body."
        case .ExpectedLeftBraceForSubscript:
            return "Expected '{' for subscript body."
        case .ExpectedOperator:
            return "Expected 'operator' for operator declaration."
        case .ExpectedOperatorName:
            return "Expected operator name."
        case .ReservedOperator:
            return "The prefix operators '&', '<' and '?', the infix operator '?', and the postfix operators '!', '>', and '?' are reserved."
        case .ExpectedLeftBraceForOperator:
            return "Expected '{' for operator declaration."
        case .ExpectedRightBraceForOperator:
            return "Expected '}' for operator declaration."
        case .ExpectedPrecedence:
            return "Expected decimal digits for precedence."
        case .ExpectedAssociativity:
            return "Expected 'left', 'right' or 'none' for associativity."
        // ExpressionParser
        case .ExpectedColonAfterCondition:
            return "Expected ':' after true condition of conditional expression"
        case .ExpectedRightBracketAfterSubscript:
            return "Expected ']' at the end of subscript expression"
        case .DotOperatorAfterOptionalChaining:
            return "Expected '.' after optional chaining"
        case .UnexpectedTokenForMember:
            return "Unexpected token after '.'"
        case .ExpectedImplicitMember:
            return "Expected identifier after the begging of implicit member expression"
        case .ExpectedExpression:
            return "Expected expression"
        case .UnexpectedEOFWhileArray:
            return "Parser reached end of file while parsing an array"
        case .ExpectedRightBracketAfterDictionary:
            return "Expected ']' at the end of dictionary literal"
        case .ExpectedColonForDictionary:
            return "Expected ':' between the key and the value of dictionary literal"
        case .ExpectedRightBracketAfterArray:
            return "Expected ']' at the end of array literal"
        case .ExpectedMember:
            return "Expected member name or 'init' after dot"
        case .ExpectedSuperMember:
            return "Expected member expression or subscript expression after 'super'"
        case .NotClosedLeftParenthesis:
            return "'(' not closed before end of file."
        case .ExpectedInForClosureSignature:
            return "Expected 'in' after closure signature."
        case .ExpectedParameterName:
            return "Expected identifier after ',' of parameter list."
        case .ExpectedUnownedSafeUnsafeModifierRightParenthesis:
            return "Expected ')' after 'safe' or 'unsafe' for unowned modifier"
        case .ExpectedRightBraceAfterClosure:
            return "Expected '}' at the end of closure"
        case .ExpectedTupleLabel:
            return "Expected identifier for the label of tuple element"
        case .ExpectedRightParenthesisAfterTuple:
            return "Expected ')' at the end of tuple"
        // GenericsParser
        case .ExpectedGraterThanAfterGenericParameter:
            return "Expected '>' at the end of generic parameter clause."
        case .ExpectedGenericParameterName:
            return "Expected generic parameter name."
        case .ExpectedIdentifierForRequirement:
            return "Expected identifier at the beggining of requirement"
        case .ExpectedDoubleEqual:
            return "Expected '==' for the same type requirement"
        case .ExpectedRequirementSymbol:
            return "Expected ':' for the conformance requirement or '==' for the same type requirement"
        // PatternParser
        case .ExpectedDeclarativePattern:
            return "Expected declarative pattern. You can use only identifier patterns, wildcard patterns or tuple patterns here."
        case .ExpectedEnumCasePatternIdentifier:
            return "Expected identifier after '.' for enum case pattern"
        case .NestedBindingPattern:
            return "You cannot use 'let' or 'var' inside of another 'let' or 'var'"
        // ProcedureParser
        case .ContinuousProcedure:
            return "Continuous procedure must be separated by ';'"
        case .ExpectedSemicolonAfterForInit:
            return "Expected ';' after initialize statement of ForFlow"
        case .ExpectedSemicolonAfterForCondition:
            return "Expected ';' after condition of ForFlow"
        case .UnexpectedRightParenthesis:
            return "Unexpected ')'."
        case .ExpectedRightParenthesisAfterForSetting:
            return "Expected ')' after setting of parenthesized ForFlow"
        case .ExpectedForVariableInit:
            return "Expected 'var' for the declaration in initialize condition."
        case .ExpectedInForForPattern:
            return "Expected 'in' after pattern of ForInFlow"
        case .ExpectedWhileForRepeatWhile:
            return "Expected 'while' before repeat while condition"
        case .ExpectedElseForGuard:
            return "Expected 'else' after condition of GuardFlow"
        case .ExpectedCondition:
            return "Expected condition of the flow"
        case .ExpectedEqualForPatternMatch:
            return "Expected '=' for the case pattern of pattern matching clause"
        case .ExpectedMatchingPattern:
            return "Expected matching pattern."
        case .ExpectedEqualForOptionalBinding:
            return "Expected '=' after the pattern of optional binding pattern"
        case .ExpectedLeftBraceForFlowSwitch:
            return "Expected '{' after switch condition."
        case .ExpectedRightBraceAfterFlowSwitch:
            return "Expected '}' at the end of flow switch."
        case .ExpectedColonAfterCasePattern:
            return "Expected ':' after patterns of case flow."
        case .EmptyCaseFlow:
            return "Case flow should have at least one procedure."
        case .ExpectedColonAfterDefault:
            return "Expected ':' after 'default' in flow switch."
        case .LabelWithUnexpectedFlow:
            return "Only loop flows, if flow, and flow switch can have a label"
        case .ExpectedEqualForAssignment:
            return "Expected '=' after pattern in the assignment operation."
        case .ExpectedLeftBraceForProceduresBlock:
            return "Expected '{' before procedures block"
        case .ExpectedRightBraceAfterProceduresBlock:
            return "Expected '}' after procedures block"
        // TypeParser
        case .ExpectedType:
            return "Expected type"
        case .ExpectedRightBracketAfterDictionaryType:
            return "Expected ']' for dictionary type"
        case .ExpectedSymbolForAggregator:
            return "Expected ']' for array type or ':' for dictionary type"
        case .ExpectedRightParenthesisAfterTupleType:
            return "Expected ')' at the end of tuple type"
        case .ExpectedLessThanForProtocolCompositionType:
            return "Expected following '<' for protocol composition type"
        case .ExpectedTypeIdentifierForProtocolCompositionType:
            return "Expected type identifier for element of protocol composition type"
        case .ExpectedGraterThanAfterProtocolCompositionType:
            return "Expected '>' at the end of protocol composition type"
        case .ExpectedMetatypeType:
            return "Expected 'Type' or 'Protocol' for metatype type"
        // TypeInference
        case .UnwrappingNotAOptionalType:
            return "Unwrapping not a optional type."
        case .TypeNotMatch:
            return "Type not match"
        }
    }
}
