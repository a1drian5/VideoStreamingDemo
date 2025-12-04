import Foundation

// Model representing a video item
struct VideoItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let url: URL
    
    init(id: UUID = UUID(), title: String, url: URL) {
        self.id = id
        self.title = title
        self.url = url
    }
}

