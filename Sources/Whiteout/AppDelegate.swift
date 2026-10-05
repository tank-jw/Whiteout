import Cocoa
import WhiteOutKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var displayManager: DisplayManager!
    private var updateChecker: UpdateChecker!
    private var statusBarController: StatusBarController!
    private var revealObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory app (menu bar only, no dock icon)
        NSApp.setActivationPolicy(.accessory)

        displayManager = DisplayManager()
        updateChecker = UpdateChecker()
        statusBarController = StatusBarController(displayManager: displayManager, updateChecker: updateChecker)

        // 다른 프로세스가 중복 실행을 시도할 때 기존 설정창을 띄우는 알림 수신
        revealObserver = AppInstanceGuard.shared.startListeningForRevealNotification { [weak self] in
            DispatchQueue.main.async {
                self?.statusBarController?.showPopover()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let obs = revealObserver {
            AppInstanceGuard.shared.stopListening(obs)
            revealObserver = nil
        }
        AppInstanceGuard.shared.releaseLock()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateNow
    }
}
