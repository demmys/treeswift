; ModuleID = 'TreeSwift'

%_MS9TreeSwift4Bool = type <{ i1 }>
%_MS9TreeSwift3Int = type <{ i64 }>

; name = Modle: TreeSwift, Struct: Bool, Initializer
; arg0 = Label: _builtinBooleanLiteral, Module: Builtin, Typealias: Int1
; ret  = Module: TreeSwift, Struct: Bool
define %_MS9TreeSwift4Bool @_MSI9TreeSwift4Bool_LMT22_builtinBooleanLiteral7Builtin4Int1_MS9TreeSwift4Bool(i1) {
entry:
    %1 = alloca %_MS9TreeSwift4Bool
    %2 = getelementptr inbounds %_MS9TreeSwift4Bool* %1, i32 0, i32 0
    store i1 %0, i1* %2
    %3 = load %_MS9TreeSwift4Bool* %1
    ret %_MS9TreeSwift4Bool %3
}

; name = Modle: TreeSwift, Struct: Bool, VariableGet: _builtinBooleanLiteral
; ret  = Module: Builtin, Struct: Int1
define i1 @_MSG9TreeSwift4Bool22_builtinBooleanLiteral_MT7Builtin4Int1(%_MS9TreeSwift4Bool) {
entry:
    %1 = extractvalue %_MS9TreeSwift4Bool %0, 0
    ret i1 %1
}

; name = Modle: TreeSwift, Struct: Int, Initializer
; arg0 = Label: _builtinIntegerLiteral, Module: Builtin, Typealias: Int64
; ret  = Module: TreeSwift, Struct: Int
define %_MS9TreeSwift3Int @_MSI9TreeSwift3Int_LMT22_builtinIntegerLiteral7Builtin5Int64_MS9TreeSwift3Int(i64) {
entry:
    %1 = alloca %_MS9TreeSwift3Int
    %2 = getelementptr inbounds %_MS9TreeSwift3Int* %1, i32 0, i32 0
    store i64 %0, i64* %2
    %3 = load %_MS9TreeSwift3Int* %1
    ret %_MS9TreeSwift3Int %3
}

; name = Modle: TreeSwift, Operator: +
; arg0 = Module: TreeSwift, Struct: Int
; arg1 = Module: TreeSwift, Struct: Int
; ret  = Module: TreeSwift, Struct: Int
define %_MS9TreeSwift3Int @_MO9TreeSwift1a_MS_MS9TreeSwift3Int_9TreeSwift3Int_MS9TreeSwift3Int(%_MS9TreeSwift3Int, %_MS9TreeSwift3Int) {
entry:
    %2 = extractvalue %_MS9TreeSwift3Int %0, 0
    %3 = extractvalue %_MS9TreeSwift3Int %1, 0
    %4 = add i64 %2, %3
    %5 = call %_MS9TreeSwift3Int @_MSI9TreeSwift3Int_LMT22_builtinIntegerLiteral7Builtin5Int64_MS9TreeSwift3Int(i64 %4)
    ret %_MS9TreeSwift3Int %5
}

; name = Modle: TreeSwift, Operator: -
; arg0 = Module: TreeSwift, Struct: Int
; arg1 = Module: TreeSwift, Struct: Int
; ret  = Module: TreeSwift, Struct: Int
define %_MS9TreeSwift3Int @_MO9TreeSwift1s_MS_MS9TreeSwift3Int_9TreeSwift3Int_MS9TreeSwift3Int(%_MS9TreeSwift3Int, %_MS9TreeSwift3Int) {
entry:
    %2 = extractvalue %_MS9TreeSwift3Int %0, 0
    %3 = extractvalue %_MS9TreeSwift3Int %1, 0
    %4 = sub i64 %2, %3
    %5 = call %_MS9TreeSwift3Int @_MSI9TreeSwift3Int_LMT22_builtinIntegerLiteral7Builtin5Int64_MS9TreeSwift3Int(i64 %4)
    ret %_MS9TreeSwift3Int %5
}

; name = Modle: TreeSwift, Operator: <
; arg0 = Module: TreeSwift, Struct: Int
; arg1 = Module: TreeSwift, Struct: Int
; ret  = Module: TreeSwift, Struct: Bool
define %_MS9TreeSwift4Bool @_MO9TreeSwift1l_MS_MS9TreeSwift3Int_9TreeSwift3Int_MS9TreeSwift4Bool(%_MS9TreeSwift3Int, %_MS9TreeSwift3Int) {
entry:
    %2 = extractvalue %_MS9TreeSwift3Int %0, 0
    %3 = extractvalue %_MS9TreeSwift3Int %1, 0
    %4 = icmp slt i64 %2, %3
    %5 = call %_MS9TreeSwift4Bool @_MSI9TreeSwift4Bool_LMT22_builtinBooleanLiteral7Builtin4Int1_MS9TreeSwift4Bool(i1 %4)
    ret %_MS9TreeSwift4Bool %5
}

declare i32 @printf(i8* noalias nocapture, ...)
@.printfi64 = private constant [4 x i8] c"%d\0A\00"

; name = Modle: TreeSwift, Function: print
; arg0 = Module: TreeSwift, Struct: Int
; ret  = Tuple()
define void @_MF9TreeSwift5print_MS9TreeSwift3Int_tltr(%_MS9TreeSwift3Int) {
entry:
    %1 = extractvalue %_MS9TreeSwift3Int %0, 0
    %2 = getelementptr inbounds [4 x i8]* @.printfi64, i32 0, i32 0
    call i32 (i8*, ...)* @printf(i8* %2, i64 %1)
    ret void
}
