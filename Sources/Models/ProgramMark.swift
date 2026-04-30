enum ProgramMark: String, Codable, Equatable {
    case star
    case bookmark

    var systemImage: String {
        switch self {
        case .star:     "star.fill"
        case .bookmark: "bookmark.fill"
        }
    }

    var label: String {
        switch self {
        case .star:     "お気に入り"
        case .bookmark: "後で聴く"
        }
    }
}
