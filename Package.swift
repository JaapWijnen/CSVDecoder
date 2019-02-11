// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "CSVDecoder",
    products: [
        .library(name: "CSVDecoder", targets: ["CSVDecoder"]),
    ],
    dependencies: [
        .package(url: "../CSVReader", .branch("master")),
    ],
    targets: [
        .target(name: "CSVDecoder", dependencies: ["CSVReader"]),
        .testTarget(name: "CSVDecoderTests", dependencies: ["CSVDecoder"]),
    ]
)