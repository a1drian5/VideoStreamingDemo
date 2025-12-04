import SwiftUI

// Main app entry point
@available(iOS 15.0, *)
@main
struct SwiftUIVideoPlayerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let dependencyContainer = DependencyContainer.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                VideoPlayerScreen(viewModel: dependencyContainer.videoPlayerViewModel)
            }
            .navigationViewStyle(.stack)
        }
    }
}
