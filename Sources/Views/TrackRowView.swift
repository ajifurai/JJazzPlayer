import SwiftUI

struct TrackRowView: View {
    let track: Track
    let isActive: Bool
    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 10) {
            albumArt
            VStack(alignment: .leading, spacing: 2) {
                Text(track.song)
                    .font(.subheadline)
                    .fontWeight(isActive ? .bold : .regular)
                    .foregroundStyle(isActive ? Color.blue : Color.primary)
                if !track.artist.isEmpty {
                    Text(track.artist).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(formatTime(track.startSeconds)).font(.caption2).foregroundStyle(.tertiary).monospacedDigit()
        }
        .padding(.vertical, 2)
        .contextMenu { if !track.isJingle { searchMenu } }
    }

    @ViewBuilder
    private var searchMenu: some View {
        Section("Apple Music") {
            Button { open(query: track.song, service: .appleMusic) } label: {
                Label("曲名「\(track.song)」", systemImage: "music.note")
            }
            if !track.artist.isEmpty {
                Button { open(query: track.artist, service: .appleMusic) } label: {
                    Label("アーティスト「\(track.artist)」", systemImage: "person")
                }
            }
        }
        Section("Spotify") {
            Button { open(query: track.song, service: .spotify) } label: {
                Label("曲名「\(track.song)」", systemImage: "music.note")
            }
            if !track.artist.isEmpty {
                Button { open(query: track.artist, service: .spotify) } label: {
                    Label("アーティスト「\(track.artist)」", systemImage: "person")
                }
            }
        }
    }

    private enum MusicService { case appleMusic, spotify }

    private func open(query: String, service: MusicService) {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlStr = service == .appleMusic
            ? "music://music.apple.com/search?term=\(encoded)"
            : "spotify:search:\(encoded)"
        if let url = URL(string: urlStr) { openURL(url) }
    }

    private var albumArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.15)).frame(width: 44, height: 44)
            if let url = track.albumImageURL {
                AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { EmptyView() }
                    .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "music.note").foregroundStyle(.secondary)
            }
        }
    }

    private func formatTime(_ s: Double) -> String {
        let m = Int(s) / 60, sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }
}
