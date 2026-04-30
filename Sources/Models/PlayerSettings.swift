import Foundation

@MainActor
final class PlayerSettings: ObservableObject {
    static let shared = PlayerSettings()
    static let defaultSet: Set<PlayerButton> = [.prevTrack, .skipBack30, .nextTrack]
    private static let buttonsKey = "player_buttons"
    private static let showTypeKey = "selected_show_type"

    @Published private(set) var selectedSet: Set<PlayerButton> {
        didSet { saveButtons() }
    }

    @Published var selectedShowType: ShowType {
        didSet { UserDefaults.standard.set(selectedShowType.rawValue, forKey: Self.showTypeKey) }
    }

    var selectedButtons: [PlayerButton] {
        PlayerButton.allCases.filter { selectedSet.contains($0) }
    }

    private init() {
        selectedSet = Self.loadButtons() ?? Self.defaultSet
        let raw = UserDefaults.standard.string(forKey: Self.showTypeKey) ?? ShowType.pickup.rawValue
        selectedShowType = ShowType(rawValue: raw) ?? .pickup
    }

    init(testKey: String, initial: Set<PlayerButton>) {
        selectedSet = initial
        selectedShowType = .pickup
    }

    func toggle(_ button: PlayerButton) {
        if selectedSet.contains(button) {
            guard selectedSet.count > 1 else { return }
            selectedSet.remove(button)
        } else if selectedSet.count < 3 {
            selectedSet.insert(button)
        }
    }

    func isSelected(_ button: PlayerButton) -> Bool { selectedSet.contains(button) }

    private static func loadButtons() -> Set<PlayerButton>? {
        guard let data = UserDefaults.standard.data(forKey: buttonsKey),
              let raws = try? JSONDecoder().decode([String].self, from: data) else { return nil }
        let buttons = Set(raws.compactMap(PlayerButton.init(rawValue:)))
        return buttons.isEmpty ? nil : buttons
    }

    private func saveButtons() {
        let data = try? JSONEncoder().encode(selectedSet.map(\.rawValue))
        UserDefaults.standard.set(data, forKey: Self.buttonsKey)
    }
}
