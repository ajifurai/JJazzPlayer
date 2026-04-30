import SwiftUI

struct ProgramDetailView: View {
    let program: Program
    @ObservedObject private var player = AudioPlayerService.shared
    @State private var showSettings = false

    var body: some View {
        List {
            ForEach(Array(program.tracks.enumerated()), id: \.offset) { index, track in
                TrackRowView(track: track, isActive: isTrackActive(index: index))
                    .contentShape(Rectangle())
                    .onTapGesture { player.play(program: program, from: track.startSeconds) }
                    .listRowSeparator(track.isJingle ? .hidden : .visible)
                    .opacity(track.isJingle ? 0.45 : 1.0)
            }
        }
        .safeAreaInset(edge: .bottom) { PlayerControlsView() }
        .navigationTitle(program.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    private func isTrackActive(index: Int) -> Bool {
        guard player.currentProgramID == program.id else { return false }
        let tracks = program.tracks
        let track = tracks[index]
        let nextStart = index + 1 < tracks.count ? tracks[index + 1].startSeconds : Double.infinity
        return track.startSeconds <= player.currentTime && player.currentTime < nextStart
    }
}
