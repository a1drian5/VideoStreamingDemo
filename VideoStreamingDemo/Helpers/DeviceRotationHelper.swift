import SwiftUI
import UIKit

// Helper for managing device orientation
@available(iOS 15.0, *)
class DeviceRotationHelper {
    // Forces device to rotate to specified orientation
    static func forceRotation(to orientation: UIInterfaceOrientationMask) {
        let targetOrientation: UIInterfaceOrientation
        switch orientation {
        case .landscape, .landscapeLeft, .landscapeRight:
            targetOrientation = .landscapeRight
        case .portrait:
            targetOrientation = .portrait
        default:
            targetOrientation = .portrait
        }
        
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
            }
        } else {
            UIDevice.current.setValue(targetOrientation.rawValue, forKey: "orientation")
        }
        
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    static var currentOrientation: UIInterfaceOrientation {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.interfaceOrientation
        }
        return .portrait
    }
}

// App delegate for handling orientation changes
@available(iOS 15.0, *)
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

