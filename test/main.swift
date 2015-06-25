import PureSwiftUnit

let tester = Tester()
tester.register(ParserTest())
tester.register(CharacterStreamTest())
tester.register(WordLiteralComposerTest())
tester.register(IdentifierComposerTest())
tester.register(IntegerLiteralComposerTest())
tester.register(OperatorComposerTest())
tester.run(DefaultTestReporter())
