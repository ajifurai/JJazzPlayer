import XCTest
@testable import JJaZZPlayer

@MainActor
final class PlayerSettingsTests: XCTestCase {

    func testDefaultButtons() {
        XCTAssertEqual(PlayerSettings.defaultSet, [.prevTrack, .skipBack30, .nextTrack])
    }

    func testSelectedButtonsSortedByAllCases() {
        // allCases order: prevTrack, skipBack30, skipBack10, skipForward10, nextTrack
        let settings = makeFreshSettings(initial: [.nextTrack, .prevTrack, .skipBack30])
        XCTAssertEqual(settings.selectedButtons, [.prevTrack, .skipBack30, .nextTrack])
    }

    func testToggleAddsButton() {
        let settings = makeFreshSettings(initial: [.prevTrack, .skipBack30])
        settings.toggle(.nextTrack)
        XCTAssertTrue(settings.isSelected(.nextTrack))
        XCTAssertEqual(settings.selectedSet.count, 3)
    }

    func testToggleRemovesButton() {
        let settings = makeFreshSettings(initial: [.prevTrack, .skipBack30, .nextTrack])
        settings.toggle(.prevTrack)
        XCTAssertFalse(settings.isSelected(.prevTrack))
    }

    func testToggleBlockedAtMaxThree() {
        let settings = makeFreshSettings(initial: [.prevTrack, .skipBack30, .nextTrack])
        settings.toggle(.skipForward10)
        XCTAssertFalse(settings.isSelected(.skipForward10))
        XCTAssertEqual(settings.selectedSet.count, 3)
    }

    func testToggleBlockedAtMinOne() {
        let settings = makeFreshSettings(initial: [.prevTrack])
        settings.toggle(.prevTrack)
        XCTAssertTrue(settings.isSelected(.prevTrack))
        XCTAssertEqual(settings.selectedSet.count, 1)
    }

    func testPlayerButtonSystemImages() {
        XCTAssertEqual(PlayerButton.prevTrack.systemImage, "backward.end.fill")
        XCTAssertEqual(PlayerButton.nextTrack.systemImage, "forward.end.fill")
        XCTAssertEqual(PlayerButton.skipBack30.systemImage, "gobackward.30")
        XCTAssertEqual(PlayerButton.skipBack10.systemImage, "gobackward.10")
        XCTAssertEqual(PlayerButton.skipForward10.systemImage, "goforward.10")
    }

    // MARK: - Helpers

    private func makeFreshSettings(initial: Set<PlayerButton>) -> PlayerSettings {
        // Use a unique key per test to avoid cross-test pollution
        let key = UUID().uuidString
        return PlayerSettings(testKey: key, initial: initial)
    }
}
