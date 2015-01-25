#ifndef LLVM_H_INCLUDED
#define LLVM_H_INCLUDED

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OpenFlags) {
    OpenFlags_None = 0,
    OpenFlags_Excl = 1,
    OpenFlags_Append = 2,
    OpenFlags_Text = 4,
    OpenFlags_RW = 8
};

typedef NS_ENUM(NSInteger, LinkageTypes) {
    LinkageTypes_ExternalLinkage = 0,
    LinkageTypes_AvailableExternallyLinkage,
    LinkageTypes_LinkOnceAnyLinkage,
    LinkageTypes_LinkOnceODRLinkage,
    LinkageTypes_WeakAnyLinkage,
    LinkageTypes_WeakODRLinkag,
    LinkageTypes_AppendingLinkage,
    LinkageTypes_InternalLinkage,
    LinkageTypes_PrivateLinkage,
    LinkageTypes_ExternalWeakLinkage,
    LinkageTypes_CommonLinkage
};

typedef NS_ENUM(NSInteger, CallingConv) {
    CallingConv_C = 0,
    CallingConv_Fast = 8,
    CallingConv_Cold = 9,
    CallingConv_GHC = 10,
    CallingConv_HiPE = 11,
    CallingConv_WebKit_JS = 12,
    CallingConv_AnyReg = 13,
    CallingConv_PreserveMost = 14,
    CallingConv_PreserveAll = 15,
    CallingConv_FirstTargetCC = 64,
    CallingConv_X86_StdCall = 64,
    CallingConv_X86_FastCall = 65,
    CallingConv_ARM_APCS = 66,
    CallingConv_ARM_AAPCS = 67,
    CallingConv_ARM_AAPCS_VFP = 68,
    CallingConv_MSP430_INTR = 69,
    CallingConv_X86_ThisCall = 70,
    CallingConv_PTX_Kernel = 71,
    CallingConv_PTX_Device = 72,
    CallingConv_SPIR_FUNC = 75,
    CallingConv_SPIR_KERNEL = 76,
    CallingConv_Intel_OCL_BI = 77,
    CallingConv_X86_64_SysV = 78,
    CallingConv_X86_64_Win64 = 79,
    CallingConv_X86_VectorCall = 80
};

typedef NS_ENUM(NSInteger, AddressSpace) {
    AddressSpace_Generic = 0,
    AddressSpace_Global = 1,
    AddressSpace_Shared = 3,
    AddressSpace_Const = 4,
    AddressSpace_Local = 5,
    AddressSpace_Param = 101
};

typedef NS_ENUM(NSInteger, ThreadLocalMode) {
    ThreadLocalMode_NotThreadLocal = 0,
    ThreadLocalMode_GeneralDynamic,
    ThreadLocalMode_LocalDynamic,
    ThreadLocalMode_InitialExec,
    ThreadLocalMode_LocalExec
};

@interface RawFDOStream : NSObject
-(id)initWithFileName: (const char *)fileName
                     : (const char **)errorInfo
                     : (OpenFlags)flags;
-(void)close;
@end

@interface IRBuilder : NSObject
-(id)init;
@end

@interface APInt : NSObject
-(id)initWithNumBits: (unsigned int)numBits
                    : (const char *)str
                    : (unsigned char)radix;
@end

@interface LLVMContext : NSObject
@end

@interface Module : NSObject
-(id)initWithModuleID: (const char *)moduleID;
-(LLVMContext *) getContext;
@end

@interface Type : NSObject
@end

@interface IntegerType : Type
+(IntegerType *)get: (LLVMContext *)c : (unsigned int)numBits;
@end

@interface PointerType : Type
+(PointerType *)get: (Type *)elementType : (AddressSpace)addressSpace;
@end

@interface ArrayType : Type
+(ArrayType *)get: (Type *)elementType : (unsigned long)numElements;
@end

@interface FunctionType : Type
+(FunctionType *)get: (Type *)result : (NSArray *)params : (bool)isVarArg;
@end

@interface Value : NSObject
-(void)dump;
@end

@interface Constant : Value
@end

@interface ConstantInt : Constant
+(ConstantInt *)get: (LLVMContext *)context : (const APInt *)v;
@end

@interface ConstantDataArray : Constant
+(Constant *)getString: (LLVMContext *)context
                      : (const char *)initializer
                      : (bool) addNull;
@end

@interface ConstantExpr : NSObject
+(Constant *)getGetElementPtr: (Constant *)c : (NSArray *)idxList : (bool)inBounds;
@end

@interface GlobalVariable : Constant
-(id)initWithModule: (Module *)m
                   : (Type *)ty
                   : (bool)isConstant
                   : (LinkageTypes)linkage
                   : (Constant *)initializer
                   : (const char *)name
                   : (GlobalVariable *)insertBefore
                   : (ThreadLocalMode)tlMode
                   : (AddressSpace)addressSpace
                   : (bool)isExternallyInitialized;
@end

@interface Function : Value
+(Function *)create: (FunctionType *)ty
                   : (LinkageTypes)linkage
                   : (const char *)n
                   : (Module *)m;
-(void) setCallingConv: (CallingConv)cc;
@end

@interface BasicBlock : NSObject
+(BasicBlock *)create: (LLVMContext *)context
                     : (const char *)name
                     : (Function *)parent
                     : (BasicBlock *)insertBefore;
@end

@interface CallInst : NSObject
+(CallInst *) create: (Value *)func
                    : (NSArray *)args
                    : (const char *)nameStr
                    : (BasicBlock *)insertAtEnd;
@end

@interface ReturnInst : NSObject
+(ReturnInst *)create: (LLVMContext *)c
                     : (Value *)retVal
                     : (BasicBlock *)insertAtEnd;
@end

@interface Pass : NSObject
@end

@interface ModulePass : Pass
+(ModulePass *)createPrintModulePass: (RawFDOStream *)os : (const char *)Banner;
@end

@interface PassManager : NSObject
-(id)init;
-(void)add: (Pass *)p;
-(bool)run: (Module *)m;
@end

#endif
