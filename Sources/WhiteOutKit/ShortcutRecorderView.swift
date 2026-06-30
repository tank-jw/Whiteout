import SwiftUI
import AppKit

// MARK: - SwiftUI wrapper

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var shortcut: KeyShortcut?

    func makeNSView(context: Context) -> RecorderNSView {
        let view = RecorderNSView()
        view.onShortcutChanged = { newShortcut in
            shortcut = newShortcut
        }
        return view
    }

    func updateNSView(_ nsView: RecorderNSView, context: Context) {
        nsView.currentShortcut = shortcut
        nsView.needsDisplay = true
    }
}

// MARK: - NSView implementation

class RecorderNSView: NSView {
    var currentShortcut: KeyShortcut?
    var onShortcutChanged: ((KeyShortcut?) -> Void)?
    private var isRecording = false

    override var acceptsFirstResponder: Bool { true }
    override var intrinsicContentSize: NSSize { NSSize(width: 120, height: 22) }

    override func draw(_ dirtyRect: NSRect) {
        // 배경
        let bg: NSColor = isRecording
            ? NSColor.orange.withAlphaComponent(0.15)
            : NSColor(white: 0.5, alpha: 0.08)
        bg.setFill()
        let bgPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 0, dy: 1), xRadius: 5, yRadius: 5)
        bgPath.fill()

        // 테두리
        NSColor(white: 0.5, alpha: isRecording ? 0.5 : 0.25).setStroke()
        let border = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 1.5), xRadius: 5, yRadius: 5)
        border.lineWidth = 0.5
        border.stroke()

        // 텍스트
        let label: String
        let color: NSColor
        if isRecording {
            label = "⌨ 녹화 중..."
            color = .orange
        } else if let s = currentShortcut {
            label = s.displayString
            color = .labelColor
        } else {
            label = "클릭하여 설정"
            color = .tertiaryLabelColor
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: color
        ]
        let str = NSAttributedString(string: label, attributes: attrs)
        let sz = str.size()
        str.draw(at: NSPoint(
            x: (bounds.width  - sz.width)  / 2,
            y: (bounds.height - sz.height) / 2
        ))
    }

    // 클릭 시 녹화 시작
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func becomeFirstResponder() -> Bool {
        isRecording = true
        needsDisplay = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        needsDisplay = true
        return true
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: // Esc — 취소
            window?.makeFirstResponder(nil)
        case 51: // Delete — 단축키 삭제
            onShortcutChanged?(nil)
            currentShortcut = nil
            needsDisplay = true
            window?.makeFirstResponder(nil)
        default:
            if let shortcut = KeyShortcut.from(event: event) {
                onShortcutChanged?(shortcut)
                currentShortcut = shortcut
                needsDisplay = true
                window?.makeFirstResponder(nil)
            }
        }
    }

    // Command 키 조합 등이 performKeyEquivalent로 들어오는 경우도 처리
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isRecording else { return false }
        keyDown(with: event)
        return true
    }
}
