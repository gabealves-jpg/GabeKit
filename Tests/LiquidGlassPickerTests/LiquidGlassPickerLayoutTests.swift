import Testing
import CoreGraphics
@testable import LiquidGlassPicker

struct LiquidGlassPickerLayoutTests {
    @Test func selectedChipIsCentered() {
        let offsets = LiquidGlassPickerLayout.centeredOffsets(widths: [60, 100, 80], selectedIndex: 1, spacing: 4)
        #expect(offsets == [-84, 0, 94])
    }

    @Test func neighborsStackOutward() {
        let offsets = LiquidGlassPickerLayout.centeredOffsets(widths: [60, 100, 80], selectedIndex: 2, spacing: 4)
        #expect(offsets == [-178, -94, 0])
    }

    @Test func invalidSelectionKeepsEverythingAtCenter() {
        #expect(LiquidGlassPickerLayout.centeredOffsets(widths: [10, 20], selectedIndex: 5, spacing: 4) == [0, 0])
    }
}
