// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "MacOSDimmer",
  platforms: [.macOS(.v13)],
  targets: [
    .executableTarget(
      name: "MacOSDimmer",
      path: "Sources/MacOSDimmer"
    ),
  ]
)
