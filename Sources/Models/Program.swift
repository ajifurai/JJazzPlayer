import Foundation

enum ShowType: String, Codable {
    case pickup = "pick-up"
    case yorujazz
}

struct Program: Identifiable, Codable {
    let id: String
    let showType: ShowType
    let displayTitle: String
    var savedPosition: Double
    var tracks: [Track] = []

    var audioURL: URL {
        URL(string: "https://jjazz-aod.leanstream.co:8001/jjazz/\(id).mp3")!
    }
}
