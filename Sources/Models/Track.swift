import Foundation

struct Track: Identifiable, Codable {
    let id: UUID
    let song: String
    let artist: String
    let albumImageURL: URL?
    let startSeconds: Double
    var endSeconds: Double
    let isJingle: Bool

    var durationSeconds: Double { endSeconds - startSeconds }
}
