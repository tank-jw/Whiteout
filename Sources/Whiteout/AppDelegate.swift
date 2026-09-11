import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    public static var isExplicitQuit = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the app from the Dock — menu bar only
        NSApp.setActivationPolicy(.accessory)
        ProcessInfo.processInfo.disableAutomaticTermination("WhiteOut running in menu bar")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if Self.isExplicitQuit {
            return .terminateNow
        }
        return .terminateCancel
    }
}
