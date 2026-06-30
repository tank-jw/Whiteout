import XCTest
import CoreGraphics
@testable import WhiteOutKit

final class MockDisplayService: DisplayServiceProtocol {
    var activeDisplays: [CGDirectDisplayID] = [1]
    var setDisplayTables: [CGDirectDisplayID: (capacity: UInt32, red: [CGGammaValue], green: [CGGammaValue], blue: [CGGammaValue])] = [:]
    var getDisplayTables: [CGDirectDisplayID: (red: [CGGammaValue], green: [CGGammaValue], blue: [CGGammaValue])] = [
        1: (
            red: Array(repeating: 0.0, count: 256),
            green: Array(repeating: 0.0, count: 256),
            blue: Array(repeating: 0.0, count: 256)
        )
    ]
    
    init() {
        for i in 0..<256 {
            let val = CGGammaValue(i) / 255.0
            getDisplayTables[1]!.red[i] = val
            getDisplayTables[1]!.green[i] = val
            getDisplayTables[1]!.blue[i] = val
        }
    }

    func getActiveDisplayList(_ maxDisplays: UInt32, _ activeDisplays: UnsafeMutablePointer<CGDirectDisplayID>?, _ displayCount: UnsafeMutablePointer<UInt32>?) -> CGError {
        if let displayCount = displayCount {
            displayCount.pointee = UInt32(self.activeDisplays.count)
        }
        if let activeDisplays = activeDisplays {
            for i in 0..<min(Int(maxDisplays), self.activeDisplays.count) {
                activeDisplays[i] = self.activeDisplays[i]
            }
        }
        return .success
    }
    
    func getDisplayTransferByTable(_ display: CGDirectDisplayID, _ capacity: UInt32, _ redTable: UnsafeMutablePointer<CGGammaValue>?, _ greenTable: UnsafeMutablePointer<CGGammaValue>?, _ blueTable: UnsafeMutablePointer<CGGammaValue>?, _ sampleCount: UnsafeMutablePointer<UInt32>?) -> CGError {
        if let sampleCount = sampleCount {
            sampleCount.pointee = 256
        }
        if let table = getDisplayTables[display] {
            if let r = redTable { r.initialize(from: table.red, count: 256) }
            if let g = greenTable { g.initialize(from: table.green, count: 256) }
            if let b = blueTable { b.initialize(from: table.blue, count: 256) }
        }
        return .success
    }
    
    func setDisplayTransferByTable(_ display: CGDirectDisplayID, _ capacity: UInt32, _ redTable: UnsafePointer<CGGammaValue>?, _ greenTable: UnsafePointer<CGGammaValue>?, _ blueTable: UnsafePointer<CGGammaValue>?) -> CGError {
        let rBuffer = redTable != nil ? Array(UnsafeBufferPointer(start: redTable, count: Int(capacity))) : []
        let gBuffer = greenTable != nil ? Array(UnsafeBufferPointer(start: greenTable, count: Int(capacity))) : []
        let bBuffer = blueTable != nil ? Array(UnsafeBufferPointer(start: blueTable, count: Int(capacity))) : []
        setDisplayTables[display] = (capacity: capacity, red: rBuffer, green: gBuffer, blue: bBuffer)
        return .success
    }
}

final class MockClockTimer: ClockTimer {
    var isInvalidated = false
    func invalidate() {
        isInvalidated = true
    }
}

final class MockClockService: ClockServiceProtocol {
    var mockedDate = Date()
    var scheduledTimerInterval: TimeInterval?
    var scheduledTimerBlock: (() -> Void)?
    
    func currentDate() -> Date {
        return mockedDate
    }
    
    func scheduleRepeatingTimer(interval: TimeInterval, block: @escaping () -> Void) -> ClockTimer {
        scheduledTimerInterval = interval
        scheduledTimerBlock = block
        return MockClockTimer()
    }
}

final class MockWorkspaceSubscription: WorkspaceSubscription {
    var isUnsubscribed = false
    func unsubscribe() {
        isUnsubscribed = true
    }
}

final class MockWorkspaceService: WorkspaceServiceProtocol {
    var appIcons: [String: NSImage] = [:]
    var activeAppHandler: ((String, String) -> Void)?
    
    func getAppIcon(bundleIdentifier: String) -> NSImage? {
        return appIcons[bundleIdentifier]
    }
    
    func observeActiveApplication(handler: @escaping (String, String) -> Void) -> WorkspaceSubscription {
        activeAppHandler = handler
        return MockWorkspaceSubscription()
    }
}

final class MockAppService: AppServiceProtocol {
    var isRegisteredForLaunchAtLogin: Bool = false
    
    func registerForLaunchAtLogin() throws {
        isRegisteredForLaunchAtLogin = true
    }
    
    func unregisterForLaunchAtLogin() throws {
        isRegisteredForLaunchAtLogin = false
    }
}

final class MockShortcutService: ShortcutServiceProtocol {
    var onTrigger: (() -> Void)?
    var registeredShortcut: KeyShortcut?
    
    func register(_ shortcut: KeyShortcut) {
        registeredShortcut = shortcut
    }
    
    func unregister() {
        registeredShortcut = nil
    }
}

final class DisplayManagerTests: XCTestCase {
    var displayService: MockDisplayService!
    var clockService: MockClockService!
    var workspaceService: MockWorkspaceService!
    var appService: MockAppService!
    var shortcutService: MockShortcutService!
    var dm: DisplayManager!
    
    override func setUp() {
        super.setUp()
        displayService = MockDisplayService()
        clockService = MockClockService()
        workspaceService = MockWorkspaceService()
        appService = MockAppService()
        shortcutService = MockShortcutService()
        
        let keys = [
            "whitePointReduction",
            "whitePointEnabled",
            "curveExponent",
            "isShortcutEnabled",
            "globalShortcut",
            "language",
            "launchAtLogin",
            "selectedDisplayID",
            "displaySettings",
            "appRules",
            "timeRules"
        ]
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        dm = DisplayManager(
            displayService: displayService,
            clockService: clockService,
            workspaceService: workspaceService,
            appService: appService,
            shortcutService: shortcutService
        )
    }
    
    override func tearDown() {
        dm = nil
        displayService = nil
        clockService = nil
        workspaceService = nil
        appService = nil
        shortcutService = nil
        super.tearDown()
    }
    
    func testInitializationAndDefaultState() {
        XCTAssertNotNil(dm)
        XCTAssertEqual(displayService.setDisplayTables.count, 0, "No tables should be set initially because it's disabled by default")
    }
    
    func testApplyReductionWhenEnabled() {
        dm.isEnabled = true
        dm.reduction = 0.1
        dm.applyReduction()
        
        XCTAssertEqual(displayService.setDisplayTables.count, 1)
        if let table = displayService.setDisplayTables[1] {
            XCTAssertLessThan(table.red.last!, 1.0)
            XCTAssertLessThan(table.green.last!, 1.0)
            XCTAssertLessThan(table.blue.last!, 1.0)
        }
    }
    
    func testAppRuleTriggersOnFocus() {
        let rule = AppRule(bundleIdentifier: "com.apple.Safari", appName: "Safari", reduction: 0.2, curveExponent: 4.0, isEnabled: true)
        dm.appRules = [rule]
        
        workspaceService.activeAppHandler?("com.apple.Safari", "Safari")
        
        XCTAssertEqual(dm.activeRuleAppName, "Safari")
        XCTAssertEqual(dm.reduction, 0.2)
        XCTAssertEqual(dm.isEnabled, true)
    }

    func testShortcutTriggerTogglesEnabledState() {
        dm.isEnabled = false
        dm.isShortcutEnabled = true
        
        shortcutService.onTrigger?()
        
        XCTAssertTrue(dm.isEnabled)
    }

    func testGammaAdjustmentsAndExponents() {
        // Verify at 0% reduction, applied table matches original (linear / unchanged)
        dm.isEnabled = true
        dm.reduction = 0.0
        dm.applyReduction()
        
        XCTAssertEqual(displayService.setDisplayTables[1]?.red.last, 1.0)
        XCTAssertEqual(displayService.setDisplayTables[1]?.red[128], 128.0 / 255.0)
        
        // Verify that at 10% reduction, maximum whitepoint value (index 255) is scaled down to 1.0 - 0.1 * 0.3 = 0.97 of original
        dm.reduction = 0.1
        dm.applyReduction()
        XCTAssertNotNil(displayService.setDisplayTables[1])
        if let table = displayService.setDisplayTables[1] {
            XCTAssertEqual(table.red.last!, 0.97, accuracy: 0.0001)
        }
        
        // Verify that at 30% reduction, maximum whitepoint value (index 255) is scaled down to 1.0 - 0.3 * 0.3 = 0.91 of original
        dm.reduction = 0.3
        dm.applyReduction()
        if let table = displayService.setDisplayTables[1] {
            XCTAssertEqual(table.red.last!, 0.91, accuracy: 0.0001)
        }
        
        // Verify for exponents 2.5, 4.0, and 6.0, intermediate values are computed exactly as defined by the formula
        let exponents = [2.5, 4.0, 6.0]
        let reduction = 0.3
        let maxOutput = 1.0 - reduction * 0.3
        let index = 128
        let t = Double(index) / 255.0
        
        for exp in exponents {
            dm.reduction = reduction
            dm.curveExponent = exp
            dm.applyReduction()
            
            if let table = displayService.setDisplayTables[1] {
                let sf = 1.0 - pow(t, exp) * (1.0 - maxOutput)
                let expectedValue = t * sf
                XCTAssertEqual(Double(table.red[index]), expectedValue, accuracy: 0.001)
            }
        }
    }

    func testAppSpecificAutomationFocusChange() {
        // Set up default user settings
        dm.selectedDisplayID = "all"
        dm.isEnabled = true
        dm.reduction = 0.1
        dm.curveExponent = 2.5
        
        // Verify default settings applied
        XCTAssertEqual(dm.reduction, 0.1)
        XCTAssertEqual(dm.curveExponent, 2.5)
        XCTAssertTrue(dm.isEnabled)
        
        // Set up app rule
        let rule = AppRule(bundleIdentifier: "com.apple.Safari", appName: "Safari", reduction: 0.2, curveExponent: 4.0, isEnabled: true)
        dm.appRules = [rule]
        
        // Simulate activating Safari
        workspaceService.activeAppHandler?("com.apple.Safari", "Safari")
        
        // Verify Safari rule settings are active on the manager
        XCTAssertEqual(dm.reduction, 0.2)
        XCTAssertEqual(dm.curveExponent, 4.0)
        XCTAssertTrue(dm.isEnabled)
        XCTAssertEqual(dm.activeRuleAppName, "Safari")
        
        // Simulate activating Finder (no rules)
        workspaceService.activeAppHandler?("com.apple.finder", "Finder")
        
        // Verify active app rule is cleared and restored to default user settings
        XCTAssertNil(dm.activeRuleAppName)
        XCTAssertEqual(dm.reduction, 0.1)
        XCTAssertEqual(dm.curveExponent, 2.5)
        XCTAssertTrue(dm.isEnabled)
    }

    private func createMockDate(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 30
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components)!
    }

    func testTimeBasedAutomationMidnightCrossing() {
        // Set up default user settings
        dm.selectedDisplayID = "all"
        dm.isEnabled = true
        dm.reduction = 0.1
        dm.curveExponent = 2.5
        
        // Add a time-based automation rule that crosses midnight
        let rule = TimeRule(startHour: 23, startMinute: 0, endHour: 6, endMinute: 0, reduction: 0.15, isEnabled: true)
        dm.timeRules = [rule]
        
        // 1. Set mock clock time to 22:59
        clockService.mockedDate = createMockDate(hour: 22, minute: 59)
        dm.evaluateTimeRules()
        // Verify rule is not active and reduction is user default
        XCTAssertNil(dm.activeTimeRuleId)
        XCTAssertEqual(dm.reduction, 0.1)
        
        // 2. Set mock clock time to 23:00
        clockService.mockedDate = createMockDate(hour: 23, minute: 00)
        dm.evaluateTimeRules()
        // Verify rule is active and reduction is 0.15
        XCTAssertEqual(dm.activeTimeRuleId, rule.id)
        XCTAssertEqual(dm.reduction, 0.15)
        
        // 3. Set mock clock time to 02:00
        clockService.mockedDate = createMockDate(hour: 2, minute: 0)
        dm.evaluateTimeRules()
        XCTAssertEqual(dm.activeTimeRuleId, rule.id)
        XCTAssertEqual(dm.reduction, 0.15)
        
        // 4. Set mock clock time to 05:59
        clockService.mockedDate = createMockDate(hour: 5, minute: 59)
        dm.evaluateTimeRules()
        XCTAssertEqual(dm.activeTimeRuleId, rule.id)
        XCTAssertEqual(dm.reduction, 0.15)
        
        // 5. Set mock clock time to 06:00
        clockService.mockedDate = createMockDate(hour: 6, minute: 0)
        dm.evaluateTimeRules()
        // Verify rule is not active and reduction is restored to default
        XCTAssertNil(dm.activeTimeRuleId)
        XCTAssertEqual(dm.reduction, 0.1)
    }

    func testDistortionRecoveryGuard() {
        // Create a fresh MockDisplayService with a distorted table
        let distortedService = MockDisplayService()
        var rDistorted = [CGGammaValue](repeating: 0, count: 256)
        var gDistorted = [CGGammaValue](repeating: 0, count: 256)
        var bDistorted = [CGGammaValue](repeating: 0, count: 256)
        for i in 0..<256 {
            let val = (CGGammaValue(i) / 255.0) * 0.85
            rDistorted[i] = val
            gDistorted[i] = val
            bDistorted[i] = val
        }
        distortedService.getDisplayTables[1] = (red: rDistorted, green: gDistorted, blue: bDistorted)
        
        // Initialize a new DisplayManager with the distorted service
        let testDM = DisplayManager(
            displayService: distortedService,
            clockService: clockService,
            workspaceService: workspaceService,
            appService: appService,
            shortcutService: shortcutService
        )
        
        // Apply reduction with 0% (or disable) to trigger restoration of the cached "original" table
        testDM.isEnabled = true
        testDM.reduction = 0.0
        testDM.applyReduction()
        
        // Verify that the restored table is linear (1.0 at index 255) rather than the distorted table (0.85 at index 255)
        XCTAssertNotNil(distortedService.setDisplayTables[1])
        if let table = distortedService.setDisplayTables[1] {
            XCTAssertEqual(table.red.last!, 1.0, accuracy: 0.0001)
            XCTAssertEqual(table.red[128], 128.0 / 255.0, accuracy: 0.0001)
        }
    }

    func testHotkeyRegistryStateToggling() {
        // Set shortcut, isShortcutEnabled = false initially
        dm.isShortcutEnabled = false
        dm.shortcut = KeyShortcut(keyCode: 49, carbonModifiers: 0) // Space with no modifiers
        shortcutService.registeredShortcut = nil // Reset mock registered shortcut

        // Test that when global shortcut is enabled, shortcutService.register is called
        dm.isShortcutEnabled = true
        XCTAssertEqual(shortcutService.registeredShortcut, dm.shortcut)

        // Test that calling shortcutService.onTrigger?() toggles isEnabled correctly (from true to false, and false to true)
        dm.isEnabled = true
        shortcutService.onTrigger?()
        XCTAssertFalse(dm.isEnabled)

        shortcutService.onTrigger?()
        XCTAssertTrue(dm.isEnabled)
        
        // Also verify that if isShortcutEnabled is false, onTrigger?() does not toggle isEnabled
        dm.isShortcutEnabled = false
        dm.isEnabled = true
        shortcutService.onTrigger?()
        XCTAssertTrue(dm.isEnabled) // remains true
    }
}
