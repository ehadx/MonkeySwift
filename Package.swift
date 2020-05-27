// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "MonkeySwift",
  targets: [
    .target(
      name: "MonkeySwift",
      dependencies: ["REPL"]),
    .target(
      name: "Lexer"),
    .target(
      name: "REPL",
      dependencies: ["Lexer"]),
    .target(
      name: "Parser",
      dependencies: ["Lexer"]),
    .testTarget(
      name: "LexerTests",
      dependencies: ["Lexer"]),
    .testTarget(
      name: "ParserTests",
      dependencies: ["Lexer", "Parser"])
  ]
)
