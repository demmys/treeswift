#import <Foundation/Foundation.h>
#import "llvm.h"
#import "llvm-cpp.h"

@implementation RawFDOStream {
    llvm::raw_fd_ostream *raw;
};

-(id)initWithFileName: (const char *)fileName
                     : (const char **)errorInfo
                     : (OpenFlags)flags {
    std::string err;
    llvm::raw_fd_ostream *r = new llvm::raw_fd_ostream(
        fileName,
        err,
        (llvm::sys::fs::OpenFlags)flags
    );
    if(err.empty()) {
        *errorInfo = err.c_str();
    }
    self = [super init];
    raw = r;
    return self;
}

-(void)dealloc {
    delete(raw);
    [super dealloc];
}

-(void)close {
    raw->close();
}

-(llvm::raw_fd_ostream *)raw {
    return raw;
}

@end


@implementation IRBuilder {
    llvm::IRBuilder<> *raw;
};

-(id)init {
    self = [super init];
    raw = new llvm::IRBuilder<>(llvm::getGlobalContext());
    return self;
}

-(void)dealloc {
    delete(raw);
    [super dealloc];
}

@end


@implementation APInt {
    llvm::APInt *raw;
};

-(id)initWithNumBits: (unsigned int)numBits
                    : (const char *)str
                    : (unsigned char)radix {
    self = [super init];
    raw = new llvm::APInt(numBits, llvm::StringRef(str), radix);
    return self;
}

-(void)dealloc {
    delete(raw);
    [super dealloc];
}

-(llvm::APInt *)raw {
    return raw;
}

@end


@implementation LLVMContext {
    llvm::LLVMContext *raw;
};

-(id)initWithRawObject: (llvm::LLVMContext *)c {
    self = [super init];
    raw = c;
    return self;
}

-(llvm::LLVMContext *)raw {
    return raw;
}

@end


@implementation Module {
    llvm::Module *raw;
};

-(id)initWithModuleID: (const char *)moduleID {
    self = [super init];
    raw = new llvm::Module(llvm::StringRef(moduleID), llvm::getGlobalContext());
    return self;
}

-(void)dealloc {
    delete(raw);
    [super dealloc];
}

-(llvm::Module *)raw {
    return raw;
}

-(LLVMContext *) getContext {
    return [[LLVMContext alloc] initWithRawObject: &(raw->getContext())];
}

@end


@implementation Type {
    llvm::Type *raw;
};

-(id)initWithRawObject: (llvm::Type *)r {
    self = [super init];
    raw = r;
    return self;
}

-(llvm::Type *)raw {
    return raw;
}

@end


@implementation IntegerType {
    llvm::IntegerType *raw;
};

-(id)initWithRawObject: (llvm::IntegerType *)i {
    self = [super initWithRawObject: i];
    raw = i;
    return self;
}

+(IntegerType *)get: (LLVMContext *)c : (unsigned int)numBits {
    llvm::IntegerType *raw = llvm::IntegerType::get(*c.raw, numBits);
    return [[IntegerType alloc] initWithRawObject: raw];
}

@end


@implementation PointerType {
    llvm::PointerType *raw;
};

-(id)initWithRawObject: (llvm::PointerType *)p {
    self = [super initWithRawObject: p];
    raw = p;
    return self;
}

+(PointerType *)get: (Type *)elementType : (AddressSpace)addressSpace {
    llvm::PointerType *raw = llvm::PointerType::get(elementType.raw, addressSpace);
    return [[PointerType alloc] initWithRawObject: raw];
}

@end


@implementation ArrayType {
    llvm::ArrayType *raw;
};

-(id)initWithRawObject: (llvm::ArrayType *)a {
    self = [super initWithRawObject: a];
    raw = a;
    return self;
}

+(ArrayType *)get: (Type *)elementType : (unsigned long)numElements {
    llvm::ArrayType *raw = llvm::ArrayType::get(elementType.raw, numElements);
    return [[ArrayType alloc] initWithRawObject: raw];
}

@end


@implementation FunctionType {
    llvm::FunctionType *raw;
};

-(id)initWithRawObject: (llvm::FunctionType *)f {
    self = [super initWithRawObject: f];
    raw = f;
    return self;
}

+(FunctionType *)get: (Type *)result : (NSArray *)params : (bool)isVarArg {
    std::vector<llvm::Type *> p;
    for(Type *t in params) {
        p.push_back(t.raw);
    }
    llvm::FunctionType *raw = llvm::FunctionType::get(
        result.raw,
        llvm::ArrayRef<llvm::Type *>(p),
        isVarArg
    );
    return [[FunctionType alloc] initWithRawObject: raw];
}

-(llvm::FunctionType *)raw {
    return raw;
}

@end


@implementation Value {
    llvm::Value *raw;
};

-(id)initWithRawObject: (llvm::Value *)v {
    self = [super init];
    raw = v;
    return self;
}

-(void)dump {
    raw->dump();
}

-(llvm::Value *)raw {
    return raw;
}

@end


@implementation Constant {
    llvm::Constant *raw;
};

-(id)initWithRawObject: (llvm::Constant *)c {
    self = [super initWithRawObject: c];
    raw = c;
    return self;
}

-(llvm::Constant *)raw {
    return raw;
}

@end


@implementation ConstantInt {
    llvm::ConstantInt *raw;
};

-(id)initWithRawObject: (llvm::ConstantInt *)c {
    self = [super initWithRawObject: c];
    raw = c;
    return self;
}

+(ConstantInt *)get: (LLVMContext *)context : (const APInt *)v {
    llvm::ConstantInt *raw = llvm::ConstantInt::get(*context.raw, *v.raw);
    return [[ConstantInt alloc] initWithRawObject: raw];
}

@end


@implementation ConstantDataArray {
    llvm::ConstantDataArray *raw;
};

+(Constant *)getString: (LLVMContext *)context
                      : (const char *)initializer
                      : (bool) addNull {
    llvm::Constant *raw = llvm::ConstantDataArray::getString(
        *context.raw, 
        llvm::StringRef(initializer),
        addNull
    );
    return [[Constant alloc] initWithRawObject: raw];
}

@end


@implementation ConstantExpr {
    llvm::ConstantExpr *raw;
};

+(Constant *)getGetElementPtr: (Constant *)c : (NSArray *)idxList : (bool)inBounds {
    std::vector<llvm::Constant *> i;
    for(Constant *c in idxList) {
        i.push_back(c.raw);
    }
    llvm::Constant *raw = llvm::ConstantExpr::getGetElementPtr(
        c.raw,
        llvm::ArrayRef<llvm::Constant *>(i),
        inBounds
    );
    return [[Constant alloc] initWithRawObject: raw];
}

@end


@implementation GlobalVariable {
    llvm::GlobalVariable *raw;
};

-(id)initWithRawObject: (llvm::GlobalVariable *)g {
    self = [super initWithRawObject: g];
    raw = g;
    return self;
}

-(id)initWithModule: (Module *)m
                   : (Type *)ty
                   : (bool)isConstant
                   : (LinkageTypes)linkage
                   : (Constant *)initializer
                   : (const char *)name
                   : (GlobalVariable *)insertBefore
                   : (ThreadLocalMode)tlMode
                   : (AddressSpace)addressSpace
                   : (bool)isExternallyInitialized {
    llvm::GlobalVariable *g = new llvm::GlobalVariable(
        *m.raw,
        ty.raw,
        isConstant,
        (llvm::GlobalValue::LinkageTypes)linkage,
        initializer.raw,
        llvm::StringRef(name),
        insertBefore.raw,
        (llvm::GlobalValue::ThreadLocalMode)tlMode,
        addressSpace,
        isExternallyInitialized
    );
    self = [super initWithRawObject: g];
    raw = g;
    return self;
}

-(llvm::GlobalVariable *)raw {
    return raw;
}

@end


@implementation Function {
    llvm::Function *raw;
};

-(id)initWithRawObject: (llvm::Function *)f {
    self = [super initWithRawObject: f];
    raw = f;
    return self;
}

+(Function *)create: (FunctionType *)ty
                   : (LinkageTypes)linkage
                   : (const char *)n
                   : (Module *)m {
    llvm::Function *raw = llvm::Function::Create(
        ty.raw,
        (llvm::GlobalValue::LinkageTypes)linkage,
        llvm::Twine(n),
        m.raw
    );
    return [[Function alloc] initWithRawObject: raw];
}

-(void) setCallingConv: (CallingConv)cc {
    raw->setCallingConv((llvm::CallingConv::ID)cc);
}

-(llvm::Function *)raw {
    return raw;
}

@end


@implementation BasicBlock {
    llvm::BasicBlock *raw;
};

-(id)initWithRawObject: (llvm::BasicBlock *)b {
    self = [super init];
    raw = b;
    return self;
}

+(BasicBlock *)create: (LLVMContext *)context
                     : (const char *)name
                     : (Function *)parent
                     : (BasicBlock *)insertBefore {
    llvm::BasicBlock *raw = llvm::BasicBlock::Create(
        *context.raw,
        llvm::Twine(name),
        parent.raw,
        insertBefore.raw
    );
    return [[BasicBlock alloc] initWithRawObject: raw];
}

-(llvm::BasicBlock *)raw {
    return raw;
}

@end


@implementation CallInst {
    llvm::CallInst *raw;
};

-(id)initWithRawObject: (llvm::CallInst *)c {
    self = [super init];
    raw = c;
    return self;
}

+(CallInst *) create: (Value *)func
                    : (NSArray *)args
                    : (const char *)nameStr
                    : (BasicBlock *)insertAtEnd {
    std::vector<llvm::Value *> a;
    for(Value *v in args) {
        a.push_back(v.raw);
    }
    llvm::CallInst *raw = llvm::CallInst::Create(
        func.raw,
        llvm::ArrayRef<llvm::Value *>(a),
        llvm::Twine(nameStr),
        insertAtEnd.raw
    );
    return [[CallInst alloc] initWithRawObject: raw];
}

@end


@implementation ReturnInst {
    llvm::ReturnInst *raw;
};

-(id)initWithRawObject: (llvm::ReturnInst *)r {
    self = [super init];
    raw = r;
    return self;
}

+(ReturnInst *)create: (LLVMContext *)c
                     : (Value *)retVal
                     : (BasicBlock *)insertAtEnd {
    llvm::ReturnInst *raw = llvm::ReturnInst::Create(
        *c.raw,
        retVal.raw,
        insertAtEnd.raw
    );
    return [[ReturnInst alloc] initWithRawObject: raw];
}

@end


@implementation Pass {
    llvm::Pass *raw;
};

-(id)initWithRawObject: (llvm::Pass *)p {
    self = [super init];
    raw = p;
    return self;
}

-(llvm::Pass *)raw {
    return raw;
}

@end


@implementation ModulePass {
    llvm::ModulePass *raw;
};

-(id)initWithRawObject: (llvm::ModulePass *)m {
    self = [super initWithRawObject: m];
    raw = m;
    return self;
}

+(ModulePass *)createPrintModulePass: (RawFDOStream *)os : (const char *)Banner {
    llvm::ModulePass *raw = llvm::createPrintModulePass(*os.raw, std::string(Banner));
    return [[ModulePass alloc] initWithRawObject: raw];
}

-(llvm::ModulePass *)raw {
    return raw;
}

@end


@implementation PassManager {
    llvm::legacy::PassManager *raw;
};

-(id)init {
    self = [super init];
    raw = new llvm::legacy::PassManager();
    return self;
}

-(void)dealloc {
    delete(raw);
    [super dealloc];
}

-(void)add: (Pass *)p {
    raw->add(p.raw);
}

-(bool)run: (Module *)m {
    return raw->run(*m.raw);
}

@end
