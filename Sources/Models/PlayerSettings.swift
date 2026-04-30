import Foundation

@MainActor
final class PlayerSettings: ObservableObject {
    static let shared = PlayerSettings()
    static let defaultSet: Set<PlayerButton> = [.prevTrack, .skipBack30, .nextTrack]
    private static let buttonsKey  = "player_buttons"
    private static let showTypeKey = "selected_show_type"
    private static let marksKey    = "program_marks"
    private static let hiddenKey   = "hidden_programs"

    @Published private(set) var selectedSet: Set<PlayerButton> { didSet { saveButtons() } }
    @Published var selectedShowType: ShowType { didSet { saveShowType() } }
    @Published var programMarks: [String: ProgramMark] { didSet { saveMarks() } }
    @Published var hiddenPrograms: Set<String> { didSet { saveHidden() } }

    var selectedButtons: [PlayerButton] { PlayerButton.allCases.filter { selectedSet.contains($0) } }

    private init() {
        selectedSet = Self.loadButtons() ?? Self.defaultSet
        let raw = UserDefaults.standard.string(forKey: Self.showTypeKey) ?? ShowType.pickup.rawValue
        selectedShowType = ShowType(rawValue: raw) ?? .pickup
        programMarks = Self.loadMarks()
        hiddenPrograms = Self.loadHidden()
    }

    init(testKey: String, initial: Set<PlayerButton>) {
        selectedSet = initial
        selectedShowType = .pickup
        programMarks = [:]
        hiddenPrograms = []
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

    func toggleMark(_ mark: ProgramMark, for id: String) {
        programMarks[id] = programMarks[id] == mark ? nil : mark
    }

    func hide(_ id: String) { hiddenPrograms.insert(id) }
    func clearAllMarks() { programMarks = [:] }
    func clearHidden() { hiddenPrograms = [] }

    // MARK: - Save

    private func saveShowType() {
        UserDefaults.standard.set(selectedShowType.rawValue, forKey: Self.showTypeKey)
    }

    private func saveButtons() {
        let data = try? JSONEncoder().encode(selectedSet.map(\.rawValue))
        UserDefaults.standard.set(data, forKey: Self.buttonsKey)
    }

    private func saveMarks() {
        let data = try? JSONEncoder().encode(programMarks.mapValues(\.rawValue))
        UserDefaults.standard.set(data, forKey: Self.marksKey)
    }

    private func saveHidden() {
        let data = try? JSONEncoder().encode(Array(hiddenPrograms))
        UserDefaults.standard.set(data, forKey: Self.hiddenKey)
    }

    // MARK: - Load

    private static func loadButtons() -> Set<PlayerButton>? {
        guard let data = UserDefaults.standard.data(forKey: buttonsKey),
              let raws = try? JSONDecoder().decode([String].self, from: data) else { return nil }
        let buttons = Set(raws.compactMap(PlayerButton.init(rawValue:)))
        return buttons.isEmpty ? nil : buttons
    }

    private static func loadMarks() -> [String: ProgramMark] {
        guard let data = UserDefaults.standard.data(forKey: marksKey),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return dict.compactMapValues(ProgramMark.init(rawValue:))
    }

    private static func loadHidden() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: hiddenKey),
              let arr = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return Set(arr)
    }
}
