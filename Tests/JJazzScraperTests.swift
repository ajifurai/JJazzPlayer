import XCTest
@testable import JJaZZPlayer

final class JJazzScraperTests: XCTestCase {
    func testExtractProgNum() {
        let html = "...jjazzplayer('J-1955', null, 'pick-up')..."
        XCTAssertEqual(JJazzScraper.extractProgNum(from: html), "J-1955")
    }

    func testExtractProgNumNotFound() {
        XCTAssertNil(JJazzScraper.extractProgNum(from: "<html></html>"))
    }

    func testMakeHistoryURLApril2026() {
        let url = JJazzScraper.makeHistoryURL(year: 2026, month: 4)
        XCTAssertEqual(url?.absoluteString, "https://www.jjazz.net/programs/pick-up/26april.php")
    }

    func testMakeHistoryURLDecember2025() {
        let url = JJazzScraper.makeHistoryURL(year: 2025, month: 12)
        XCTAssertEqual(url?.absoluteString, "https://www.jjazz.net/programs/pick-up/25december.php")
    }

    func testMakeHistoryURLInvalidMonth() {
        XCTAssertNil(JJazzScraper.makeHistoryURL(year: 2026, month: 13))
        XCTAssertNil(JJazzScraper.makeHistoryURL(year: 2026, month: 0))
    }

    func testGeneratePageInfosCount() {
        let infos = JJazzScraper.generatePageInfos(monthsBack: 6)
        XCTAssertEqual(infos.count, 6)
    }

    func testGeneratePageInfosURLs() {
        let infos = JJazzScraper.generatePageInfos(monthsBack: 3)
        XCTAssertFalse(infos.isEmpty)
        let firstURL = infos[0].0.absoluteString
        XCTAssertTrue(firstURL.hasPrefix("https://www.jjazz.net/programs/pick-up/"))
    }
}
