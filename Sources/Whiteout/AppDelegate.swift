import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the app from the Dock — menu bar only
        NSApp.setActivationPolicy(.accessory)
    }
}
