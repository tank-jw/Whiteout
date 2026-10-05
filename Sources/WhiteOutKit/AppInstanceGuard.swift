import Foundation
import AppKit

/// Whiteout 앱의 단일 인스턴스(Single Instance) 실행을 보장하고,
/// 중복 실행 시도 시 기존 인스턴스의 팝오버를 열도록 유도하는 가드 클래스.
public final class AppInstanceGuard {
    public static let shared = AppInstanceGuard()

    public static let revealNotificationName = NSNotification.Name("com.tankjw.WhiteOut.revealPopover")
    
    private let lockFilePath: String
    private var lockFileDescriptor: Int32 = -1
    private(set) public var isLockHeld: Bool = false

    public init(lockFilePath: String? = nil) {
        if let customPath = lockFilePath {
            self.lockFilePath = customPath
        } else {
            let tempDir = NSTemporaryDirectory() as NSString
            self.lockFilePath = tempDir.appendingPathComponent("com.tankjw.WhiteOut.lock")
        }
    }

    /// 다른 인스턴스가 실행 중인지 확인하고, 첫 번째 인스턴스라면 락을 획득합니다.
    /// - Parameter checkRunningApplications: NSRunningApplication 검사를 함께 수행할지 여부 (기본값 true)
    /// - Returns: `true` if this instance is the only running instance and acquired the lock.
    ///            `false` if another instance is already running.
    @discardableResult
    public func acquireSingleInstanceLock(checkRunningApplications: Bool = true) -> Bool {
        if isLockHeld {
            return true
        }

        // 1. NSRunningApplication 검사 (동일 Bundle Identifier를 가진 활성 프로세스 확인)
        if checkRunningApplications {
            let myPID = ProcessInfo.processInfo.processIdentifier
            let bundleID = Bundle.main.bundleIdentifier ?? "com.tankjw.WhiteOut"
            let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            let otherApps = runningApps.filter { $0.processIdentifier != myPID && !$0.isTerminated }
            
            if !otherApps.isEmpty {
                return false
            }
        }

        // 2. POSIX 커널 수준 flock 잠금
        let fd = open(lockFilePath, O_CREAT | O_RDWR, 0o644)
        guard fd >= 0 else {
            // 파일 생성 실패 시 안전하게 허용 (비정상 권한 환경 방어)
            return true
        }

        if flock(fd, LOCK_EX | LOCK_NB) != 0 {
            // 이미 다른 프로세스가 파일 락을 소유하고 있음 (EWOULDBLOCK)
            close(fd)
            return false
        }

        self.lockFileDescriptor = fd
        self.isLockHeld = true
        return true
    }

    /// 획득한 락을 명시적으로 해제합니다.
    public func releaseLock() {
        if lockFileDescriptor >= 0 {
            flock(lockFileDescriptor, LOCK_UN)
            close(lockFileDescriptor)
            lockFileDescriptor = -1
        }
        isLockHeld = false
    }

    /// 이미 실행 중인 기존 인스턴스에게 메뉴바 팝오버를 표시하라는 분산 알림(DistributedNotification)을 전송합니다.
    public func notifyExistingInstanceToReveal() {
        // 기존 프로세스가 있다면 포커스 활성화 요청
        let myPID = ProcessInfo.processInfo.processIdentifier
        let bundleID = Bundle.main.bundleIdentifier ?? "com.tankjw.WhiteOut"
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if let existingApp = runningApps.first(where: { $0.processIdentifier != myPID && !$0.isTerminated }) {
            existingApp.activate(options: .activateIgnoringOtherApps)
        }

        // 분산 알림으로 팝오버 즉시 열기 트리거
        DistributedNotificationCenter.default().postNotificationName(
            Self.revealNotificationName,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    /// 기본 인스턴스에서 외부 신호(중복 실행 시도) 수신 대기를 등록합니다.
    public func startListeningForRevealNotification(onReveal: @escaping () -> Void) -> NSObjectProtocol {
        return DistributedNotificationCenter.default().addObserver(
            forName: Self.revealNotificationName,
            object: nil,
            queue: .main
        ) { _ in
            onReveal()
        }
    }

    /// 등록된 옵저버를 해제합니다.
    public func stopListening(_ observer: NSObjectProtocol) {
        DistributedNotificationCenter.default().removeObserver(observer)
    }

    deinit {
        releaseLock()
    }
}
