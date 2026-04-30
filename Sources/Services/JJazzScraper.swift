import Foundation

struct JJazzScraper {
    static let pickupBaseURL = "https://www.jjazz.net/programs/pick-up/"
    static let yorujazzBaseURL = "https://www.jjazz.net/programs/yorujazz/"

    // MARK: - pick-up

    static func fetchPickupPrograms() async throws -> [Program] {
        let pageInfos = generatePageInfos(monthsBack: 12)
        var programs: [Program] = []
        await withTaskGroup(of: Program?.self) { group in
            for (url, year, month) in pageInfos {
                group.addTask { try? await fetchPickupProgram(from: url, year: year, month: month) }
            }
            for await p in group { if let p { programs.append(p) } }
        }
        return deduplicated(programs).sorted { pickupSortKey($0.displayTitle) > pickupSortKey($1.displayTitle) }
    }

    private static func fetchPickupProgram(from url: URL, year: Int, month: Int) async throws -> Program? {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8),
              let progNum = extractProgNum(from: html) else { return nil }
        let title = pickupTitle(year: year, month: month)
        let saved = UserDefaults.standard.double(forKey: "pos_\(progNum)")
        return Program(id: progNum, showType: .pickup, displayTitle: title,
                       savedPosition: saved, tracks: parsePlaylist(from: html))
    }

    private static func pickupTitle(year: Int, month: Int) -> String {
        let names = ["1月","2月","3月","4月","5月","6月",
                     "7月","8月","9月","10月","11月","12月"]
        return "\(year)年\(names[month - 1]) pick-up"
    }

    private static func pickupSortKey(_ title: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: #"(\d{4})年[^\d]*(\d+)月"#),
              let m = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)),
              let yrRange = Range(m.range(at: 1), in: title),
              let moRange = Range(m.range(at: 2), in: title) else { return 0 }
        return (Int(title[yrRange]) ?? 0) * 100 + (Int(title[moRange]) ?? 0)
    }

    // MARK: - 夜ジャズ

    static func fetchYorujazzPrograms(count: Int = 12) async throws -> [Program] {
        let (data, _) = try await URLSession.shared.data(from: URL(string: yorujazzBaseURL)!)
        guard let html = String(data: data, encoding: .utf8) else { return [] }
        let episodes = Array(extractYorujazzEpisodes(from: html).suffix(count))
        var programs: [Program] = []
        await withTaskGroup(of: Program?.self) { group in
            for (url, title) in episodes {
                group.addTask { try? await fetchYorujazzProgram(from: url, title: title) }
            }
            for await p in group { if let p { programs.append(p) } }
        }
        return deduplicated(programs).sorted { episodeNum($0.displayTitle) > episodeNum($1.displayTitle) }
    }

    private static func fetchYorujazzProgram(from url: URL, title: String) async throws -> Program? {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8),
              let progNum = extractProgNum(from: html) else { return nil }
        let saved = UserDefaults.standard.double(forKey: "pos_\(progNum)")
        return Program(id: progNum, showType: .yorujazz, displayTitle: title,
                       savedPosition: saved, tracks: parsePlaylist(from: html))
    }

    private static func extractYorujazzEpisodes(from html: String) -> [(URL, String)] {
        let pattern = #"href="(https://www\.jjazz\.net/programs/yorujazz/[^"]+\.php)" title="([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(html.startIndex..., in: html)
        return regex.matches(in: html, range: range).compactMap { match in
            guard let urlRange = Range(match.range(at: 1), in: html),
                  let titleRange = Range(match.range(at: 2), in: html),
                  let url = URL(string: String(html[urlRange])) else { return nil }
            return (url, String(html[titleRange]))
        }
    }

    private static func episodeNum(_ title: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: #"#(\d+)"#),
              let m = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)),
              let r = Range(m.range(at: 1), in: title) else { return 0 }
        return Int(title[r]) ?? 0
    }

    // MARK: - Shared

    private static func deduplicated(_ programs: [Program]) -> [Program] {
        var seen = Set<String>()
        return programs.filter { seen.insert($0.id).inserted }
    }

    static func extractProgNum(from html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: #"jjazzplayer\('(J-\d+)'"#),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else { return nil }
        return String(html[range])
    }

    static func generatePageInfos(monthsBack: Int) -> [(URL, Int, Int)] {
        let calendar = Calendar.current
        let now = Date()
        var results: [(URL, Int, Int)] = []
        let cur = calendar.dateComponents([.year, .month], from: now)
        if let y = cur.year, let m = cur.month {
            results.append((URL(string: pickupBaseURL)!, y, m))
        }
        for i in 1..<monthsBack {
            guard let date = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            let c = calendar.dateComponents([.year, .month], from: date)
            guard let y = c.year, let m = c.month,
                  let url = makeHistoryURL(year: y, month: m) else { continue }
            results.append((url, y, m))
        }
        return results
    }

    static func makeHistoryURL(year: Int, month: Int) -> URL? {
        let monthNames = ["january","february","march","april","may","june",
                          "july","august","september","october","november","december"]
        guard month >= 1 && month <= 12 else { return nil }
        let yy = String(format: "%02d", year % 100)
        return URL(string: pickupBaseURL + "\(yy)\(monthNames[month - 1]).php")
    }

    // MARK: - Playlist parsing

    static func parsePlaylist(from html: String) -> [Track] {
        guard let tableHTML = extractTableHTML(from: html) else { return [] }
        guard let regex = try? NSRegularExpression(pattern: #"<tr>(.+?)</tr>"#, options: .dotMatchesLineSeparators) else { return [] }
        let range = NSRange(tableHTML.startIndex..., in: tableHTML)
        var entries: [(imgURL: URL?, song: String, artist: String, start: Double, isJingle: Bool)] = []
        for match in regex.matches(in: tableHTML, range: range) {
            guard let r = Range(match.range, in: tableHTML),
                  let entry = parseRow(String(tableHTML[r])) else { continue }
            entries.append(entry)
        }
        return buildTracks(from: entries)
    }

    private static func extractTableHTML(from html: String) -> String? {
        guard let start = html.range(of: #"<div id="ins_playlist">"#),
              let end = html.range(of: "</table>", range: start.upperBound..<html.endIndex) else { return nil }
        return String(html[start.lowerBound..<end.upperBound])
    }

    private static func parseRow(_ row: String) -> (imgURL: URL?, song: String, artist: String, start: Double, isJingle: Bool)? {
        guard row.contains(#"class="time""#) else { return nil }
        if row.contains("table-header") || row.contains("totaltime") || row.contains("tt_text") { return nil }
        let isJingle = row.contains(#"class="jingle""#)
        let imgURL = isJingle ? nil : extractImgURL(from: row)
        let song = isJingle ? "JJazz.Net Jingle" : (firstGroup(pattern: #"class="song">([^<]+)"#, in: row) ?? "")
        let artist = isJingle ? "" : extractArtist(from: row)
        let start = parseTime(firstGroup(pattern: #"class="time">([^<]+)"#, in: row) ?? "")
        return (imgURL, song, artist, start, isJingle)
    }

    private static func buildTracks(from entries: [(imgURL: URL?, song: String, artist: String, start: Double, isJingle: Bool)]) -> [Track] {
        (0..<entries.count).map { i in
            Track(
                id: UUID(),
                song: entries[i].song,
                artist: entries[i].artist,
                albumImageURL: entries[i].imgURL,
                startSeconds: entries[i].start,
                endSeconds: i + 1 < entries.count ? entries[i + 1].start : entries[i].start,
                isJingle: entries[i].isJingle
            )
        }
    }

    private static func extractImgURL(from row: String) -> URL? {
        guard let path = firstGroup(pattern: #"<img src="(/img_disc/[^"]+)""#, in: row) else { return nil }
        return URL(string: "https://www.jjazz.net" + path)
    }

    private static func extractArtist(from row: String) -> String {
        guard let raw = firstGroup(pattern: #"class="artist">(.+?)</td>"#, in: row) else { return "" }
        return (try? NSRegularExpression(pattern: "<[^>]+>"))
            .flatMap { regex -> String? in
                let s = raw as NSString
                return regex.stringByReplacingMatches(in: raw, range: NSRange(location: 0, length: s.length), withTemplate: "")
            }?.trimmingCharacters(in: .whitespaces) ?? raw
    }

    static func parseTime(_ timeStr: String) -> Double {
        let s = timeStr.replacingOccurrences(of: "&quot;", with: "\"")
        guard let regex = try? NSRegularExpression(pattern: #"(\d+):(\d+)'(\d+)""#),
              let match = regex.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)),
              match.numberOfRanges == 4 else { return 0 }
        return Double(intGroup(match, 1, in: s) * 3600 + intGroup(match, 2, in: s) * 60 + intGroup(match, 3, in: s))
    }

    private static func firstGroup(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges >= 2,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }

    private static func intGroup(_ match: NSTextCheckingResult, _ idx: Int, in s: String) -> Int {
        guard let range = Range(match.range(at: idx), in: s) else { return 0 }
        return Int(s[range]) ?? 0
    }
}
