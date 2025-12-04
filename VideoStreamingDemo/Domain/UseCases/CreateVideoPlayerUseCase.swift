import Foundation
import AVFoundation

// Use case for creating video player instances
final class CreateVideoPlayerUseCase {
    private let repository: VideoPlayerRepository
    
    init(repository: VideoPlayerRepository) {
        self.repository = repository
    }
    
    func execute(for videoItem: VideoItem) -> AVPlayer {
        return repository.createPlayer(for: videoItem.url)
    }
}

