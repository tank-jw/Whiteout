import Cocoa
import CoreGraphics
import Foundation
import Combine

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
class DisplayManager: ObservableObject {

    // MARK: - Published State

    @Published var reduction: Double {
        didSet { UserDefaults.standard.set(reduction, forKey: Keys.reduction) }
    }

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled) }
    }

    /// 비선형 곡선 지수 프리셋: 2.5(일반) / 4.0(문서·PDF) / 6.0(하이라이트 집중)
    @Published var curveExponent: Double {
        didSet { UserDefaults.standard.set(curveExponent, forKey: Keys.curveExponent) }
    }

    // MARK: - Private

    private enum Keys {
        static let reduction     = "whitePointReduction"
        static let isEnabled     = "whitePointEnabled"
        static let curveExponent = "curveExponent"
    }

    private let tableSize = 256

    /// 디스플레이 ID → 원본 감마 테이블 (다중 모니터 지원)
    private var originalTables: [CGDirectDisplayID: GammaTable] = [:]

    // MARK: - Init

    init() {
        let savedReduction = UserDefaults.standard.double(forKey: Keys.reduction)
        let savedEnabled   = UserDefaults.standard.bool(forKey: Keys.isEnabled)
        let savedExponent  = UserDefaults.standard.object(forKey: Keys.curveExponent) as? Double ?? 4.0

        self.reduction     = savedReduction
        self.isEnabled     = savedEnabled
        self.curveExponent = savedExponent

        saveOriginalTables()

        // Re-apply saved setting on launch
        if savedEnabled && savedReduction > 0 {
            applyReduction(savedReduction)
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
    }

    deinit {
        restoreOriginalTables()
    }

    // MARK: - Public API

    /// Apply the current `reduction` value to ALL active displays.
    func applyReduction(_ amount: Double? = nil) {
        let amount = amount ?? reduction
        guard amount > 0.001 else {
            restoreOriginalTables()
            return
        }

        // Map: slider 0‥1  →  max white output 1.0‥0.7  (최대 30% 감소)
        let maxOutput = CGGammaValue(1.0 - amount * 0.3)

        // Non-linear highlight compression curve
        //
        //  scaleFactor(t) = 1.0 - t^exponent × (1 - maxOutput)
        //
        //  t = 0 (black) → scaleFactor = 1.0  → output unchanged  ✓
        //  t = 1 (white) → scaleFactor = maxOutput               ✓
        //  mid-tones     → smooth transition, biased toward preserving darks
        //
        // Curve exponent preset: 2.5 = general / 4.0 = document·PDF / 6.0 = highlights only
        let exp = CGGammaValue(curveExponent)

        // 모든 저장된 디스플레이에 적용
        for (displayID, tables) in originalTables {
            var r = [CGGammaValue](repeating: 0, count: tableSize)
            var g = [CGGammaValue](repeating: 0, count: tableSize)
            var b = [CGGammaValue](repeating: 0, count: tableSize)

            for i in 0..<tableSize {
                let t = CGGammaValue(i) / CGGammaValue(tableSize - 1)
                let scaleFactor = 1.0 - pow(t, exp) * (1.0 - maxOutput)
                r[i] = tables.red[i]   * scaleFactor
                g[i] = tables.green[i] * scaleFactor
                b[i] = tables.blue[i]  * scaleFactor
            }

            CGSetDisplayTransferByTable(displayID, UInt32(tableSize), &r, &g, &b)
        }
    }

    /// Toggle the effect on/off.
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled && reduction > 0 {
            applyReduction()
        } else {
            restoreOriginalTables()
        }
    }

    /// Reset everything to factory defaults and restore all displays.
    func resetAll() {
        restoreOriginalTables()
        reduction = 0
        isEnabled = false
    }

    /// Restore original tables and quit.
    func quit() {
        restoreOriginalTables()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Private Helpers

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
        }

        // 연결 해제된 모니터: 테이블 제거
        for id in knownIDs.subtracting(currentIDs) {
            originalTables.removeValue(forKey: id)
        }

        // 활성 상태라면 새 구성에 즉시 재적용
        if isEnabled && reduction > 0.001 {
            applyReduction()
        }
    }
}
