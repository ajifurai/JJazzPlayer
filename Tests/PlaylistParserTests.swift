import XCTest
@testable import JJaZZPlayer

final class PlaylistParserTests: XCTestCase {
    private let sampleHTML = """
    <div id="ins_playlist">
    <table summary="PLAYLIST">
    <tr id="table-header"><th>ALBUM</th><th>SONG</th><th>ARTIST</th><th>TIME</th></tr>
    <tr><td>&nbsp;</td><td colspan="2" class="jingle">JJazz.Net Jingle</td><td class="time">0:00'00&quot;</td></tr>
    <tr><td class="album"><a href="#"><img src="/img_disc/test_2.png" alt="Album" border="0"></a></td><td class="song">Test Song</td><td class="artist"><a href="#">Test Artist</a></td><td class="time">0:00'51&quot;</td></tr>
    <tr><td class="album"><a href="#"><img src="/img_disc/test2_2.jpeg" alt="Album2" border="0"></a></td><td class="song">Second Song</td><td class="artist">Artist 2</td><td class="time">0:04'04&quot;</td></tr>
    <tr><td>&nbsp;</td><td colspan="2" class="tt_text">total time</td><td class="totaltime">0:10'00&quot;</td></tr>
    </table>
    </div>
    """

    func testParsePlaylistCount() {
        let tracks = JJazzScraper.parsePlaylist(from: sampleHTML)
        XCTAssertEqual(tracks.count, 3)
    }

    func testParsePlaylistFirstIsJingle() {
        let tracks = JJazzScraper.parsePlaylist(from: sampleHTML)
        XCTAssertTrue(tracks[0].isJingle)
        XCTAssertEqual(tracks[0].startSeconds, 0)
    }

    func testParsePlaylistSongDetails() {
        let tracks = JJazzScraper.parsePlaylist(from: sampleHTML)
        XCTAssertEqual(tracks[1].song, "Test Song")
        XCTAssertEqual(tracks[1].artist, "Test Artist")
        XCTAssertEqual(tracks[1].startSeconds, 51)
        XCTAssertEqual(tracks[1].albumImageURL?.absoluteString, "https://www.jjazz.net/img_disc/test_2.png")
    }

    func testParsePlaylistEndSeconds() {
        let tracks = JJazzScraper.parsePlaylist(from: sampleHTML)
        XCTAssertEqual(tracks[1].endSeconds, 244)
    }

    func testParseTimeSeconds() {
        XCTAssertEqual(JJazzScraper.parseTime("0:00'51&quot;"), 51)
    }

    func testParseTimeMinutes() {
        XCTAssertEqual(JJazzScraper.parseTime("0:04'04&quot;"), 244)
    }

    func testParseTimeHours() {
        XCTAssertEqual(JJazzScraper.parseTime("1:02'05&quot;"), 3725)
    }

    func testParseEmptyHTML() {
        XCTAssertTrue(JJazzScraper.parsePlaylist(from: "<html></html>").isEmpty)
    }
}
