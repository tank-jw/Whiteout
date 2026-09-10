import Carbon
import AppKit
import Foundation

// MARK: - KeyShortcut Model

public struct KeyShortcut: Codable, Equatable {
    public let keyCode: UInt32
    public let carbonModifiers: UInt32

    public init(keyCode: UInt32, carbonModifiers: UInt32) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
    }

    public var displayString: String {
        var result = ""
        if carbonModifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if carbonModifiers & UInt32(optionKey)  != 0 { result += "⌥" }
        if carbonModifiers & UInt32(shiftKey)   != 0 { result += "⇧" }
        if carbonModifiers & UInt32(cmdKey)     != 0 { result += "⌘" }
        result += Self.keyCodeToString(keyCode)
        return result
    }

    public static func keyCodeToString(_ code: UInt32) -> String {
        let map: [UInt32: String] = [
            0:"A",  11:"B", 8:"C",  2:"D",  14:"E", 3:"F",
            5:"G",  4:"H",  34:"I", 38:"J", 40:"K", 37:"L",
            46:"M", 45:"N", 31:"O", 35:"P", 12:"Q", 15:"R",
            1:"S",  17:"T", 32:"U", 9:"V",  13:"W", 7:"X",
            16:"Y", 6:"Z",
            18:"1", 19:"2", 20:"3", 21:"4", 23:"5",
            22:"6", 26:"7", 28:"8", 25:"9", 29:"0",
            24:"=", 27:"-", 30:"]", 33:"[", 41:";", 39:"'",
            43:",", 47:".", 44:"/", 42:"\\", 50:"`",
            36:"↩", 48:"⇥", 49:"Space", 51:"⌫", 53:"Esc",
            122:"F1",  120:"F2",  99:"F3",  118:"F4",
            96:"F5",  97:"F6",  98:"F7",  100:"F8",
            101:"F9", 109:"F10", 103:"F11", 111:"F12",
            123:"←", 124:"→", 125:"↓", 126:"↑",
            115:"↖", 119:"↘", 116:"⇞", 121:"⇟", 117:"⌦",
            65:"[Keypad .]", 67:"[Keypad *]", 69:"[Keypad +]",
            75:"[Keypad /]", 78:"[Keypad -]", 81:"[Keypad =]",
            82:"[Keypad 0]", 83:"[Keypad 1]", 84:"[Keypad 2]",
            85:"[Keypad 3]", 86:"[Keypad 4]", 87:"[Keypad 5]",
            88:"[Keypad 6]", 89:"[Keypad 7]", 91:"[Keypad 8]", 92:"[Keypad 9]"
        ]
        return map[code] ?? "key(\(code))"
    }

    /// NSEvent의 키 입력에서 KeyShortcut 생성 (modifier 없으면 nil)
    public static func from(event: NSEvent) -> KeyShortcut? {
        let nsModifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        guard !nsModifiers.isEmpty else { return nil }
        var carbon: UInt32 = 0
        if nsModifiers.contains(.command) { carbon |= UInt32(cmdKey) }
        if nsModifiers.contains(.option)  { carbon |= UInt32(optionKey) }
        if nsModifiers.contains(.control) { carbon |= UInt32(controlKey) }
        if nsModifiers.contains(.shift)   { carbon |= UInt32(shiftKey) }
        return KeyShortcut(keyCode: UInt32(event.keyCode), carbonModifiers: carbon)
    }
}

// MARK: - ShortcutManager

/// Carbon Event Manager를 사용해 전역 단축키를 등록/해제하는 싱글톤.
/// 외부 라이브러리 의존 없이 시스템 내장 API만 사용한다.
final class ShortcutManager {
    static let shared = ShortcutManager()

    /// 단축키가 눌렸을 때 호출되는 콜백
    var onTrigger: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    private init() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userData) -> OSStatus in
                guard let ptr = userData else { return noErr }
                Unmanaged<ShortcutManager>.fromOpaque(ptr).takeUnretainedValue().onTrigger?()
                return noErr
            },
            1, &spec, selfPtr, &eventHandlerRef
        )
    }

    func register(_ shortcut: KeyShortcut) {
        unregister()
        let id = EventHotKeyID(signature: OSType(0x574F5554), id: 1)  // 'WOUT'
        RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            id,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    deinit {
        unregister()
        if let ref = eventHandlerRef { RemoveEventHandler(ref) }
    }
}
