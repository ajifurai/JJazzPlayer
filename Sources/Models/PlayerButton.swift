enum PlayerButton: String, CaseIterable, Identifiable, Hashable {
    case prevTrack, skipBack30, skipBack10, skipForward10, nextTrack

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .prevTrack:     "backward.end.fill"
        case .skipBack30:    "gobackward.30"
        case .skipBack10:    "gobackward.10"
        case .skipForward10: "goforward.10"
        case .nextTrack:     "forward.end.fill"
        }
    }

    var label: String {
        switch self {
        case .prevTrack:     "前の曲"
        case .skipBack30:    "30秒戻し"
        case .skipBack10:    "10秒戻し"
        case .skipForward10: "10秒進み"
        case .nextTrack:     "次の曲"
        }
    }

    var isRightOfPlay: Bool {
        self == .skipForward10 || self == .nextTrack
    }
}
