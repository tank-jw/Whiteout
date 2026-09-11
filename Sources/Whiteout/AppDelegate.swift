import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the app from the Dock — menu bar only
        NSApp.setActivationPolicy(.accessory)
        UserDefaults.standard.removeObject(forKey: "NSStatusItem VisibleCC Item-0")
        UserDefaults.standard.set(true, forKey: "NSStatusItem Visible Item-0")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
