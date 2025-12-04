import Foundation

// Represents the current state of video playback
enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case failed(Error)
    
    // Custom equality for Error case
    static func == (lhs: PlaybackState, rhs: PlaybackState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.loading, .loading),
             (.playing, .playing),
             (.paused, .paused):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

// Available playback speeds
enum PlaybackSpeed: Double, CaseIterable {
    case slow = 0.5
    case normal = 1.0
    case fast = 2.0
    
    var displayName: String {
        switch self {
        case .slow: return "0.5x"
        case .normal: return "1x"
        case .fast: return "2x"
        }
    }
}

