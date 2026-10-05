import AppKit
import WhiteOutKit

// 단일 인스턴스 검사: 이미 Whiteout이 실행 중이라면 기존 창을 띄우고 즉시 종료
if !AppInstanceGuard.shared.acquireSingleInstanceLock() {
    AppInstanceGuard.shared.notifyExistingInstanceToReveal()
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
