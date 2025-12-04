import Foundation
import AVFoundation
import Combine
import SwiftUI

// ViewModel managing video player state and actions
@available(iOS 15.0, *)
@MainActor
final class VideoPlayerViewModel: ObservableObject {
    @Published var playbackState: PlaybackState = .idle
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 0.0
    @Published var isMuted: Bool = false
    @Published var playbackSpeed: PlaybackSpeed = .normal
    @Published var isFullscreen: Bool = false
    @Published var isSeeking: Bool = false
    
    private(set) var player: AVPlayer?
    
    nonisolated(unsafe) private let createVideoPlayerUseCase: CreateVideoPlayerUseCase
    nonisolated(unsafe) private var timeObserver: Any?
    nonisolated(unsafe) private var cancellables = Set<AnyCancellable>()
    private let videoItem: VideoItem
    
    // Returns true if video is currently playing
    var isPlaying: Bool {
        playbackState == .playing
    }
    
    // Formats current time as HH:MM:SS or MM:SS
    var formattedCurrentTime: String {
        formatTime(currentTime)
    }
    
    // Formats total duration as HH:MM:SS or MM:SS
    var formattedDuration: String {
        formatTime(duration)
    }
    
    // Calculates playback progress (0.0 to 1.0)
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    nonisolated init(createVideoPlayerUseCase: CreateVideoPlayerUseCase, videoItem: VideoItem) {
        self.createVideoPlayerUseCase = createVideoPlayerUseCase
        self.videoItem = videoItem
        
        Task { @MainActor in
            self.setupPlayer()
        }
    }
    
    deinit {
        if let observer = timeObserver, let playerInstance = player {
            playerInstance.removeTimeObserver(observer)
        }
        cancellables.removeAll()
    }
    
    // Initializes player with video URL
    private func setupPlayer() {
        playbackState = .loading
        
        let avPlayer = createVideoPlayerUseCase.execute(for: videoItem)
        self.player = avPlayer
        
        setupTimeObserver()
        setupPlayerObservers()
        
        // Load duration asynchronously
        avPlayer.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.updateDuration()
                self.playbackState = .paused
            }
        }
    }
    
    // Observes playback time every 0.1 seconds
    private func setupTimeObserver() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self = self, !self.isSeeking else { return }
                self.currentTime = time.seconds
            }
        }
    }
    
    // Observes player events (end, errors)
    private func setupPlayerObservers() {
        guard let player = player else { return }
        
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleVideoEnd()
                }
            }
            .store(in: &cancellables)
        
        player.publisher(for: \.currentItem?.status)
            .sink { [weak self] status in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    if status == .failed {
                        self.playbackState = .failed(NSError(domain: "VideoPlayer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error loading video"]))
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // Updates duration from player item
    private func updateDuration() {
        guard let player = player,
              let item = player.currentItem else { return }
        
        let duration = item.duration
        guard duration.isNumeric else { return }
        
        self.duration = duration.seconds
    }
    
    // Toggles between play and pause states
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    // Starts video playback
    func play() {
        guard let player = player else { return }
        player.play()
        playbackState = .playing
    }
    
    // Pauses video playback
    func pause() {
        guard let player = player else { return }
        player.pause()
        playbackState = .paused
    }
    
    // Stops playback and resets to beginning
    func stop() {
        pause()
        seek(to: 0)
    }
    
    // Toggles audio mute state
    func toggleMute() {
        guard let player = player else { return }
        isMuted.toggle()
        player.isMuted = isMuted
    }
    
    // Changes playback speed (0.5x, 1x, 2x)
    func setPlaybackSpeed(_ speed: PlaybackSpeed) {
        guard let player = player else { return }
        playbackSpeed = speed
        player.rate = Float(speed.rawValue)
        
        if playbackState == .paused {
            player.rate = 0
        }
    }
    
    // Seeks to specific time in video
    func seek(to time: Double) {
        guard let player = player else { return }
        
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        player.seek(to: cmTime) { [weak self] completed in
            Task { @MainActor [weak self] in
                guard let self = self, completed else { return }
                self.currentTime = time
                self.isSeeking = false
            }
        }
    }
    
    // Marks seeking as started
    func startSeeking() {
        isSeeking = true
    }
    
    // Completes seeking operation
    func endSeeking(at time: Double) {
        seek(to: time)
    }
    
    // Toggles fullscreen mode
    func toggleFullscreen() {
        isFullscreen.toggle()
    }
    
    // Called when view appears
    func handleAppearance() {
        if playbackState == .idle {
            setupPlayer()
        }
    }
    
    // Called when view disappears
    func handleDisappearance() {
        if isPlaying {
            pause()
        }
    }
    
    // Handles video playback completion
    private func handleVideoEnd() {
        playbackState = .paused
        seek(to: 0)
    }
    
    // Formats seconds to time string
    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite && !seconds.isNaN else { return "00:00" }
        
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}
