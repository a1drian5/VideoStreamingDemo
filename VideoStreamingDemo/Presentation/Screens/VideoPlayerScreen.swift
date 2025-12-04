import SwiftUI
import AVKit

// Main video player screen with custom controls
@available(iOS 15.0, *)
struct VideoPlayerScreen: View {
    @StateObject private var viewModel: VideoPlayerViewModel
    @State private var controlsOpacity: Double = 1.0
    @State private var hideControlsTask: Task<Void, Never>?
    
    init(viewModel: VideoPlayerViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundLayer
                
                videoPlayerContent
                    .zIndex(1)
                
                controlsOverlay(geometry: geometry)
                    .zIndex(100)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .opacity(controlsOpacity)
                    .animation(.easeInOut(duration: 0.3), value: controlsOpacity)
                
                if viewModel.playbackState == .loading {
                    loadingOverlay
                        .zIndex(200)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { showControls() }
        }
        .ignoresSafeArea()
        .navigationTitle(viewModel.isFullscreen ? "" : "Video Player")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(viewModel.isFullscreen)
        .statusBarHidden(viewModel.isFullscreen)
        .onAppear(perform: handleViewAppearance)
        .onDisappear(perform: handleViewDisappearance)
        .onChange(of: viewModel.isFullscreen, perform: handleFullscreenChange)
        .onChange(of: viewModel.playbackState, perform: handlePlaybackStateChange)
        .alert("Error", isPresented: .constant(isErrorState)) {
            Button("OK", role: .cancel) { }
        } message: {
            if case .failed(let error) = viewModel.playbackState {
                Text(error.localizedDescription)
            }
        }
    }
    
    // Black background for video
    private var backgroundLayer: some View {
        Color.black
            .ignoresSafeArea()
            .zIndex(0)
    }
    
    // Main video player or placeholder
    private var videoPlayerContent: some View {
        Group {
            if let player = viewModel.player {
                CustomVideoPlayerView(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                placeholderView
            }
        }
    }
    
    // Placeholder shown when no video
    private var placeholderView: some View {
        VStack {
            Image(systemName: "video.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No video available")
                .foregroundColor(.gray)
        }
    }
    
    // Creates controls overlay with geometry
    private func controlsOverlay(geometry: GeometryProxy) -> some View {
        let isLandscape = geometry.size.width > geometry.size.height
        
        return VideoControlsView(
            viewModel: viewModel,
            isLandscape: isLandscape,
            availableWidth: geometry.size.width,
            availableHeight: geometry.size.height,
            safeAreaInsets: EdgeInsets(
                top: geometry.safeAreaInsets.top,
                leading: geometry.safeAreaInsets.leading,
                bottom: geometry.safeAreaInsets.bottom,
                trailing: geometry.safeAreaInsets.trailing
            )
        )
        .allowsHitTesting(controlsOpacity > 0.5)
    }
    
    // Loading indicator overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                Text("Loading video...")
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
        }
    }
    
    // Checks if playback is in error state
    private var isErrorState: Bool {
        if case .failed = viewModel.playbackState {
            return true
        }
        return false
    }
    
    // Shows controls and schedules auto-hide
    private func showControls() {
        hideControlsTask?.cancel()
        controlsOpacity = 1.0
        scheduleHideControls()
    }
    
    // Hides controls with fade animation
    private func hideControls() {
        controlsOpacity = 0.0
    }
    
    // Auto-hide controls after 3 seconds
    private func scheduleHideControls() {
        hideControlsTask?.cancel()
        guard viewModel.isPlaying else { return }
        
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            
            if !Task.isCancelled && viewModel.isPlaying {
                await MainActor.run {
                    hideControls()
                }
            }
        }
    }
    
    // Called when view appears on screen
    private func handleViewAppearance() {
        viewModel.handleAppearance()
        scheduleHideControls()
    }
    
    // Called when view disappears from screen
    private func handleViewDisappearance() {
        viewModel.handleDisappearance()
        AppDelegate.orientationLock = .portrait
        DeviceRotationHelper.forceRotation(to: .portrait)
    }
    
    // Handles device rotation on fullscreen toggle
    private func handleFullscreenChange(_ isFullscreen: Bool) {
        if isFullscreen {
            AppDelegate.orientationLock = .landscape
            DeviceRotationHelper.forceRotation(to: .landscape)
            
            hideControlsTask?.cancel()
            controlsOpacity = 1.0
            
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    scheduleHideControls()
                }
            }
        } else {
            AppDelegate.orientationLock = .portrait
            DeviceRotationHelper.forceRotation(to: .portrait)
            showControls()
        }
    }
    
    // Manages controls visibility based on playback state
    private func handlePlaybackStateChange(_ state: PlaybackState) {
        if state == .paused {
            hideControlsTask?.cancel()
            controlsOpacity = 1.0
        } else if state == .playing {
            if controlsOpacity > 0.5 {
                scheduleHideControls()
            }
        }
    }
}

#if DEBUG
@available(iOS 15.0, *)
struct VideoPlayerScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VideoPlayerScreen(viewModel: DependencyContainer.shared.videoPlayerViewModel)
        }
        .preferredColorScheme(.dark)
    }
}
#endif
