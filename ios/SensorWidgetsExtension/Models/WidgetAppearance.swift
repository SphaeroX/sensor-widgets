import Foundation

/// Optional per-widget look (contract field `appearance`). Unset values keep the platform default.
/// Mirrors the Dart `WidgetAppearance`.
public struct WidgetAppearance: Codable, Equatable {
    public let backgroundColor: String?
    public let backgroundOpacity: Double?
    public let textColor: String?
    public let accentColor: String?
    public let fontScale: Double?
    public let cornerRadius: Double?

    public init(
        backgroundColor: String? = nil,
        backgroundOpacity: Double? = nil,
        textColor: String? = nil,
        accentColor: String? = nil,
        fontScale: Double? = nil,
        cornerRadius: Double? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.backgroundOpacity = backgroundOpacity
        self.textColor = textColor
        self.accentColor = accentColor
        self.fontScale = fontScale
        self.cornerRadius = cornerRadius
    }
}

/// Resolved, validated appearance. `nil` colors mean "use the system default", so widgets
/// without `appearance` look unchanged.
///
/// Platform limits: iOS draws the widget container shape itself, so `cornerRadius` is resolved
/// (for parity checks) but not applied; `fontScale` scales fixed point sizes and maps to a
/// Dynamic Type step for text styles.
public struct ResolvedAppearance: Equatable {
    public let backgroundARGB: UInt32?
    public let backgroundOpacity: Double
    public let textARGB: UInt32?
    public let accentARGB: UInt32?
    public let fontScale: Double
    public let cornerRadius: Double
    /// True when a font scale was configured (the Dynamic Type override is then applied).
    public let hasCustomFontScale: Bool
}

public enum AppearanceResolver {
    public static let minFontScale = 0.8
    public static let maxFontScale = 1.4
    public static let maxCornerRadius = 32.0
    public static let defaultCornerRadius = 16.0

    public static func resolve(_ appearance: WidgetAppearance?) -> ResolvedAppearance {
        let source = appearance ?? WidgetAppearance()
        return ResolvedAppearance(
            backgroundARGB: source.backgroundColor.flatMap { ChartColor.parseHex($0) },
            backgroundOpacity: min(max(source.backgroundOpacity ?? 1.0, 0), 1),
            textARGB: source.textColor.flatMap { ChartColor.parseHex($0) },
            accentARGB: source.accentColor.flatMap { ChartColor.parseHex($0) },
            fontScale: min(max(source.fontScale ?? 1.0, minFontScale), maxFontScale),
            cornerRadius: min(max(source.cornerRadius ?? defaultCornerRadius, 0), maxCornerRadius),
            hasCustomFontScale: source.fontScale != nil
        )
    }
}
