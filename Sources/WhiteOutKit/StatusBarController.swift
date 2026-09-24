import AppKit
import SwiftUI
import Combine

/// StatusBarController manages the AppKit NSStatusItem and NSPopover
/// using a production-grade hybrid architecture (NSStatusItem + NSPopover + NSHostingController).
@MainActor
public final class StatusBarController: NSObject, NSPopoverDelegate {
    public let statusItem: NSStatusItem
    public let popover: NSPopover
    public let displayManager: DisplayManager
    public let updateChecker: UpdateChecker

    private var cancellables = Set<AnyCancellable>()

    public init(displayManager: DisplayManager, updateChecker: UpdateChecker) {
        self.displayManager = displayManager
        self.updateChecker = updateChecker

        // 1. Create NSStatusItem with variable length
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem.autosaveName = "WhiteOut"

        // 2. Create NSPopover
        self.popover = NSPopover()
        self.popover.behavior = .transient
        self.popover.animates = true
        self.popover.contentSize = NSSize(width: 320, height: 580)
        self.popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(displayManager)
                .environmentObject(updateChecker)
        )

        super.init()

        self.popover.delegate = self

        // 3. Configure Status Bar Button
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleStatusItemClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .semibold)
        }

        // 4. Reactive bindings to DisplayManager state
        setupObservers()

        // 5. Initial visual setup
        updateButton()
    }

    private func setupObservers() {
        displayManager.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateButton() }
            .store(in: &cancellables)

        displayManager.$reduction
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateButton() }
            .store(in: &cancellables)

        displayManager.$language
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateButton() }
            .store(in: &cancellables)
    }

    public func updateButton() {
        guard let button = statusItem.button else { return }
        let isEnabled = displayManager.isEnabled
        let reduction = displayManager.reduction

        let imageName = isEnabled ? "sun.min.fill" : "sun.min"
        button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: "Whiteout")
        button.imagePosition = .imageLeading

        if isEnabled && reduction > 0.01 {
            let pct = Int((reduction * 30).rounded())
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .semibold)
            button.title = " \(pct)%"
        } else {
            button.title = ""
        }
    }

    @objc private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            togglePopover(sender)
            return
        }

        let isRightClick = event.type == .rightMouseUp || event.type == .rightMouseDown
        let isControlClick = event.modifierFlags.contains(.control) && (event.type == .leftMouseUp || event.type == .leftMouseDown)

        if isRightClick || isControlClick {
            showContextMenu(sender)
        } else {
            togglePopover(sender)
        }
    }

    public func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            hidePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    public func showPopover(_ sender: NSStatusBarButton) {
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        NSApp.activate(ignoringOtherApps: true)
    }

    public func hidePopover(_ sender: Any? = nil) {
        popover.performClose(sender)
    }

    private func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        let lang = displayManager.appLanguage

        // 1. Quick On / Off toggle
        let toggleTitle = displayManager.isEnabled
            ? LocalizedStrings.turnOff(lang: lang)
            : LocalizedStrings.turnOn(lang: lang)
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleWhiteoutAction), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // 2. Open Settings Popover
        let openSettingsTitle = LocalizedStrings.openSettings(lang: lang)
        let settingsItem = NSMenuItem(title: openSettingsTitle, action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // 3. Quit
        let quitTitle = "\(LocalizedStrings.quitLabel(lang: lang)) Whiteout"
        let quitItem = NSMenuItem(title: quitTitle, action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        // Close popover if currently visible
        if popover.isShown {
            popover.performClose(nil)
        }

        // Present context menu cleanly without breaking future left-click actions
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: sender)
    }

    @objc private func toggleWhiteoutAction() {
        displayManager.isEnabled.toggle()
    }

    @objc private func openSettingsAction() {
        if let button = statusItem.button {
            showPopover(button)
        }
    }

    @objc private func quitAction() {
        displayManager.quit()
    }
}
