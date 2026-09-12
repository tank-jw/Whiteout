import Foundation
import AppKit

/// GitHub Releases API를 통해 최신 버전을 확인하고 자동 업데이트를 수행하는 클래스.
public class UpdateChecker: ObservableObject {

    // 현재 앱 버전 — 릴리즈 빌드 시 build_dmg.sh의 VERSION="2.1.0"과 함께 업데이트할 것
    public static let currentVersion = "2.1.0"

    /// 주기적 재확인 간격 (120시간 = 5일)
    private static let checkIntervalSeconds: TimeInterval = 120 * 3600

    private let apiURL      = URL(string: "https://api.github.com/repos/tank-jw/Whiteout/releases/latest")!
    private let releasesURL = URL(string: "https://github.com/tank-jw/Whiteout/releases/latest")!

    @Published public var updateAvailable:  Bool   = false
    @Published public var latestVersion:    String = ""
    @Published public var isChecking:       Bool   = false
    @Published public var isDownloading:    Bool   = false
    @Published public var downloadProgress: Double = 0
    @Published public var showNetworkErrorAlert: Bool = false

    private var zipDownloadURL: URL?
    private var progressObservation: NSKeyValueObservation?
    private var periodicTimer: Timer?

    public init() {
        // View에 의존하지 않고 생성 즉시 주기 확인 시작
        scheduleTimer()
        fetchLatestRelease(isManual: false)
    }

    deinit { periodicTimer?.invalidate() }

    // MARK: - 업데이트 확인

    /// 앱 시작 시 호출 — 조용히 1회 확인 + 120시간 주기 타이머 시작
    private func startPeriodicChecks() {
        fetchLatestRelease(isManual: false)
        scheduleTimer()
    }

    /// 사용자가 직접 누른 경우 — 즉시 확인 후 타이머 리셋
    func manualCheck() {
        guard !isChecking && !isDownloading else { return }
        fetchLatestRelease(isManual: true)
        scheduleTimer()   // 수동 확인 시점부터 120시간 리셋
    }

    // MARK: - 내부 공통 네트워크 요청

    private func fetchLatestRelease(isManual: Bool) {
        if isManual {
            DispatchQueue.main.async { self.isChecking = true }
        }

        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else { return }

            defer {
                if isManual {
                    DispatchQueue.main.async { self.isChecking = false }
                }
            }

            if error != nil || data == nil {
                DispatchQueue.main.async {
                    if isManual {
                        self.showNetworkErrorAlert = true
                    }
                }
                return
            }

            guard let data,
                  let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag     = json["tag_name"] as? String else {
                DispatchQueue.main.async {
                    if isManual {
                        self.showNetworkErrorAlert = true
                    }
                }
                return
            }

            let remote = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag

            // 릴리즈 assets에서 .zip 다운로드 URL 추출
            var zipURL: URL?
            if let assets = json["assets"] as? [[String: Any]] {
                for asset in assets {
                    if let name   = asset["name"] as? String,
                       name.hasSuffix(".zip"),
                       let urlStr = asset["browser_download_url"] as? String,
                       let url    = URL(string: urlStr) {
                        zipURL = url
                        break
                    }
                }
            }

            DispatchQueue.main.async {
                self.latestVersion   = remote
                self.zipDownloadURL  = zipURL
                self.updateAvailable = self.isNewer(remote, than: Self.currentVersion)
            }
        }.resume()
    }

    // MARK: - 타이머

    private func scheduleTimer() {
        periodicTimer?.invalidate()
        periodicTimer = Timer.scheduledTimer(
            withTimeInterval: Self.checkIntervalSeconds,
            repeats: true
        ) { [weak self] _ in
            self?.fetchLatestRelease(isManual: false)
        }
    }

    // MARK: - 자동 업데이트 (다운로드 → 설치 → 재실행)

    /// zip이 있으면 자동 다운로드→설치, 없으면 브라우저로 폴백
    func performUpdate() {
        guard let zipURL = zipDownloadURL else {
            openReleasePage()
            return
        }

        DispatchQueue.main.async {
            self.isDownloading    = true
            self.downloadProgress = 0
        }

        let task = URLSession.shared.downloadTask(with: zipURL) { [weak self] tempURL, _, error in
            guard let self = self else { return }
            self.progressObservation?.invalidate()

            guard let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async {
                    self.isDownloading = false
                    self.openReleasePage()
                }
                return
            }

            DispatchQueue.main.async { self.downloadProgress = 1.0 }
            self.installUpdate(from: tempURL)
        }

        progressObservation = task.observe(\.countOfBytesReceived) { [weak self] t, _ in
            let total    = Double(t.countOfBytesExpectedToReceive)
            let received = Double(t.countOfBytesReceived)
            guard total > 0 else { return }
            DispatchQueue.main.async { self?.downloadProgress = received / total }
        }

        task.resume()
    }

    func openReleasePage() {
        NSWorkspace.shared.open(releasesURL)
    }

    // MARK: - 설치

    private func installUpdate(from tempZip: URL) {
        let fm         = FileManager.default
        let extractDir = fm.temporaryDirectory
            .appendingPathComponent("WhiteOut_Update_\(UUID().uuidString)")

        do {
            try fm.createDirectory(at: extractDir, withIntermediateDirectories: true)
        } catch {
            DispatchQueue.main.async { self.isDownloading = false }
            return
        }

        let zipDest = extractDir.appendingPathComponent("update.zip")
        do {
            try fm.copyItem(at: tempZip, to: zipDest)
        } catch {
            DispatchQueue.main.async { self.isDownloading = false }
            return
        }

        let unzip = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unzip.arguments     = ["-o", zipDest.path, "-d", extractDir.path]
        try? unzip.run()
        unzip.waitUntilExit()

        let extractedApp = extractDir.appendingPathComponent("WhiteOut.app")
        guard fm.fileExists(atPath: extractedApp.path) else {
            DispatchQueue.main.async { self.isDownloading = false }
            return
        }

        let currentBundle = Bundle.main.bundleURL
        let destination   = currentBundle.pathExtension == "app"
            ? currentBundle
            : URL(fileURLWithPath: "/Applications/WhiteOut.app")

        let currentPID = ProcessInfo.processInfo.processIdentifier
        let logPath = "/tmp/whiteout_updater.log"

        let script = """
        #!/bin/bash
        exec > "\(logPath)" 2>&1
        echo "=== WhiteOut Updater Started: $(date) ==="
        echo "Waiting for process \(currentPID) to terminate..."

        # 부모 프로세스 종료 대기 (최대 10초)
        for i in {1..20}; do
            if ! kill -0 \(currentPID) 2>/dev/null; then
                echo "Parent process exited cleanly."
                break
            fi
            sleep 0.5
        done

        # 확실한 종료 보장
        kill -9 \(currentPID) 2>/dev/null || true
        sleep 0.5

        echo "Replacing old application at '\(destination.path)'..."
        rm -rf '\(destination.path)'
        cp -R '\(extractedApp.path)' '\(destination.path)'
        xattr -dr com.apple.quarantine '\(destination.path)' 2>/dev/null || true

        echo "Relaunching updated application..."
        open '\(destination.path)'

        echo "Cleaning up temporary files..."
        rm -rf '\(extractDir.path)'
        rm -f "$0"
        echo "=== Update Successful: $(date) ==="
        """

        let scriptURL = fm.temporaryDirectory.appendingPathComponent("whiteout_updater_\(UUID().uuidString).sh")
        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        } catch {
            DispatchQueue.main.async { self.isDownloading = false }
            return
        }

        let chmod = Process()
        chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmod.arguments     = ["+x", scriptURL.path]
        try? chmod.run()
        chmod.waitUntilExit()

        // nohup과 백그라운드 서브쉘로 완전히 독립된 프로세스로 실행
        let launcher = Process()
        launcher.executableURL = URL(fileURLWithPath: "/bin/bash")
        launcher.arguments     = ["-c", "nohup /bin/bash '\(scriptURL.path)' > /dev/null 2>&1 &"]
        launcher.standardInput  = FileHandle.nullDevice
        launcher.standardOutput = FileHandle.nullDevice
        launcher.standardError  = FileHandle.nullDevice
        try? launcher.run()
        launcher.waitUntilExit()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApplication.shared.terminate(nil)
        }
    }

    // MARK: - 시맨틱 버전 비교

    private func isNewer(_ remote: String, than current: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let c = current.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(r.count, c.count) {
            let rv = i < r.count ? r[i] : 0
            let cv = i < c.count ? c[i] : 0
            if rv != cv { return rv > cv }
        }
        return false
    }
}
