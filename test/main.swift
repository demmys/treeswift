import PureSwiftUnit

let tester = Tester()
tester.register(ParserTest())
tester.register(CharacterStreamTest())
tester.register(WordLiteralComposerTest())
tester.register(IdentifierComposerTest())
tester.register(NumericLiteralComposerTest())
tester.register(OperatorComposerTest())
tester.register(StringLiteralComposerTest())
tester.run(DefaultTestReporter())
