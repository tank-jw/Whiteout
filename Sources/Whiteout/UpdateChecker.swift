import Foundation
import AppKit

/// GitHub Releases API를 통해 최신 버전을 확인하고 자동 업데이트를 수행하는 클래스.
class UpdateChecker: ObservableObject {

    // 현재 앱 버전 — 릴리즈 빌드 시 build_dmg.sh의 VERSION="1.6.5"과 함께 업데이트할 것
    static let currentVersion = "1.6.5"

    /// 주기적 재확인 간격 (120시간 = 5일)
    private static let checkIntervalSeconds: TimeInterval = 120 * 3600

    private let apiURL      = URL(string: "https://api.github.com/repos/tank-jw/Whiteout/releases/latest")!
    private let releasesURL = URL(string: "https://github.com/tank-jw/Whiteout/releases/latest")!

    @Published var updateAvailable:  Bool   = false
    @Published var latestVersion:    String = ""
    @Published var isChecking:       Bool   = false
    @Published var isDownloading:    Bool   = false
    @Published var downloadProgress: Double = 0
    @Published var showNetworkErrorAlert: Bool = false

    private var zipDownloadURL: URL?
    private var progressObservation: NSKeyValueObservation?
    private var periodicTimer: Timer?

    init() {
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

        isDownloading    = true
        downloadProgress = 0

        let task = URLSession.shared.downloadTask(with: zipURL) { [weak self] tempURL, _, error in
            guard let self else { return }
            self.progressObservation?.invalidate()
            DispatchQueue.main.async { self.downloadProgress = 1.0 }

            guard let tempURL, error == nil else {
                DispatchQueue.main.async { self.isDownloading = false }
                return
            }
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
        let extractDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("Whiteout_Update_\(UUID().uuidString)")

        try? fm.createDirectory(at: extractDir, withIntermediateDirectories: true)

        let zipDest = extractDir.appendingPathComponent("update.zip")
        try? fm.copyItem(at: tempZip, to: zipDest)

        let unzip = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unzip.arguments     = ["-o", zipDest.path, "-d", extractDir.path]
        try? unzip.run()
        unzip.waitUntilExit()

        let extractedApp = extractDir.appendingPathComponent("Whiteout.app")
        guard fm.fileExists(atPath: extractedApp.path) else {
            DispatchQueue.main.async { self.isDownloading = false }
            return
        }

        let currentBundle = Bundle.main.bundleURL
        let destination   = currentBundle.pathExtension == "app"
            ? currentBundle
            : URL(fileURLWithPath: "/Applications/Whiteout.app")

        let script = """
        #!/bin/bash
        sleep 2
        rm -rf '\(destination.path)'
        cp -R '\(extractedApp.path)' '\(destination.path)'
        xattr -dr com.apple.quarantine '\(destination.path)' 2>/dev/null || true
        open '\(destination.path)'
        rm -rf '\(extractDir.path)'
        """

        let scriptPath = NSTemporaryDirectory() + "whiteout_updater.sh"
        try? script.write(toFile: scriptPath, atomically: true, encoding: .utf8)

        let chmod = Process()
        chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmod.arguments     = ["+x", scriptPath]
        try? chmod.run()
        chmod.waitUntilExit()

        // nohup으로 앱 프로세스 그룹과 완전히 분리하여 실행
        // — 앱이 종료되어도 스크립트가 계속 실행되어 재실행까지 완료됨
        let launcher = Process()
        launcher.executableURL = URL(fileURLWithPath: "/bin/sh")
        launcher.arguments     = ["-c", "nohup /bin/sh '\(scriptPath)' > /dev/null 2>&1 &"]
        launcher.standardInput  = FileHandle.nullDevice
        launcher.standardOutput = FileHandle.nullDevice
        launcher.standardError  = FileHandle.nullDevice
        try? launcher.run()
        launcher.waitUntilExit()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
