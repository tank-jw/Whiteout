import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the app from the Dock — menu bar only
        NSApp.setActivationPolicy(.accessory)

        // Ensure menu bar item is visible and positioned to the right of menu bar hiders (e.g. Hidden Bar)
        UserDefaults.standard.set(true, forKey: "NSStatusItem Visible Item-0")
        UserDefaults.standard.set(true, forKey: "NSStatusItem VisibleCC Item-0")
        if UserDefaults.standard.object(forKey: "NSStatusItem Preferred Position Item-0") == nil {
            UserDefaults.standard.set(250, forKey: "NSStatusItem Preferred Position Item-0")
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateCancel
    }
}
