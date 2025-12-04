import Foundation
import AVFoundation

// Service for loading videos from remote URLs
protocol VideoService {
    func loadVideo(from url: URL) -> AVPlayer
}

final class VideoServiceImpl: VideoService {
    func loadVideo(from url: URL) -> AVPlayer {
        return AVPlayer(url: url)
    }
}

