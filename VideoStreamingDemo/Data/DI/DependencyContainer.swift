import Foundation
import Swinject

// Dependency injection container using Swinject
final class DependencyContainer {
    static let shared = DependencyContainer()
    let container: Container
    
    private init() {
        container = Container()
        registerDependencies()
    }
    
    private func registerDependencies() {
        registerDataLayer()
        registerDomainLayer()
        registerPresentationLayer()
    }
    
    // Register data layer services and repositories
    private func registerDataLayer() {
        container.register(VideoService.self) { _ in
            VideoServiceImpl()
        }.inObjectScope(.container)
        
        container.register(VideoPlayerRepository.self) { resolver in
            let videoService = resolver.resolve(VideoService.self)!
            return VideoPlayerRepositoryImpl(videoService: videoService)
        }.inObjectScope(.container)
    }
    
    // Register domain layer use cases
    private func registerDomainLayer() {
        container.register(CreateVideoPlayerUseCase.self) { resolver in
            let repository = resolver.resolve(VideoPlayerRepository.self)!
            return CreateVideoPlayerUseCase(repository: repository)
        }
    }
    
    // Register presentation layer ViewModels
    private func registerPresentationLayer() {
        container.register(VideoItem.self) { _ in
            VideoItem(
                title: "Big Buck Bunny",
                url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!
            )
        }
        
        container.register(VideoPlayerViewModel.self) { resolver in
            let createVideoPlayerUseCase = resolver.resolve(CreateVideoPlayerUseCase.self)!
            let videoItem = resolver.resolve(VideoItem.self)!
            return VideoPlayerViewModel(
                createVideoPlayerUseCase: createVideoPlayerUseCase,
                videoItem: videoItem
            )
        }
    }
    
    func resolve<T>(_ serviceType: T.Type) -> T? {
        return container.resolve(serviceType)
    }
}

extension DependencyContainer {
    var videoPlayerViewModel: VideoPlayerViewModel {
        guard let viewModel = resolve(VideoPlayerViewModel.self) else {
            fatalError("VideoPlayerViewModel is not registered in the DI container")
        }
        return viewModel
    }
    
    var videoItem: VideoItem {
        guard let item = resolve(VideoItem.self) else {
            fatalError("VideoItem is not registered in the DI container")
        }
        return item
    }
}
