import XCTest
@testable import JJaZZPlayer

final class ProgramTests: XCTestCase {
    func testAudioURL() {
        let prog = Program(id: "J-1955", showType: .pickup, displayTitle: "2026年4月 pick-up", savedPosition: 0)
        XCTAssertEqual(prog.audioURL.absoluteString,
                       "https://jjazz-aod.leanstream.co:8001/jjazz/J-1955.mp3")
    }

    func testPickupDisplayTitle() {
        let prog = Program(id: "J-1955", showType: .pickup, displayTitle: "2026年4月 pick-up", savedPosition: 0)
        XCTAssertEqual(prog.displayTitle, "2026年4月 pick-up")
    }

    func testYorujazzDisplayTitle() {
        let prog = Program(id: "J-2000", showType: .yorujazz, displayTitle: "夜ジャズ.Net#211 - akiko", savedPosition: 0)
        XCTAssertEqual(prog.displayTitle, "夜ジャズ.Net#211 - akiko")
        XCTAssertEqual(prog.showType, .yorujazz)
    }
}
