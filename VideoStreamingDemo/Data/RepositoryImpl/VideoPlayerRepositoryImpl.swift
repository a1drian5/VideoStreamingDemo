import Foundation
import AVFoundation

// Implementation of video player repository
final class VideoPlayerRepositoryImpl: VideoPlayerRepository {
    private let videoService: VideoService
    
    init(videoService: VideoService) {
        self.videoService = videoService
    }
    
    func createPlayer(for url: URL) -> AVPlayer {
        return videoService.loadVideo(from: url)
    }
    
    // Validates URL scheme for streaming
    func validateVideoURL(_ url: URL) -> Bool {
        let validSchemes = ["http", "https"]
        guard let scheme = url.scheme?.lowercased() else {
            return false
        }
        return validSchemes.contains(scheme)
    }
}

