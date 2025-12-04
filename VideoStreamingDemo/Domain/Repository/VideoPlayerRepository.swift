import Foundation
import AVFoundation

// Repository protocol for video player operations
protocol VideoPlayerRepository {
    func createPlayer(for url: URL) -> AVPlayer
    func validateVideoURL(_ url: URL) -> Bool
}

