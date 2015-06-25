import PureSwiftUnit

let tester = Tester()
tester.register(ParserTest())
tester.register(CharacterStreamTest())
tester.register(WordLiteralComposerTest())
tester.run(DefaultTestReporter())
