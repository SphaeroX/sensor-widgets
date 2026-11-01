import Foundation
import SwiftUI
import XCTest
#if canImport(SensorWidgetsCore)
@testable import SensorWidgetsCore
#endif

/// Per-widget `appearance` contract and its iOS resolution (Task_32). CI only.
final class AppearanceTests: XCTestCase {

    private func loadFixture(named name: String, subdirectory: String) -> Data {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        let candidatePaths = [
            "fixtures/\(subdirectory)/\(name)",
            "../fixtures/\(subdirectory)/\(name)",
            "../../fixtures/\(subdirectory)/\(name)",
            "\(currentDir)/fixtures/\(subdirectory)/\(name)",
            "\(currentDir)/../fixtures/\(subdirectory)/\(name)"
        ]
        for path in candidatePaths {
            if fileManager.fileExists(atPath: path),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                return data
            }
        }
        XCTFail("Could not locate fixture \(name) in \(subdirectory)")
        return Data()
    }

    private func fixtureWidgets() throws -> [WidgetDefinition] {
        let data = loadFixture(named: "widget_definition_appearance.json", subdirectory: "widget_definitions")
        return try JSONDecoder().decode(WidgetDefinitionsEnvelope.self, from: data).widgets
    }

    func testDecodesAppearanceFromSharedFixture() throws {
        let widgets = try fixtureWidgets()
        let appearance = try XCTUnwrap(widgets[0].appearance)
        XCTAssertEqual(appearance.backgroundColor, "#102030")
        XCTAssertEqual(appearance.backgroundOpacity, 0.5)
        XCTAssertEqual(appearance.textColor, "#FFEEAA")
        XCTAssertEqual(appearance.accentColor, "#33CC99")
        XCTAssertEqual(appearance.fontScale, 1.2)
        XCTAssertEqual(appearance.cornerRadius, 24)

        XCTAssertNil(widgets[1].appearance)
        XCTAssertEqual(widgets[2].appearance?.accentColor, "#FF5722")
        XCTAssertNil(widgets[2].appearance?.backgroundColor)
    }

    func testWidgetsWithoutAppearanceKeepTheOriginalLook() {
        let resolved = AppearanceResolver.resolve(nil)
        XCTAssertNil(resolved.backgroundARGB)
        XCTAssertNil(resolved.textARGB)
        XCTAssertNil(resolved.accentARGB)
        XCTAssertEqual(resolved.backgroundOpacity, 1.0)
        XCTAssertEqual(resolved.fontScale, 1.0)
        XCTAssertNil(resolved.dynamicTypeSize)
        XCTAssertEqual(resolved, AppearanceResolver.resolve(WidgetAppearance()))
    }

    func testCustomValuesAreResolved() throws {
        let appearance = try XCTUnwrap(fixtureWidgets()[0].appearance)
        let resolved = AppearanceResolver.resolve(appearance)
        XCTAssertEqual(resolved.backgroundARGB, 0xFF10_2030)
        XCTAssertEqual(resolved.backgroundOpacity, 0.5)
        XCTAssertEqual(resolved.textARGB, 0xFFFF_EEAA)
        XCTAssertEqual(resolved.accentARGB, 0xFF33_CC99)
        XCTAssertEqual(resolved.fontScale, 1.2)
        XCTAssertEqual(resolved.cornerRadius, 24)
        XCTAssertEqual(resolved.dynamicTypeSize, .xLarge)
    }

    func testInvalidAndOutOfRangeValuesFallBackOrClamp() {
        let invalid = AppearanceResolver.resolve(
            WidgetAppearance(backgroundColor: "nope", textColor: "x", accentColor: "#12")
        )
        XCTAssertEqual(invalid, AppearanceResolver.resolve(nil))

        let high = AppearanceResolver.resolve(
            WidgetAppearance(backgroundOpacity: 5, fontScale: 9, cornerRadius: 500)
        )
        XCTAssertEqual(high.backgroundOpacity, 1.0)
        XCTAssertEqual(high.fontScale, 1.4)
        XCTAssertEqual(high.cornerRadius, 32)

        let low = AppearanceResolver.resolve(WidgetAppearance(fontScale: 0.1, cornerRadius: -3))
        XCTAssertEqual(low.fontScale, 0.8)
        XCTAssertEqual(low.cornerRadius, 0)
        XCTAssertEqual(low.dynamicTypeSize, .small)
    }
}
