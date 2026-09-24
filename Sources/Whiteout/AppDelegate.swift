import Cocoa
import WhiteOutKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var displayManager: DisplayManager!
    private var updateChecker: UpdateChecker!
    private var statusBarController: StatusBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory app (menu bar only, no dock icon)
        NSApp.setActivationPolicy(.accessory)

        displayManager = DisplayManager()
        updateChecker = UpdateChecker()
        statusBarController = StatusBarController(displayManager: displayManager, updateChecker: updateChecker)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateCancel
    }
}
