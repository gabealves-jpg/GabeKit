// swift-tools-version: 6.2
import PackageDescription

/// Componentes SwiftUI reutilizáveis entre os apps do Gabe (Pagr, Cashola…).
/// Cada componente é um produto próprio: o app importa só o que usa.
let package = Package(
    name: "GabeKit",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "LiquidGlassPicker", targets: ["LiquidGlassPicker"]),
    ],
    targets: [
        .target(name: "LiquidGlassPicker"),
        .testTarget(name: "LiquidGlassPickerTests", dependencies: ["LiquidGlassPicker"]),
    ]
)
