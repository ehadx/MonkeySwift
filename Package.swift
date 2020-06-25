// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "MonkeySwift",
  targets: [
    .target(name: "MonkeySwift", dependencies: ["REPL"]),
    .target(name: "Core"),
    .target(name: "REPL", dependencies: ["Core"]),
    .testTarget( name: "CoreTests", dependencies: ["Core"]),
  ]
)
