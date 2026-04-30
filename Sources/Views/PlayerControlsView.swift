import AVKit
import SwiftUI

struct PlayerControlsView: View {
    @ObservedObject private var player = AudioPlayerService.shared
    @ObservedObject private var settings = PlayerSettings.shared
    @State private var isDragging = false
    @State private var sliderValue: Double = 0

    var body: some View {
        if let program = player.currentProgram {
            playerCard(program: program)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .onChange(of: player.currentTime) { _, t in
                    if !isDragging { sliderValue = t }
                }
        }
    }

    private func playerCard(program: Program) -> some View {
        VStack(spacing: 8) {
            currentTrackRow(program: program)
            progressRow
            controlsRow(program: program)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func currentTrackRow(program: Program) -> some View {
        HStack(spacing: 10) {
            albumArtView
            VStack(alignment: .leading, spacing: 2) {
                Text(player.currentTrack?.song ?? program.displayTitle)
                    .font(.subheadline).bold().lineLimit(1)
                if let artist = player.currentTrack?.artist, !artist.isEmpty {
                    Text(artist).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
        }
    }

    private var albumArtView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.2)).frame(width: 44, height: 44)
            if let url = player.currentTrack?.albumImageURL {
                AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { EmptyView() }
                    .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "music.note").foregroundStyle(.secondary)
            }
        }
    }

    private var progressRow: some View {
        HStack(spacing: 8) {
            Text(formatTime(sliderValue)).font(.caption).monospacedDigit()
            Slider(value: $sliderValue, in: 0...max(player.duration, 1)) { editing in
                isDragging = editing
                if !editing { player.seek(to: sliderValue) }
            }
            Text(formatTime(player.duration)).font(.caption).monospacedDigit()
        }
    }

    private func controlsRow(program: Program) -> some View {
        let left = settings.selectedButtons.filter { !$0.isRightOfPlay }
        let right = settings.selectedButtons.filter { $0.isRightOfPlay }
        return HStack(spacing: 0) {
            Spacer()
            if left.count > 0 { actionButton(left[0], program: program); Spacer() }
            if left.count > 1 { actionButton(left[1], program: program); Spacer() }
            if left.count > 2 { actionButton(left[2], program: program); Spacer() }
            playPauseButton(program: program)
            Spacer()
            if right.count > 0 { actionButton(right[0], program: program); Spacer() }
            if right.count > 1 { actionButton(right[1], program: program); Spacer() }
            RoutePickerView().frame(width: 32, height: 32)
        }
    }

    private func actionButton(_ button: PlayerButton, program: Program) -> some View {
        Button { perform(button) } label: {
            Image(systemName: button.systemImage)
                .font(.system(size: 26))
                .foregroundStyle(.primary)
        }
    }

    private func perform(_ button: PlayerButton) {
        switch button {
        case .prevTrack:     player.skipToPreviousTrack()
        case .nextTrack:     player.skipToNextTrack()
        case .skipBack30:    player.seek(to: max(0, player.currentTime - 30))
        case .skipBack10:    player.seek(to: max(0, player.currentTime - 10))
        case .skipForward10: player.seek(to: player.currentTime + 10)
        }
    }

    private func playPauseButton(program: Program) -> some View {
        Button {
            player.isPlaying ? player.pause() : player.play(program: program)
        } label: {
            Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 44)).foregroundStyle(.blue)
        }
    }

    private func formatTime(_ s: Double) -> String {
        guard s.isFinite && s >= 0 else { return "0:00" }
        let m = Int(s) / 60, sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }
}

struct RoutePickerView: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView()
        v.tintColor = .label
        return v
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
