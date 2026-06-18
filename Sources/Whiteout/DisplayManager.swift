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
struct DisplaySetting: Codable, Identifiable, Equatable {
    var id: String { String(displayID) }
    let displayID: CGDirectDisplayID
    let name: String
    var reduction: Double
    var curveExponent: Double
    var isEnabled: Bool
}

struct AppRule: Codable, Identifiable, Equatable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let appName: String
    var reduction: Double
    var curveExponent: Double
    var isEnabled: Bool
}

struct TimeRule: Codable, Identifiable, Equatable {
    var id = UUID()
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var reduction: Double
    var isEnabled: Bool

    // Computed properties for SwiftUI DatePicker binding mapping
    var startDate: Date {
        get {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = startHour
            components.minute = startMinute
            return calendar.date(from: components) ?? Date()
        }
        set {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: newValue)
            startHour = components.hour ?? 0
            startMinute = components.minute ?? 0
        }
    }

    var endDate: Date {
        get {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = endHour
            components.minute = endMinute
            return calendar.date(from: components) ?? Date()
        }
        set {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: newValue)
            endHour = components.hour ?? 0
            endMinute = components.minute ?? 0
        }
    }
}

class DisplayManager: ObservableObject {

    // MARK: - Published State

    @Published var reduction: Double {
        didSet {
            UserDefaults.standard.set(reduction, forKey: Keys.reduction)
            handleUserAdjustedReduction(reduction)
        }
    }

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled)
            handleUserAdjustedEnabled(isEnabled)
        }
    }

    @Published var curveExponent: Double {
        didSet {
            UserDefaults.standard.set(curveExponent, forKey: Keys.curveExponent)
            handleUserAdjustedExponent(curveExponent)
        }
    }

    @Published var isShortcutEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isShortcutEnabled, forKey: Keys.isShortcutEnabled)
            if isShortcutEnabled, let sc = shortcut {
                ShortcutManager.shared.register(sc)
            } else {
                ShortcutManager.shared.unregister()
            }
        }
    }

    @Published var shortcut: KeyShortcut? {
        didSet {
            if let sc = shortcut, let data = try? JSONEncoder().encode(sc) {
                UserDefaults.standard.set(data, forKey: Keys.shortcut)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.shortcut)
            }
            if isShortcutEnabled {
                if let sc = shortcut {
                    ShortcutManager.shared.register(sc)
                } else {
                    ShortcutManager.shared.unregister()
                }
            }
        }
    }

    @Published var language: String {
        didSet { UserDefaults.standard.set(language, forKey: Keys.language) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin)
            syncLaunchAtLogin()
        }
    }

    // picker selection: "all" or displayID string
    @Published var selectedDisplayID: String = "all" {
        didSet {
            UserDefaults.standard.set(selectedDisplayID, forKey: Keys.selectedDisplayID)
            syncSelectedDisplayToGlobalProperties()
        }
    }

    @Published var displaySettings: [String: DisplaySetting] = [:] {
        didSet {
            if let data = try? JSONEncoder().encode(displaySettings) {
                UserDefaults.standard.set(data, forKey: Keys.displaySettings)
            }
        }
    }

    @Published var appRules: [AppRule] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(appRules) {
                UserDefaults.standard.set(data, forKey: Keys.appRules)
            }
        }
    }

    @Published var activeRuleAppName: String? = nil

    @Published var timeRules: [TimeRule] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(timeRules) {
                UserDefaults.standard.set(data, forKey: Keys.timeRules)
            }
            evaluateTimeRules()
        }
    }

    @Published var activeTimeRuleId: UUID? = nil

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

    private var timeRuleTimer: Timer?

    private let tableSize = 256
    private var originalTables: [CGDirectDisplayID: GammaTable] = [:]
    private var isSyncingProperties = false

    var lastActiveAppBundleIdentifier: String?
    var lastActiveAppName: String?

    // MARK: - Init

    init() {
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
        ShortcutManager.shared.onTrigger = { [weak self] in
            guard let self = self, self.isShortcutEnabled else { return }
            self.setEnabled(!self.isEnabled)
        }
        if savedShortcutOn, let sc = savedShortcut {
            ShortcutManager.shared.register(sc)
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
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        // Evaluate time rules periodically
        evaluateTimeRules()
        timeRuleTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.evaluateTimeRules()
            }
        }
    }

    deinit {
        timeRuleTimer?.invalidate()
        restoreOriginalTables()
    }

    // MARK: - Public API

    /// Apply the current `reduction` value to active displays.
    func applyReduction() {
        // If an app rule is currently active, apply the active app rule's settings to all screens
        if let activeAppName = activeRuleAppName,
           let rule = appRules.first(where: { $0.appName == activeAppName }) {
            applyReductionForActiveRule(rule)
            return
        }

        // If a time rule is active, apply the active time rule's settings to all screens
        if let activeTimeId = activeTimeRuleId,
           let rule = timeRules.first(where: { $0.id == activeTimeId }) {
            applyReductionForActiveTimeRule(rule)
            return
        }

        // Otherwise, apply display-specific settings
        for (displayID, tables) in originalTables {
            let key = String(displayID)
            let setting = displaySettings[key] ?? DisplaySetting(displayID: displayID, name: getDisplayName(displayID), reduction: reduction, curveExponent: curveExponent, isEnabled: isEnabled)

            guard setting.isEnabled, setting.reduction > 0.001 else {
                // Restore this display only
                var r = tables.red
                var g = tables.green
                var b = tables.blue
                CGSetDisplayTransferByTable(displayID, UInt32(tableSize), &r, &g, &b)
                continue
            }

            let maxOutput = CGGammaValue(1.0 - setting.reduction * 0.3)
            let exp = CGGammaValue(setting.curveExponent)

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
            CGSetDisplayTransferByTable(displayID, UInt32(tableSize), &r, &g, &b)
        }
    }

    private func applyReductionForActiveRule(_ rule: AppRule) {
        for (displayID, tables) in originalTables {
            guard rule.isEnabled, rule.reduction > 0.001 else {
                var r = tables.red
                var g = tables.green
                var b = tables.blue
                CGSetDisplayTransferByTable(displayID, UInt32(tableSize), &r, &g, &b)
                continue
            }

            let maxOutput = CGGammaValue(1.0 - rule.reduction * 0.3)
            let exp = CGGammaValue(rule.curveExponent)

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
            CGSetDisplayTransferByTable(displayID, UInt32(tableSize), &r, &g, &b)
        }
    }

    private func applyReductionForActiveTimeRule(_ rule: TimeRule) {
        for (displayID, tables) in originalTables {
            guard isEnabled, rule.reduction > 0.001 else {
                var r = tables.red
                var g = tables.green
                var b = tables.blue
                CGSetDisplayTransferByTable(displayID, UInt32(tableSize), &r, &g, &b)
                continue
            }

            let maxOutput = CGGammaValue(1.0 - rule.reduction * 0.3)
            let exp = CGGammaValue(curveExponent) // Use standard curveExponent

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
            CGSetDisplayTransferByTable(displayID, UInt32(tableSize), &r, &g, &b)
        }
    }

    /// Toggle the effect on/off.
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        applyReduction()
    }

    /// Restore original tables and quit.
    func quit() {
        restoreOriginalTables()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Monitor/App Rule Management

    func getDisplayName(_ displayID: CGDirectDisplayID) -> String {
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
               screenNumber == displayID {
                return screen.localizedName
            }
        }
        return "외장 디스플레이 (\(displayID))"
    }

    func addAppRuleForLastActiveApp() {
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

    func deleteAppRule(at index: Int) {
        let rule = appRules[index]
        appRules.remove(at: index)

        if activeRuleAppName == rule.appName {
            activeRuleAppName = nil
            syncSelectedDisplayToGlobalProperties()
            applyReduction()
        }
    }

    func getAppIcon(bundleIdentifier: String) -> NSImage? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }

    func addTimeRule() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let endHour = (hour + 1) % 24
        
        let newRule = TimeRule(startHour: hour, startMinute: 0, endHour: endHour, endMinute: 0, reduction: 0.1, isEnabled: true)
        timeRules.append(newRule)
    }

    func deleteTimeRule(at index: Int) {
        let rule = timeRules[index]
        timeRules.remove(at: index)

        if activeTimeRuleId == rule.id {
            activeTimeRuleId = nil
            syncSelectedDisplayToGlobalProperties()
            applyReduction()
        }
    }

    func evaluateTimeRules() {
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
        let now = Date()
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
            applyReductionForActiveRule(appRules[index])
            return
        }

        if let activeTimeId = activeTimeRuleId,
           let index = timeRules.firstIndex(where: { $0.id == activeTimeId }) {
            timeRules[index].reduction = val
            applyReductionForActiveTimeRule(timeRules[index])
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
            applyReductionForActiveRule(appRules[index])
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
            applyReductionForActiveRule(appRules[index])
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

    @objc private func appDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { return }

        let myBundleID = Bundle.main.bundleIdentifier ?? "com.tankjw.whiteout"
        if bundleID == myBundleID {
            return
        }

        lastActiveAppBundleIdentifier = bundleID
        lastActiveAppName = app.localizedName

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
        CGGetActiveDisplayList(0, nil, &count)
        guard count > 0 else { return [] }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetActiveDisplayList(count, &ids, &count)
        return ids
    }

    /// 모든 활성 디스플레이의 원본 감마 테이블 저장
    private func saveOriginalTables() {
        for displayID in activeDisplayIDs() {
            var r = [CGGammaValue](repeating: 0, count: tableSize)
            var g = [CGGammaValue](repeating: 0, count: tableSize)
            var b = [CGGammaValue](repeating: 0, count: tableSize)
            var count: UInt32 = 0
            CGGetDisplayTransferByTable(displayID, UInt32(tableSize), &r, &g, &b, &count)
            originalTables[displayID] = (red: r, green: g, blue: b)
        }
    }

    /// 모든 디스플레이를 원본 감마로 복원
    private func restoreOriginalTables() {
        guard !originalTables.isEmpty else { return }
        for (displayID, tables) in originalTables {
            var r = tables.red
            var g = tables.green
            var b = tables.blue
            CGSetDisplayTransferByTable(displayID, UInt32(tableSize), &r, &g, &b)
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
            CGGetDisplayTransferByTable(id, UInt32(tableSize), &r, &g, &b, &count)
            originalTables[id] = (red: r, green: g, blue: b)

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
            if SMAppService.mainApp.status != .enabled {
                do {
                    try SMAppService.mainApp.register()
                } catch {
                    print("Failed to register SMAppService: \(error)")
                }
            }
        } else {
            if SMAppService.mainApp.status == .enabled {
                do {
                    try SMAppService.mainApp.unregister()
                } catch {
                    print("Failed to unregister SMAppService: \(error)")
                }
            }
        }
    }
}
