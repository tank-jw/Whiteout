import Cocoa
import CoreGraphics
import Foundation
import Combine
import ServiceManagement

/// 디스플레이 한 개의 원본 감마 테이블
private typealias GammaTable = (red: [CGGammaValue], green: [CGGammaValue], blue: [CGGammaValue])

/// Manages the display's gamma transfer table to reduce white point intensity.
///
/// This replicates iPad's "Reduce White Point" feature at the GPU/driver level:
///   - Black (0) stays 0 — contrast is preserved
///   - White (1.0) is scaled down to `1.0 - reduction * 0.3`  (max 30% reduction)
///   - Applies to ALL active displays (multi-monitor support)
///   - Responds to display connect/disconnect at runtime
///   - The original gamma table is saved on init and restored on quit / reset
public class DisplayManager: ObservableObject {

    // MARK: - Published State

    @Published public var reduction: Double {
        didSet {
            if !isSyncingProperties {
                UserDefaults.standard.set(reduction, forKey: Keys.reduction)
            }
            handleUserAdjustedReduction(reduction)
        }
    }

    @Published public var isEnabled: Bool {
        didSet {
            if !isSyncingProperties {
                UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled)
            }
            handleUserAdjustedEnabled(isEnabled)
        }
    }

    @Published public var curveExponent: Double {
        didSet {
            if !isSyncingProperties {
                UserDefaults.standard.set(curveExponent, forKey: Keys.curveExponent)
            }
            handleUserAdjustedExponent(curveExponent)
        }
    }

    @Published public var isShortcutEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isShortcutEnabled, forKey: Keys.isShortcutEnabled)
            if isShortcutEnabled, let sc = shortcut {
                shortcutService.register(sc)
            } else {
                shortcutService.unregister()
            }
        }
    }

    @Published public var shortcut: KeyShortcut? {
        didSet {
            if let sc = shortcut, let data = try? JSONEncoder().encode(sc) {
                UserDefaults.standard.set(data, forKey: Keys.shortcut)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.shortcut)
            }
            if isShortcutEnabled {
                if let sc = shortcut {
                    shortcutService.register(sc)
                } else {
                    shortcutService.unregister()
                }
            }
        }
    }

    @Published public var language: String {
        didSet { UserDefaults.standard.set(language, forKey: Keys.language) }
    }

    @Published public var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
            syncLaunchAtLogin()
        }
    }

    // picker selection: "all" or displayID string
    @Published public var selectedDisplayID: String = "all" {
        didSet {
            UserDefaults.standard.set(selectedDisplayID, forKey: Keys.selectedDisplayID)
            syncSelectedDisplayToGlobalProperties()
        }
    }

    @Published public var displaySettings: [String: DisplaySetting] = [:] {
        didSet {
            if let data = try? JSONEncoder().encode(displaySettings) {
                UserDefaults.standard.set(data, forKey: Keys.displaySettings)
            }
        }
    }

    @Published public var appRules: [AppRule] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(appRules) {
                UserDefaults.standard.set(data, forKey: Keys.appRules)
            }
            // Update cached active app rule if current application matches
            updateActiveAppRuleCachedPointer()
        }
    }

    @Published public var activeRuleAppName: String? = nil {
        didSet {
            updateActiveAppRuleCachedPointer()
        }
    }

    @Published public var timeRules: [TimeRule] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(timeRules) {
                UserDefaults.standard.set(data, forKey: Keys.timeRules)
            }
            evaluateTimeRules()
        }
    }

    @Published public var activeTimeRuleId: UUID? = nil {
        didSet {
            updateActiveTimeRuleCachedPointer()
        }
    }

    // MARK: - Cached Rule Pointers (O(1) Access)
    private var activeAppRule: AppRule? = nil
    private var activeTimeRule: TimeRule? = nil

    // MARK: - Services (Dependency Injection)
    private let displayService: DisplayServiceProtocol
    private let clockService: ClockServiceProtocol
    private let workspaceService: WorkspaceServiceProtocol
    private let appService: AppServiceProtocol
    private let shortcutService: ShortcutServiceProtocol
    private var workspaceSubscription: WorkspaceSubscription?

    // MARK: - Private / App-tracking properties

    private enum Keys {
        static let reduction         = "whitePointReduction"
        static let isEnabled         = "whitePointEnabled"
        static let curveExponent     = "curveExponent"
        static let isShortcutEnabled = "isShortcutEnabled"
        static let shortcut          = "globalShortcut"
        static let language          = "language"
        static let launchAtLogin     = "launchAtLogin"
        static let selectedDisplayID = "selectedDisplayID"
        static let displaySettings   = "displaySettings"
        static let appRules          = "appRules"
        static let timeRules         = "timeRules"
    }

    private var timeRuleTimer: ClockTimer?

    private let tableSize = 256
    private var originalTables: [CGDirectDisplayID: GammaTable] = [:]
    private var isSyncingProperties = false

    public var lastActiveAppBundleIdentifier: String?
    public var lastActiveAppName: String?

    // MARK: - Init

    public init(
        displayService: DisplayServiceProtocol = LiveDisplayService(),
        clockService: ClockServiceProtocol = LiveClockService(),
        workspaceService: WorkspaceServiceProtocol = LiveWorkspaceService(),
        appService: AppServiceProtocol = LiveAppService(),
        shortcutService: ShortcutServiceProtocol = LiveShortcutService()
    ) {
        self.displayService = displayService
        self.clockService = clockService
        self.workspaceService = workspaceService
        self.appService = appService
        self.shortcutService = shortcutService

        let savedReduction    = UserDefaults.standard.double(forKey: Keys.reduction)
        let savedEnabled      = UserDefaults.standard.bool(forKey: Keys.isEnabled)
        let savedExponent     = UserDefaults.standard.object(forKey: Keys.curveExponent) as? Double ?? 4.0
        let savedShortcutOn   = UserDefaults.standard.object(forKey: Keys.isShortcutEnabled) as? Bool ?? true
        let savedLanguage     = UserDefaults.standard.string(forKey: Keys.language) ?? "ko"
        let savedLaunch       = UserDefaults.standard.bool(forKey: Keys.launchAtLogin)
        let savedShortcutData = UserDefaults.standard.data(forKey: Keys.shortcut)
        let savedShortcut     = savedShortcutData.flatMap { try? JSONDecoder().decode(KeyShortcut.self, from: $0) }

        let savedSelectedDisplay = UserDefaults.standard.string(forKey: Keys.selectedDisplayID) ?? "all"

        var loadedDisplaySettings: [String: DisplaySetting] = [:]
        if let data = UserDefaults.standard.data(forKey: Keys.displaySettings),
           let decoded = try? JSONDecoder().decode([String: DisplaySetting].self, from: data) {
            loadedDisplaySettings = decoded
        }

        var loadedAppRules: [AppRule] = []
        if let data = UserDefaults.standard.data(forKey: Keys.appRules),
           let decoded = try? JSONDecoder().decode([AppRule].self, from: data) {
            loadedAppRules = decoded
        }

        var loadedTimeRules: [TimeRule] = []
        if let data = UserDefaults.standard.data(forKey: Keys.timeRules),
           let decoded = try? JSONDecoder().decode([TimeRule].self, from: data) {
            loadedTimeRules = decoded
        }

        self.reduction         = savedReduction
        self.isEnabled         = savedEnabled
        self.curveExponent     = savedExponent
        self.isShortcutEnabled = savedShortcutOn
        self.language          = savedLanguage
        self.launchAtLogin     = savedLaunch
        self.shortcut          = savedShortcut

        self.selectedDisplayID = savedSelectedDisplay
        self.displaySettings   = loadedDisplaySettings
        self.appRules          = loadedAppRules
        self.timeRules         = loadedTimeRules

        updateActiveAppRuleCachedPointer()
        updateActiveTimeRuleCachedPointer()

        // Must happen after properties initialization
        saveOriginalTables()
        syncLaunchAtLogin()

        // Initialize settings for active displays
        for displayID in activeDisplayIDs() {
            let key = String(displayID)
            if displaySettings[key] == nil {
                displaySettings[key] = DisplaySetting(displayID: displayID, name: getDisplayName(displayID), reduction: savedReduction, curveExponent: savedExponent, isEnabled: savedEnabled)
            }
        }

        // Re-apply saved setting on launch
        if savedEnabled && savedReduction > 0 {
            applyReduction()
        }

        // 글로벌 단축키 설정 (Carbon ShortcutManager)
        self.shortcutService.onTrigger = { [weak self] in
            guard let self = self, self.isShortcutEnabled else { return }
            self.setEnabled(!self.isEnabled)
        }
        if savedShortcutOn, let sc = savedShortcut {
            self.shortcutService.register(sc)
        }

        // 앱 종료 시 원본 감마 복원
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.restoreOriginalTables()
        }

        // 모니터 연결/해제 시 디스플레이 구성 갱신
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshDisplayConfiguration()
        }

        // Observe application focus change
        self.workspaceSubscription = workspaceService.observeActiveApplication { [weak self] bundleID, appName in
            self?.appDidActivate(bundleID: bundleID, appName: appName)
        }

        // Evaluate time rules periodically
        evaluateTimeRules()
        timeRuleTimer = clockService.scheduleRepeatingTimer(interval: 30) { [weak self] in
            self?.evaluateTimeRules()
        }
    }

    deinit {
        timeRuleTimer?.invalidate()
        workspaceSubscription?.unsubscribe()
        restoreOriginalTables()
    }

    // MARK: - Public API

    /// Apply the current `reduction` value to active displays.
    public func applyReduction() {
        let currentActiveAppRule = activeAppRule
        let currentActiveTimeRule = activeTimeRule

        for (displayID, tables) in originalTables {
            let targetReduction: Double
            let targetExponent: Double
            let targetEnabled: Bool

            if let appRule = currentActiveAppRule {
                targetReduction = appRule.reduction
                targetExponent = appRule.curveExponent
                targetEnabled = appRule.isEnabled
            } else if let timeRule = currentActiveTimeRule {
                targetReduction = timeRule.reduction
                targetExponent = curveExponent
                targetEnabled = isEnabled
            } else {
                let key = String(displayID)
                let setting = displaySettings[key] ?? DisplaySetting(displayID: displayID, name: getDisplayName(displayID), reduction: reduction, curveExponent: curveExponent, isEnabled: isEnabled)
                targetReduction = setting.reduction
                targetExponent = setting.curveExponent
                targetEnabled = setting.isEnabled
            }

            guard targetEnabled, targetReduction > 0.001 else {
                // Restore original tables for this display
                var r = tables.red
                var g = tables.green
                var b = tables.blue
                _ = displayService.setDisplayTransferByTable(displayID, UInt32(tableSize), &r, &g, &b)
                continue
            }

            let maxOutput = CGGammaValue(1.0 - targetReduction * 0.3)
            let exp = CGGammaValue(targetExponent)

            var r = [CGGammaValue](repeating: 0, count: tableSize)
            var g = [CGGammaValue](repeating: 0, count: tableSize)
            var b = [CGGammaValue](repeating: 0, count: tableSize)

            for i in 0..<tableSize {
                let t = CGGammaValue(i) / CGGammaValue(tableSize - 1)
                let sf = 1.0 - pow(t, exp) * (1.0 - maxOutput)
                r[i] = tables.red[i]   * sf
                g[i] = tables.green[i] * sf
                b[i] = tables.blue[i]  * sf
            }
            _ = displayService.setDisplayTransferByTable(displayID, UInt32(tableSize), &r, &g, &b)
        }
    }

    /// Toggle the effect on/off.
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        applyReduction()
    }

    /// Restore original tables and quit.
    public func quit() {
        restoreOriginalTables()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Monitor/App Rule Management

    public func getDisplayName(_ displayID: CGDirectDisplayID) -> String {
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
               screenNumber == displayID {
                return screen.localizedName
            }
        }
        return "외장 디스플레이 (\(displayID))"
    }

    public func addAppRuleForLastActiveApp() {
        guard let bundleID = lastActiveAppBundleIdentifier,
              let name = lastActiveAppName else { return }

        if appRules.contains(where: { $0.bundleIdentifier == bundleID }) {
            return
        }

        let rule = AppRule(bundleIdentifier: bundleID, appName: name, reduction: reduction, curveExponent: curveExponent, isEnabled: isEnabled)
        appRules.append(rule)

        activeRuleAppName = name
        applyReduction()
    }

    public func deleteAppRule(at index: Int) {
        let rule = appRules[index]
        appRules.remove(at: index)

        if activeRuleAppName == rule.appName {
            activeRuleAppName = nil
            syncSelectedDisplayToGlobalProperties()
            applyReduction()
        }
    }

    public func getAppIcon(bundleIdentifier: String) -> NSImage? {
        return workspaceService.getAppIcon(bundleIdentifier: bundleIdentifier)
    }

    public func addTimeRule() {
        let calendar = Calendar.current
        let now = clockService.currentDate()
        let hour = calendar.component(.hour, from: now)
        let endHour = (hour + 1) % 24
        
        let newRule = TimeRule(startHour: hour, startMinute: 0, endHour: endHour, endMinute: 0, reduction: 0.1, isEnabled: true)
        timeRules.append(newRule)
    }

    public func deleteTimeRule(at index: Int) {
        let rule = timeRules[index]
        timeRules.remove(at: index)

        if activeTimeRuleId == rule.id {
            activeTimeRuleId = nil
            syncSelectedDisplayToGlobalProperties()
            applyReduction()
        }
    }

    public func evaluateTimeRules() {
        guard isEnabled else {
            if activeTimeRuleId != nil {
                activeTimeRuleId = nil
            }
            return
        }

        // App rule has precedence. If app rule is active, we don't apply time rules.
        if activeRuleAppName != nil {
            return
        }

        let calendar = Calendar.current
        let now = clockService.currentDate()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentMinutes = currentHour * 60 + currentMinute

        var matchedRule: TimeRule? = nil
        for rule in timeRules {
            guard rule.isEnabled else { continue }
            let start = rule.startHour * 60 + rule.startMinute
            let end = rule.endHour * 60 + rule.endMinute

            let isActive: Bool
            if start <= end {
                isActive = (currentMinutes >= start && currentMinutes < end)
            } else {
                // Crosses midnight
                isActive = (currentMinutes >= start || currentMinutes < end)
            }

            if isActive {
                matchedRule = rule
                break
            }
        }

        if let rule = matchedRule {
            if activeTimeRuleId != rule.id {
                activeTimeRuleId = rule.id
                
                isSyncingProperties = true
                self.reduction = rule.reduction
                isSyncingProperties = false
                
                applyReduction()
            }
        } else {
            if activeTimeRuleId != nil {
                activeTimeRuleId = nil
                syncSelectedDisplayToGlobalProperties()
                applyReduction()
            }
        }
    }

    // MARK: - Private Helpers

    private func handleUserAdjustedReduction(_ val: Double) {
        guard !isSyncingProperties else { return }

        if let activeAppName = activeRuleAppName,
           let index = appRules.firstIndex(where: { $0.appName == activeAppName }) {
            appRules[index].reduction = val
            applyReduction()
            return
        }

        if let activeTimeId = activeTimeRuleId,
           let index = timeRules.firstIndex(where: { $0.id == activeTimeId }) {
            timeRules[index].reduction = val
            applyReduction()
            return
        }

        if selectedDisplayID == "all" {
            for key in displaySettings.keys {
                displaySettings[key]?.reduction = val
            }
        } else {
            displaySettings[selectedDisplayID]?.reduction = val
        }
        applyReduction()
    }

    private func handleUserAdjustedExponent(_ val: Double) {
        guard !isSyncingProperties else { return }

        if let activeAppName = activeRuleAppName,
           let index = appRules.firstIndex(where: { $0.appName == activeAppName }) {
            appRules[index].curveExponent = val
            applyReduction()
            return
        }

        if selectedDisplayID == "all" {
            for key in displaySettings.keys {
                displaySettings[key]?.curveExponent = val
            }
        } else {
            displaySettings[selectedDisplayID]?.curveExponent = val
        }
        applyReduction()
    }

    private func handleUserAdjustedEnabled(_ val: Bool) {
        guard !isSyncingProperties else { return }

        if let activeAppName = activeRuleAppName,
           let index = appRules.firstIndex(where: { $0.appName == activeAppName }) {
            appRules[index].isEnabled = val
            applyReduction()
            return
        }

        if selectedDisplayID == "all" {
            for key in displaySettings.keys {
                displaySettings[key]?.isEnabled = val
            }
        } else {
            displaySettings[selectedDisplayID]?.isEnabled = val
        }
        applyReduction()
    }

    private func syncSelectedDisplayToGlobalProperties() {
        isSyncingProperties = true
        defer { isSyncingProperties = false }

        if selectedDisplayID == "all" {
            let savedReduction = UserDefaults.standard.double(forKey: Keys.reduction)
            let savedEnabled   = UserDefaults.standard.bool(forKey: Keys.isEnabled)
            let savedExponent  = UserDefaults.standard.object(forKey: Keys.curveExponent) as? Double ?? 4.0

            self.reduction = savedReduction
            self.isEnabled = savedEnabled
            self.curveExponent = savedExponent
        } else if let setting = displaySettings[selectedDisplayID] {
            self.reduction = setting.reduction
            self.isEnabled = setting.isEnabled
            self.curveExponent = setting.curveExponent
        }
    }

    private func appDidActivate(bundleID: String, appName: String) {
        lastActiveAppBundleIdentifier = bundleID
        lastActiveAppName = appName

        if let rule = appRules.first(where: { $0.bundleIdentifier == bundleID }) {
            activeRuleAppName = rule.appName

            isSyncingProperties = true
            self.reduction = rule.reduction
            self.curveExponent = rule.curveExponent
            self.isEnabled = rule.isEnabled
            isSyncingProperties = false

            applyReduction()
        } else {
            if activeRuleAppName != nil {
                activeRuleAppName = nil
                syncSelectedDisplayToGlobalProperties()
                applyReduction()
            }
        }
    }

    /// 현재 연결된 모든 활성 디스플레이 ID 반환
    private func activeDisplayIDs() -> [CGDirectDisplayID] {
        var count: UInt32 = 0
        _ = displayService.getActiveDisplayList(0, nil, &count)
        guard count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        _ = displayService.getActiveDisplayList(count, &ids, &count)
        return ids
    }

    /// 모든 활성 디스플레이의 원본 감마 테이블 저장 (왜곡 방지 가드 포함)
    private func saveOriginalTables() {
        for displayID in activeDisplayIDs() {
            var r = [CGGammaValue](repeating: 0, count: tableSize)
            var g = [CGGammaValue](repeating: 0, count: tableSize)
            var b = [CGGammaValue](repeating: 0, count: tableSize)
            var count: UInt32 = 0
            _ = displayService.getDisplayTransferByTable(displayID, UInt32(tableSize), &r, &g, &b, &count)

            if isTableDistorted(red: r, green: g, blue: b) {
                print("⚠️ Warning: Display \(displayID) gamma is already distorted. Initializing with Linear Table.")
                originalTables[displayID] = generateLinearTable()
            } else {
                originalTables[displayID] = (red: r, green: g, blue: b)
            }
        }
    }

    /// 모든 디스플레이를 원본 감마로 복원
    private func restoreOriginalTables() {
        guard !originalTables.isEmpty else { return }
        for (displayID, tables) in originalTables {
            var r = tables.red
            var g = tables.green
            var b = tables.blue
            _ = displayService.setDisplayTransferByTable(displayID, UInt32(tableSize), &r, &g, &b)
        }
    }

    /// 모니터 연결/해제 시 호출 — 새 디스플레이 추가, 제거된 디스플레이 정리
    private func refreshDisplayConfiguration() {
        let currentIDs = Set(activeDisplayIDs())
        let knownIDs   = Set(originalTables.keys)

        // 새로 연결된 모니터: 원본 테이블 저장 후 즉시 감소 적용
        for id in currentIDs.subtracting(knownIDs) {
            var r = [CGGammaValue](repeating: 0, count: tableSize)
            var g = [CGGammaValue](repeating: 0, count: tableSize)
            var b = [CGGammaValue](repeating: 0, count: tableSize)
            var count: UInt32 = 0
            _ = displayService.getDisplayTransferByTable(id, UInt32(tableSize), &r, &g, &b, &count)

            if isTableDistorted(red: r, green: g, blue: b) {
                print("⚠️ Warning: Newly connected Display \(id) gamma is distorted. Initializing with Linear Table.")
                originalTables[id] = generateLinearTable()
            } else {
                originalTables[id] = (red: r, green: g, blue: b)
            }

            let key = String(id)
            if displaySettings[key] == nil {
                displaySettings[key] = DisplaySetting(displayID: id, name: getDisplayName(id), reduction: reduction, curveExponent: curveExponent, isEnabled: isEnabled)
            }
        }

        // 연결 해제된 모니터: 테이블 제거
        for id in knownIDs.subtracting(currentIDs) {
            originalTables.removeValue(forKey: id)
        }

        applyReduction()
    }

    /// 로그인 시 자동 실행 등록/해제 동기화
    private func syncLaunchAtLogin() {
        if launchAtLogin {
            if !appService.isRegisteredForLaunchAtLogin {
                do {
                    try appService.registerForLaunchAtLogin()
                } catch {
                    print("Failed to register SMAppService: \(error)")
                }
            }
        } else {
            if appService.isRegisteredForLaunchAtLogin {
                do {
                    try appService.unregisterForLaunchAtLogin()
                } catch {
                    print("Failed to unregister SMAppService: \(error)")
                }
            }
        }
    }

    // MARK: - Private Refactoring Helpers

    private func updateActiveAppRuleCachedPointer() {
        if let activeAppName = activeRuleAppName {
            activeAppRule = appRules.first(where: { $0.appName == activeAppName })
        } else {
            activeAppRule = nil
        }
    }

    private func updateActiveTimeRuleCachedPointer() {
        if let activeTimeId = activeTimeRuleId {
            activeTimeRule = timeRules.first(where: { $0.id == activeTimeId })
        } else {
            activeTimeRule = nil
        }
    }

    private func isTableDistorted(red: [CGGammaValue], green: [CGGammaValue], blue: [CGGammaValue]) -> Bool {
        guard red.count == tableSize, green.count == tableSize, blue.count == tableSize else { return true }
        let rLast = red[tableSize - 1]
        let gLast = green[tableSize - 1]
        let bLast = blue[tableSize - 1]
        
        // 마지막 화이트포인트 값이 0.9 미만으로 감소되어 있으면 이미 조절된 왜곡 상태로 판단
        return rLast < 0.9 || gLast < 0.9 || bLast < 0.9
    }

    private func generateLinearTable() -> GammaTable {
        var r = [CGGammaValue](repeating: 0, count: tableSize)
        var g = [CGGammaValue](repeating: 0, count: tableSize)
        var b = [CGGammaValue](repeating: 0, count: tableSize)
        for i in 0..<tableSize {
            let val = CGGammaValue(i) / CGGammaValue(tableSize - 1)
            r[i] = val
            g[i] = val
            b[i] = val
        }
        return (red: r, green: g, blue: b)
    }
}
