import XCTest
@testable import CoreTests

XCTMain([
  testCase(        ParserTests.allTests),
  testCase(     EvaluatorTests.allTests),
  testCase(           ASTTests.allTests),
  testCase(         LexerTests.allTests),
  testCase(MacroExpansionTests.allTests),
])
