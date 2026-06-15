import Foundation
import AppKit

/// GitHub Releases API를 통해 최신 버전을 확인하고 자동 업데이트를 수행하는 클래스.
class UpdateChecker: ObservableObject {

    // 현재 앱 버전 — 릴리즈 빌드 시 build_dmg.sh의 VERSION과 함께 업데이트할 것
    static let currentVersion = "1.3.0"

    private let apiURL   = URL(string: "https://api.github.com/repos/tank-jw/Reduce_whitepoint/releases/latest")!
    private let releasesURL = URL(string: "https://github.com/tank-jw/Reduce_whitepoint/releases/latest")!

    @Published var updateAvailable  = false
    @Published var latestVersion    = ""
    @Published var isDownloading    = false
    @Published var downloadProgress: Double = 0

    private var zipDownloadURL: URL?
    private var progressObservation: NSKeyValueObservation?

    // MARK: - 업데이트 확인

    /// 앱 시작 시 백그라운드에서 조용히 최신 버전 확인
    func checkInBackground() {
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 8

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self,
                  let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag  = json["tag_name"] as? String else { return }

            let remote = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag

            // 릴리즈 assets 에서 .zip 다운로드 URL 추출
            var zipURL: URL?
            if let assets = json["assets"] as? [[String: Any]] {
                for asset in assets {
                    if let name    = asset["name"] as? String,
                       name.hasSuffix(".zip"),
                       let urlStr  = asset["browser_download_url"] as? String,
                       let url     = URL(string: urlStr) {
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

    // MARK: - 자동 업데이트

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

        // 다운로드 진행률 관찰
        progressObservation = task.observe(\.countOfBytesReceived) { [weak self] t, _ in
            let total    = Double(t.countOfBytesExpectedToReceive)
            let received = Double(t.countOfBytesReceived)
            guard total > 0 else { return }
            DispatchQueue.main.async {
                self?.downloadProgress = received / total
            }
        }

        task.resume()
    }

    func openReleasePage() {
        NSWorkspace.shared.open(releasesURL)
    }

    // MARK: - 설치

    private func installUpdate(from tempZip: URL) {
        let fm          = FileManager.default
        let extractDir  = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("RWP_Update_\(UUID().uuidString)")

        try? fm.createDirectory(at: extractDir, withIntermediateDirectories: true)

        // zip 복사 후 압축 해제
        let zipDest = extractDir.appendingPathComponent("update.zip")
        try? fm.copyItem(at: tempZip, to: zipDest)

        let unzip = Process()
        unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        unzip.arguments     = ["-o", zipDest.path, "-d", extractDir.path]
        try? unzip.run()
        unzip.waitUntilExit()

        let extractedApp = extractDir.appendingPathComponent("ReduceWhitePoint.app")
        guard fm.fileExists(atPath: extractedApp.path) else {
            DispatchQueue.main.async { self.isDownloading = false }
            return
        }

        // 현재 앱 위치 결정: .app 번들이면 그 위치, 아니면(swift run 등) /Applications
        let currentBundle = Bundle.main.bundleURL
        let destination   = currentBundle.pathExtension == "app"
            ? currentBundle
            : URL(fileURLWithPath: "/Applications/ReduceWhitePoint.app")

        // 업데이터 셸 스크립트 작성 — 앱 종료 후 교체 → 재실행
        let script = """
        #!/bin/bash
        sleep 1
        rm -rf '\(destination.path)'
        cp -R '\(extractedApp.path)' '\(destination.path)'
        xattr -dr com.apple.quarantine '\(destination.path)' 2>/dev/null || true
        open '\(destination.path)'
        rm -rf '\(extractDir.path)'
        """

        let scriptPath = NSTemporaryDirectory() + "rwp_updater.sh"
        try? script.write(toFile: scriptPath, atomically: true, encoding: .utf8)

        let chmod = Process()
        chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmod.arguments     = ["+x", scriptPath]
        try? chmod.run()
        chmod.waitUntilExit()

        // 스크립트 실행 후 현재 앱 종료
        let runner = Process()
        runner.executableURL = URL(fileURLWithPath: "/bin/sh")
        runner.arguments     = [scriptPath]
        try? runner.run()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
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
