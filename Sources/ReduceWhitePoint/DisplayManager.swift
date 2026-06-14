import Cocoa
import CoreGraphics
import Foundation
import Combine

/// Manages the display's gamma transfer table to reduce white point intensity.
///
/// This replicates iPad's "Reduce White Point" feature at the GPU/driver level:
///   - Black (0) stays 0 — contrast is preserved
///   - White (1.0) is scaled down to `1.0 - reduction * 0.3`  (max 30% reduction)
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
    private var originalRed:   [CGGammaValue] = []
    private var originalGreen: [CGGammaValue] = []
    private var originalBlue:  [CGGammaValue] = []

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

        // Restore gamma when the app is about to quit
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.restoreOriginalTables()
        }
    }

    deinit {
        restoreOriginalTables()
    }

    // MARK: - Public API

    /// Apply the current `reduction` value to the display's gamma table.
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

        var r = [CGGammaValue](repeating: 0, count: tableSize)
        var g = [CGGammaValue](repeating: 0, count: tableSize)
        var b = [CGGammaValue](repeating: 0, count: tableSize)

        for i in 0..<tableSize {
            let t = CGGammaValue(i) / CGGammaValue(tableSize - 1)
            let scaleFactor = 1.0 - pow(t, exp) * (1.0 - maxOutput)
            r[i] = originalRed[i]   * scaleFactor
            g[i] = originalGreen[i] * scaleFactor
            b[i] = originalBlue[i]  * scaleFactor
        }

        CGSetDisplayTransferByTable(CGMainDisplayID(), UInt32(tableSize), &r, &g, &b)

        UserDefaults.standard.set(amount, forKey: Keys.reduction)
        UserDefaults.standard.set(true,   forKey: Keys.isEnabled)
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

    /// Reset everything to factory defaults and restore the display.
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

    private func saveOriginalTables() {
        var r = [CGGammaValue](repeating: 0, count: tableSize)
        var g = [CGGammaValue](repeating: 0, count: tableSize)
        var b = [CGGammaValue](repeating: 0, count: tableSize)
        var count: UInt32 = 0

        CGGetDisplayTransferByTable(CGMainDisplayID(), UInt32(tableSize), &r, &g, &b, &count)

        originalRed   = r
        originalGreen = g
        originalBlue  = b
    }

    private func restoreOriginalTables() {
        guard !originalRed.isEmpty else { return }
        var r = originalRed
        var g = originalGreen
        var b = originalBlue
        CGSetDisplayTransferByTable(CGMainDisplayID(), UInt32(tableSize), &r, &g, &b)
    }
}
