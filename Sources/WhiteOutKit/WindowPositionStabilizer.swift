import AppKit
import SwiftUI

/// WindowPositionStabilizer freezes the popover window's horizontal position (X origin)
/// while it is visible on screen. This prevents the window from jittering or shifting left/right
/// when menu bar item contents change (e.g. when toggling On/Off and ratio numbers appear/disappear).
@MainActor
public final class WindowPositionStabilizer: NSObject {
    public static let shared = WindowPositionStabilizer()

    private var isSwizzled = false
    private weak var targetWindow: NSWindow?
    private var lockedX: CGFloat?

    public func start() {
        // Disabled global NSWindow swizzling to prevent NSSceneStatusItem dismissal by macOS ControlCenter
    }

    public func attach(to window: NSWindow) {
        start()
        self.targetWindow = window
        if window.isVisible && window.frame.origin.x > 0 {
            self.lockedX = window.frame.origin.x
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
        lockedX = nil
    }

    public func releaseLock() {
        lockedX = nil
    }

    public func shouldLock(window: NSWindow, newOrigin: NSPoint) -> NSPoint {
        guard window === targetWindow, window.isVisible else {
            return newOrigin
        }

        if let x = lockedX {
            return NSPoint(x: x, y: newOrigin.y)
        } else {
            lockedX = newOrigin.x
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
        finalRect.origin.x = finalOrigin.x
        self.whiteout_setFrame(finalRect, display: display)
    }

    @objc func whiteout_setFrame(_ rect: NSRect, display: Bool, animate: Bool) {
        var finalRect = rect
        let finalOrigin = WindowPositionStabilizer.shared.shouldLock(window: self, newOrigin: rect.origin)
        finalRect.origin.x = finalOrigin.x
        self.whiteout_setFrame(finalRect, display: display, animate: animate)
    }
}

public struct WindowPositionLock: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> PositionLockView {
        PositionLockView()
    }

    public func updateNSView(_ nsView: PositionLockView, context: Context) {
        if let window = nsView.window {
            WindowPositionStabilizer.shared.attach(to: window)
        }
    }
}

public final class PositionLockView: NSView {
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window = self.window {
            WindowPositionStabilizer.shared.attach(to: window)
        }
    }
}
