// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "CSVDecoder",
    products: [
        .library(name: "CSVDecoder", targets: ["CSVDecoder"]),
    ],
    dependencies: [
        .package(url: "git@github.com:JaapWijnen/CSVReader.git", .branch("master")),
    ],
    targets: [
        .target(name: "CSVDecoder", dependencies: ["CSVReader"]),
        .testTarget(name: "CSVDecoderTests", dependencies: ["CSVDecoder"]),
    ]
)
