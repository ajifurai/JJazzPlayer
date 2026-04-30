import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = PlayerSettings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(PlayerButton.allCases) { button in
                        buttonRow(button)
                    }
                } header: {
                    Text("再生コントロール（最大3つ）")
                } footer: {
                    Text("\(settings.selectedSet.count)/3 選択中")
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
    }

    private func buttonRow(_ button: PlayerButton) -> some View {
        let selected = settings.isSelected(button)
        let disabled = !selected && settings.selectedSet.count >= 3
        return Button { settings.toggle(button) } label: {
            HStack(spacing: 14) {
                Image(systemName: button.systemImage)
                    .font(.system(size: 20))
                    .frame(width: 28)
                    .foregroundStyle(selected ? Color.blue : (disabled ? Color.secondary : Color.primary))
                Text(button.label)
                    .foregroundStyle(disabled ? Color.secondary : Color.primary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark").foregroundStyle(.blue)
                }
            }
        }
        .disabled(disabled)
    }
}
