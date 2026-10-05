import XCTest
@testable import WhiteOutKit
import AppKit

final class AppInstanceGuardTests: XCTestCase {

    func testAcquireSingleInstanceLockAndPreventDuplicate() {
        let tempLockPath = NSTemporaryDirectory() + "test_whiteout_\(UUID().uuidString).lock"
        defer {
            unlink(tempLockPath)
        }

        let guard1 = AppInstanceGuard(lockFilePath: tempLockPath)
        let guard2 = AppInstanceGuard(lockFilePath: tempLockPath)

        // First instance acquires the lock
        let acquired1 = guard1.acquireSingleInstanceLock(checkRunningApplications: false)
        XCTAssertTrue(acquired1, "First instance should successfully acquire the lock")
        XCTAssertTrue(guard1.isLockHeld)

        // Second instance attempts to acquire the same lock -> MUST fail
        let acquired2 = guard2.acquireSingleInstanceLock(checkRunningApplications: false)
        XCTAssertFalse(acquired2, "Second instance must be prevented from acquiring the same lock")
        XCTAssertFalse(guard2.isLockHeld)

        // First instance releases the lock
        guard1.releaseLock()
        XCTAssertFalse(guard1.isLockHeld)

        // Now the second instance can acquire it
        let acquired2AfterRelease = guard2.acquireSingleInstanceLock(checkRunningApplications: false)
        XCTAssertTrue(acquired2AfterRelease, "Second instance should acquire lock after first releases it")
        XCTAssertTrue(guard2.isLockHeld)

        guard2.releaseLock()
    }

    func testDistributedNotificationDelivery() {
        let guardInstance = AppInstanceGuard()
        let expectation = self.expectation(description: "Reveal notification received")

        let observer = guardInstance.startListeningForRevealNotification {
            expectation.fulfill()
        }

        guardInstance.notifyExistingInstanceToReveal()

        waitForExpectations(timeout: 2.0)
        guardInstance.stopListening(observer)
    }

    @MainActor
    func testStatusBarControllerShowPopoverMethod() {
        let displayService = MockDisplayService()
        let clockService = MockClockService()
        let workspaceService = MockWorkspaceService()
        let appService = MockAppService()
        let shortcutService = MockShortcutService()
        let systemEventService = MockSystemDisplayEventService()

        let dm = DisplayManager(
            displayService: displayService,
            clockService: clockService,
            workspaceService: workspaceService,
            appService: appService,
            shortcutService: shortcutService,
            systemEventService: systemEventService
        )
        let uc = UpdateChecker()
        let sbc = StatusBarController(displayManager: dm, updateChecker: uc)

        let testWindow = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 200, height: 100), styleMask: [.titled], backing: .buffered, defer: false)
        testWindow.orderFront(nil)

        if let button = sbc.statusItem.button {
            testWindow.contentView?.addSubview(button)
        }

        // Parameterless showPopover should display the popover
        sbc.showPopover()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        XCTAssertTrue(sbc.popover.isShown)

        // Calling showPopover again when already shown should keep it shown without crash
        sbc.showPopover()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        XCTAssertTrue(sbc.popover.isShown)

        if let button = sbc.statusItem.button {
            sbc.hidePopover(button)
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        }
        XCTAssertFalse(sbc.popover.isShown)
    }
}
