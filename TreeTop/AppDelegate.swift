import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

// Add this to your main App struct
extension TreeTopApp {
    func makeAppDelegate() -> AppDelegate {
        return AppDelegate()
    }
}
