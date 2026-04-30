import AVFoundation
import Combine
import MediaPlayer
import UIKit

@MainActor
final class AudioPlayerService: ObservableObject {
    static let shared = AudioPlayerService()

    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var currentProgram: Program?

    var currentProgramID: String? { currentProgram?.id }

    var currentTrack: Track? {
        guard let tracks = currentProgram?.tracks else { return nil }
        return tracks.last { !$0.isJingle && $0.startSeconds <= currentTime }
    }

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var artworkTask: Task<Void, Never>?
    private var lastArtworkURL: URL?

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        setupRemoteCommands()
    }

    func play(program: Program) {
        guard currentProgram?.id != program.id else {
            player?.play()
            isPlaying = true
            updateNowPlayingInfo()
            return
        }
        saveCurrentPosition()
        loadProgram(program)
    }

    func play(program: Program, from seconds: Double) {
        if currentProgram?.id == program.id {
            seek(to: seconds)
            if !isPlaying { player?.play(); isPlaying = true }
        } else {
            saveCurrentPosition()
            loadProgram(program, seekTo: seconds)
        }
        updateNowPlayingInfo()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        saveCurrentPosition()
        updateNowPlayingInfo()
    }

    func seek(to seconds: Double) {
        currentTime = seconds
        let time = CMTime(seconds: seconds, preferredTimescale: 1000)
        player?.seek(to: time)
    }

    func saveCurrentPosition() {
        guard let id = currentProgram?.id else { return }
        UserDefaults.standard.set(currentTime, forKey: "pos_\(id)")
    }

    // MARK: - Private

    private func loadProgram(_ program: Program, seekTo: Double? = nil) {
        cancellables.removeAll()
        if let token = timeObserver { player?.removeTimeObserver(token); timeObserver = nil }
        let item = AVPlayerItem(url: program.audioURL)
        player = AVPlayer(playerItem: item)
        currentProgram = program
        duration = 0
        lastArtworkURL = nil
        observeStatus(of: item)
        observeEndOfPlayback(for: item)
        addTimeObserver()
        seekAndPlay(to: seekTo ?? program.savedPosition)
    }

    private func observeEndOfPlayback(for item: AVPlayerItem) {
        NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isPlaying = false
                    self.seek(to: 0)
                    UserDefaults.standard.set(0.0, forKey: "pos_\(self.currentProgram?.id ?? "")")
                    self.updateNowPlayingInfo()
                }
            }
            .store(in: &cancellables)
    }

    private func observeStatus(of item: AVPlayerItem) {
        item.publisher(for: \.status)
            .filter { $0 == .readyToPlay }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    if let d = try? await item.asset.load(.duration) {
                        self?.duration = d.seconds.isFinite && d.seconds > 0 ? d.seconds : 0
                        self?.updateNowPlayingInfo()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 1000)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                self?.currentTime = time.seconds
                self?.syncNowPlayingElapsed()
                self?.refreshArtworkIfNeeded()
            }
        }
    }

    private func syncNowPlayingElapsed() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyTitle] = currentTrack?.song ?? currentProgram?.displayTitle ?? ""
        info[MPMediaItemPropertyArtist] = currentTrack?.artist ?? "JJazz.Net"
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func refreshArtworkIfNeeded() {
        let url = currentTrack?.albumImageURL
        guard url != lastArtworkURL else { return }
        lastArtworkURL = url
        fetchAndSetArtwork(url: url)
    }

    private func fetchAndSetArtwork(url: URL?) {
        artworkTask?.cancel()
        guard let url else { return }
        artworkTask = Task {
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  !Task.isCancelled else { return }
            await setArtworkFromData(data)
        }
    }

    @MainActor
    private func setArtworkFromData(_ data: Data) {
        guard let artwork = makeArtwork(from: data) else { return }
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyArtwork] = artwork
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // nonisolated: requestHandler closure inherits non-isolated context
    // so MPMediaItemArtwork can call it from any thread without actor check crash
    private nonisolated func makeArtwork(from data: Data) -> MPMediaItemArtwork? {
        guard let img = UIImage(data: data), let cgImage = img.cgImage else { return nil }
        let size = img.size
        let uiImage = UIImage(cgImage: cgImage, scale: img.scale, orientation: .up)
        return MPMediaItemArtwork(boundsSize: size) { _ in uiImage }
    }

    private func seekAndPlay(to seconds: Double) {
        guard seconds > 1 else {
            player?.play()
            isPlaying = true
            updateNowPlayingInfo()
            return
        }
        let time = CMTime(seconds: seconds, preferredTimescale: 1000)
        player?.seek(to: time) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.player?.play()
                self?.isPlaying = true
                self?.updateNowPlayingInfo()
            }
        }
    }

    private func updateNowPlayingInfo() {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = currentTrack?.song ?? currentProgram?.displayTitle ?? ""
        info[MPMediaItemPropertyArtist] = currentTrack?.artist ?? "JJazz.Net"
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration > 0 ? duration : 0
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        fetchAndSetArtwork(url: currentTrack?.albumImageURL)
    }

    private func setupRemoteCommands() {
        setupPlayPauseCommands()
        setupSkipCommands()
        setupTrackCommands()
    }

    private func setupPlayPauseCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let p = self.currentProgram else { return }
                self.play(program: p)
            }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isPlaying ? self.pause() : self.currentProgram.map { self.play(program: $0) }
            }
            return .success
        }
    }

    private func setupSkipCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.skipForwardCommand.preferredIntervals = [30]
        center.skipForwardCommand.addTarget { [weak self] event in
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            Task { @MainActor [weak self] in self?.seek(to: (self?.currentTime ?? 0) + event.interval) }
            return .success
        }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget { [weak self] event in
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            Task { @MainActor [weak self] in self?.seek(to: max(0, (self?.currentTime ?? 0) - event.interval)) }
            return .success
        }
    }

    private func setupTrackCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.skipToNextTrack() }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.skipToPreviousTrack() }
            return .success
        }
    }

    private var currentTrackIndex: Int? {
        guard let tracks = currentProgram?.tracks else { return nil }
        return tracks.indices.last { !tracks[$0].isJingle && tracks[$0].startSeconds <= currentTime }
    }

    func skipToNextTrack() {
        guard let tracks = currentProgram?.tracks, let idx = currentTrackIndex else { return }
        guard let nextIdx = tracks.indices.dropFirst(idx + 1).first(where: { !tracks[$0].isJingle }) else { return }
        seek(to: tracks[nextIdx].startSeconds)
    }

    func skipToPreviousTrack() {
        guard let tracks = currentProgram?.tracks, let idx = currentTrackIndex else { return }
        let track = tracks[idx]
        if currentTime - track.startSeconds > 3 {
            seek(to: track.startSeconds)
        } else {
            guard let prevIdx = tracks.indices.prefix(idx).last(where: { !tracks[$0].isJingle }) else { return }
            seek(to: tracks[prevIdx].startSeconds)
        }
    }
}
