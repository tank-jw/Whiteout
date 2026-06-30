import Foundation
import CoreGraphics
import AppKit
import ServiceManagement

// MARK: - DisplayServiceProtocol
public protocol DisplayServiceProtocol {
    func getActiveDisplayList(_ maxDisplays: UInt32, _ activeDisplays: UnsafeMutablePointer<CGDirectDisplayID>?, _ displayCount: UnsafeMutablePointer<UInt32>?) -> CGError
    func getDisplayTransferByTable(_ display: CGDirectDisplayID, _ capacity: UInt32, _ redTable: UnsafeMutablePointer<CGGammaValue>?, _ greenTable: UnsafeMutablePointer<CGGammaValue>?, _ blueTable: UnsafeMutablePointer<CGGammaValue>?, _ sampleCount: UnsafeMutablePointer<UInt32>?) -> CGError
    func setDisplayTransferByTable(_ display: CGDirectDisplayID, _ capacity: UInt32, _ redTable: UnsafePointer<CGGammaValue>?, _ greenTable: UnsafePointer<CGGammaValue>?, _ blueTable: UnsafePointer<CGGammaValue>?) -> CGError
}

public struct LiveDisplayService: DisplayServiceProtocol {
    public init() {}
    
    public func getActiveDisplayList(_ maxDisplays: UInt32, _ activeDisplays: UnsafeMutablePointer<CGDirectDisplayID>?, _ displayCount: UnsafeMutablePointer<UInt32>?) -> CGError {
        return CGGetActiveDisplayList(maxDisplays, activeDisplays, displayCount)
    }
    
    public func getDisplayTransferByTable(_ display: CGDirectDisplayID, _ capacity: UInt32, _ redTable: UnsafeMutablePointer<CGGammaValue>?, _ greenTable: UnsafeMutablePointer<CGGammaValue>?, _ blueTable: UnsafeMutablePointer<CGGammaValue>?, _ sampleCount: UnsafeMutablePointer<UInt32>?) -> CGError {
        return CGGetDisplayTransferByTable(display, capacity, redTable, greenTable, blueTable, sampleCount)
    }
    
    public func setDisplayTransferByTable(_ display: CGDirectDisplayID, _ capacity: UInt32, _ redTable: UnsafePointer<CGGammaValue>?, _ greenTable: UnsafePointer<CGGammaValue>?, _ blueTable: UnsafePointer<CGGammaValue>?) -> CGError {
        return CGSetDisplayTransferByTable(display, capacity, redTable, greenTable, blueTable)
    }
}

// MARK: - ClockServiceProtocol
public protocol ClockTimer {
    func invalidate()
}

public protocol ClockServiceProtocol {
    func currentDate() -> Date
    func scheduleRepeatingTimer(interval: TimeInterval, block: @escaping () -> Void) -> ClockTimer
}

public struct LiveClockService: ClockServiceProtocol {
    public init() {}
    
    public func currentDate() -> Date {
        return Date()
    }
    
    public func scheduleRepeatingTimer(interval: TimeInterval, block: @escaping () -> Void) -> ClockTimer {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            block()
        }
        return LiveClockTimer(timer: timer)
    }
}

private final class LiveClockTimer: ClockTimer {
    private let timer: Timer
    init(timer: Timer) {
        self.timer = timer
    }
    func invalidate() {
        timer.invalidate()
    }
}

// MARK: - WorkspaceServiceProtocol
public protocol WorkspaceSubscription {
    func unsubscribe()
}

public protocol WorkspaceServiceProtocol {
    func getAppIcon(bundleIdentifier: String) -> NSImage?
    func observeActiveApplication(handler: @escaping (String, String) -> Void) -> WorkspaceSubscription
}

public final class LiveWorkspaceService: WorkspaceServiceProtocol {
    public init() {}
    
    public func getAppIcon(bundleIdentifier: String) -> NSImage? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }
    
    public func observeActiveApplication(handler: @escaping (String, String) -> Void) -> WorkspaceSubscription {
        let observer = WorkspaceObserver(handler: handler)
        observer.start()
        return observer
    }
}

private final class WorkspaceObserver: WorkspaceSubscription {
    private let handler: (String, String) -> Void
    private var observerObject: NSObjectProtocol?
    
    init(handler: @escaping (String, String) -> Void) {
        self.handler = handler
    }
    
    func start() {
        observerObject = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleID = app.bundleIdentifier,
                  let appName = app.localizedName else { return }
            
            let myBundleID = Bundle.main.bundleIdentifier ?? "com.tankjw.whiteout"
            if bundleID == myBundleID {
                return
            }
            self.handler(bundleID, appName)
        }
    }
    
    func unsubscribe() {
        if let obs = observerObject {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            observerObject = nil
        }
    }
    
    deinit {
        unsubscribe()
    }
}

// MARK: - AppServiceProtocol
public protocol AppServiceProtocol {
    var isRegisteredForLaunchAtLogin: Bool { get }
    func registerForLaunchAtLogin() throws
    func unregisterForLaunchAtLogin() throws
}

public struct LiveAppService: AppServiceProtocol {
    public init() {}
    
    public var isRegisteredForLaunchAtLogin: Bool {
        return SMAppService.mainApp.status == .enabled
    }
    
    public func registerForLaunchAtLogin() throws {
        try SMAppService.mainApp.register()
    }
    
    public func unregisterForLaunchAtLogin() throws {
        try SMAppService.mainApp.unregister()
    }
}

// MARK: - ShortcutServiceProtocol
public protocol ShortcutServiceProtocol: AnyObject {
    var onTrigger: (() -> Void)? { get set }
    func register(_ shortcut: KeyShortcut)
    func unregister()
}

public final class LiveShortcutService: ShortcutServiceProtocol {
    public init() {}
    
    public var onTrigger: (() -> Void)? {
        get { ShortcutManager.shared.onTrigger }
        set { ShortcutManager.shared.onTrigger = newValue }
    }
    
    public func register(_ shortcut: KeyShortcut) {
        ShortcutManager.shared.register(shortcut)
    }
    
    public func unregister() {
        ShortcutManager.shared.unregister()
    }
}
