import SwiftUI

struct ProgramRowView: View {
    let program: Program
    @ObservedObject private var player = AudioPlayerService.shared

    private var isActive: Bool { player.currentProgramID == program.id }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(isActive && player.isPlaying ? Color.blue : Color.clear)
                .frame(width: 4, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(program.displayTitle).font(.headline)
                HStack(spacing: 0) {
                    if program.savedPosition > 1 {
                        Text("再生位置: \(formatTime(program.savedPosition))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if !program.tracks.isEmpty {
                        let songCount = program.tracks.filter { !$0.isJingle }.count
                        Text(program.savedPosition > 1 ? "  ・\(songCount)曲" : "\(songCount)曲")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ s: Double) -> String {
        let h = Int(s) / 3600, m = (Int(s) % 3600) / 60, sec = Int(s) % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
    }
}
