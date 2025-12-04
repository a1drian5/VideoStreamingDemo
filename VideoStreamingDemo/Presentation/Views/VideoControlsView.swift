import SwiftUI

// Custom video controls overlay
@available(iOS 15.0, *)
struct VideoControlsView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    
    let isLandscape: Bool
    let availableWidth: CGFloat
    let availableHeight: CGFloat
    let safeAreaInsets: EdgeInsets
    
    @State private var sliderValue: Double = 0
    
    var body: some View {
        controlsContainer
    }
    
    // Main container for all controls
    private var controlsContainer: some View {
        VStack(spacing: isLandscape ? 8 : 16) {
            progressSection
            playbackControlsSection
            additionalControlsSection
        }
        .padding(.horizontal, isLandscape ? 16 : 20)
        .padding(.top, isLandscape ? 12 : 20)
        .padding(.bottom, isLandscape ? max(safeAreaInsets.bottom + 8, 20) : 20)
        .frame(maxWidth: availableWidth)
        .background(gradientBackground)
    }
    
    // Gradient background for controls
    private var gradientBackground: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.7), .black.opacity(0.9)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // Progress slider and time labels
    private var progressSection: some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { viewModel.isSeeking ? sliderValue : viewModel.currentTime },
                    set: { newValue in
                        sliderValue = newValue
                        viewModel.startSeeking()
                    }
                ),
                in: 0...max(viewModel.duration, 1),
                onEditingChanged: { editing in
                    if !editing {
                        viewModel.endSeeking(at: sliderValue)
                    }
                }
            )
            .tint(.red)
            
            HStack {
                Text(viewModel.formattedCurrentTime)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(viewModel.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
    
    // Main playback controls (mute, play/pause, fullscreen)
    private var playbackControlsSection: some View {
        HStack(spacing: isLandscape ? 30 : 40) {
            Button(action: { viewModel.toggleMute() }) {
                Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(isLandscape ? .title3 : .title2)
                    .foregroundColor(.white)
                    .frame(minWidth: 44, minHeight: 44)
            }
            
            Spacer()
            
            Button(action: { viewModel.togglePlayPause() }) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: isLandscape ? 50 : 60))
                    .foregroundColor(.white)
                    .frame(minWidth: 60, minHeight: 60)
            }
            
            Spacer()
            
            Button(action: { viewModel.toggleFullscreen() }) {
                Image(systemName: viewModel.isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(isLandscape ? .title3 : .title2)
                    .foregroundColor(.white)
                    .frame(minWidth: 44, minHeight: 44)
            }
        }
        .frame(height: isLandscape ? 50 : 60)
    }
    
    // Speed control buttons
    private var additionalControlsSection: some View {
        HStack(spacing: isLandscape ? 8 : 12) {
            Text("Speed:")
                .font(.caption)
                .foregroundColor(.white)
            
            ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
                Button(action: { viewModel.setPlaybackSpeed(speed) }) {
                    Text(speed.displayName)
                        .font(.caption)
                        .fontWeight(viewModel.playbackSpeed == speed ? .bold : .regular)
                        .foregroundColor(.white)
                        .padding(.horizontal, isLandscape ? 10 : 12)
                        .padding(.vertical, isLandscape ? 5 : 6)
                        .background(
                            viewModel.playbackSpeed == speed
                                ? Color.red
                                : Color.white.opacity(0.3)
                        )
                        .cornerRadius(8)
                }
            }
        }
        .frame(height: isLandscape ? 28 : 32)
    }
}
