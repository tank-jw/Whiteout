import AppKit
import SwiftUI

/// WindowPositionStabilizer freezes the popover window's complete 2D position (X and Y coordinates)
/// while it is visible on screen. This prevents the window from jittering or shifting horizontally
/// or vertically when menu bar item contents change (e.g. when toggling On/Off and ratio numbers appear/disappear).
@MainActor
public final class WindowPositionStabilizer: NSObject {
    public static let shared = WindowPositionStabilizer()

    private var isSwizzled = false
    private weak var targetWindow: NSWindow?
    private var lockedOrigin: NSPoint?

    public func start() {
        guard !isSwizzled else { return }
        isSwizzled = true

        let windowClass: AnyClass = NSWindow.self

        if let origOrigin = class_getInstanceMethod(windowClass, #selector(NSWindow.setFrameOrigin(_:))),
           let swizOrigin = class_getInstanceMethod(windowClass, #selector(NSWindow.whiteout_setFrameOrigin(_:))) {
            method_exchangeImplementations(origOrigin, swizOrigin)
        }

        if let origFrame = class_getInstanceMethod(windowClass, #selector(NSWindow.setFrame(_:display:))),
           let swizFrame = class_getInstanceMethod(windowClass, #selector(NSWindow.whiteout_setFrame(_:display:))) {
            method_exchangeImplementations(origFrame, swizFrame)
        }

        if let origFrameAnim = class_getInstanceMethod(windowClass, #selector(NSWindow.setFrame(_:display:animate:))),
           let swizFrameAnim = class_getInstanceMethod(windowClass, #selector(NSWindow.whiteout_setFrame(_:display:animate:))) {
            method_exchangeImplementations(origFrameAnim, swizFrameAnim)
        }
    }

    public func attach(to window: NSWindow, yOffset: CGFloat = 0) {
        start()

        // If already locked for this exact window, avoid re-applying offset or overwriting origin
        if targetWindow === window, lockedOrigin != nil {
            return
        }

        self.targetWindow = window
        if window.frame.origin.x > 0 && window.frame.origin.y > 0 {
            var targetOrigin = window.frame.origin
            targetOrigin.y += yOffset
            self.lockedOrigin = targetOrigin
            if yOffset != 0 {
                window.setFrameOrigin(targetOrigin)
            }
        }

        NotificationCenter.default.removeObserver(self, name: NSWindow.didResignKeyNotification, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowClosed),
            name: NSWindow.didResignKeyNotification,
            object: window
        )

        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowClosed),
            name: NSWindow.willCloseNotification,
            object: window
        )

        NotificationCenter.default.removeObserver(self, name: NSWindow.didChangeScreenNotification, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowClosed),
            name: NSWindow.didChangeScreenNotification,
            object: window
        )
    }

    @objc private func handleWindowClosed() {
        lockedOrigin = nil
        targetWindow = nil
    }

    public func releaseLock() {
        lockedOrigin = nil
        targetWindow = nil
    }

    public func shouldLock(window: NSWindow, newOrigin: NSPoint) -> NSPoint {
        guard window === targetWindow else {
            return newOrigin
        }

        if let locked = lockedOrigin {
            return locked
        } else {
            return newOrigin
        }
    }
}

extension NSWindow {
    @objc func whiteout_setFrameOrigin(_ pt: NSPoint) {
        let finalOrigin = WindowPositionStabilizer.shared.shouldLock(window: self, newOrigin: pt)
        self.whiteout_setFrameOrigin(finalOrigin)
    }

    @objc func whiteout_setFrame(_ rect: NSRect, display: Bool) {
        var finalRect = rect
        let finalOrigin = WindowPositionStabilizer.shared.shouldLock(window: self, newOrigin: rect.origin)
        finalRect.origin = finalOrigin
        self.whiteout_setFrame(finalRect, display: display)
    }

    @objc func whiteout_setFrame(_ rect: NSRect, display: Bool, animate: Bool) {
        var finalRect = rect
        let finalOrigin = WindowPositionStabilizer.shared.shouldLock(window: self, newOrigin: rect.origin)
        finalRect.origin = finalOrigin
        self.whiteout_setFrame(finalRect, display: display, animate: animate)
    }
}
