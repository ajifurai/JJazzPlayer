import Foundation

@MainActor
final class PlayerSettings: ObservableObject {
    static let shared = PlayerSettings()
    static let defaultSet: Set<PlayerButton> = [.prevTrack, .skipBack30, .nextTrack]
    private static let key = "player_buttons"

    @Published private(set) var selectedSet: Set<PlayerButton> {
        didSet { save() }
    }

    var selectedButtons: [PlayerButton] {
        PlayerButton.allCases.filter { selectedSet.contains($0) }
    }

    private init() {
        selectedSet = Self.load() ?? Self.defaultSet
    }

    init(testKey: String, initial: Set<PlayerButton>) {
        selectedSet = initial
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

    private static func load() -> Set<PlayerButton>? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let raws = try? JSONDecoder().decode([String].self, from: data) else { return nil }
        let buttons = Set(raws.compactMap(PlayerButton.init(rawValue:)))
        return buttons.isEmpty ? nil : buttons
    }

    private func save() {
        let data = try? JSONEncoder().encode(selectedSet.map(\.rawValue))
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
