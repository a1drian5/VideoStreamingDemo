import SwiftUI
import AVKit

// Custom video player wrapper using AVPlayerLayer
@available(iOS 15.0, *)
struct CustomVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer?
    
    // Creates the UIView for SwiftUI
    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView()
        view.player = player
        view.backgroundColor = .black
        return view
    }
    
    // Updates the UIView when state changes
    func updateUIView(_ uiView: UIView, context: Context) {
        if let playerView = uiView as? PlayerUIView {
            playerView.player = player
        }
    }
}

// UIView containing AVPlayerLayer
class PlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer?
    
    var player: AVPlayer? {
        didSet {
            setupPlayerLayer()
        }
    }
    
    // Updates layer frame on size changes
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
    
    // Configures AVPlayerLayer with current player
    private func setupPlayerLayer() {
        playerLayer?.removeFromSuperlayer()
        guard let player = player else { return }
        
        let layer = AVPlayerLayer(player: player)
        layer.frame = bounds
        layer.videoGravity = .resizeAspect
        layer.backgroundColor = UIColor.black.cgColor
        
        self.layer.addSublayer(layer)
        self.playerLayer = layer
    }
}
