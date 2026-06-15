import Foundation
import AppKit

/// GitHub Releases API 를 통해 최신 버전을 확인하는 클래스.
/// 앱 실행 시 백그라운드에서 한 번 체크하고, 새 버전이 있으면 UI에 알립니다.
class UpdateChecker: ObservableObject {

    // 현재 앱 버전 — DMG/릴리즈 빌드 시 build_dmg.sh 와 함께 업데이트할 것
    static let currentVersion = "1.1.0"

    private let apiURL = URL(string: "https://api.github.com/repos/tank-jw/Reduce_whitepoint/releases/latest")!
    private let releasesURL = URL(string: "https://github.com/tank-jw/Reduce_whitepoint/releases/latest")!

    @Published var updateAvailable = false
    @Published var latestVersion: String = ""

    /// 앱 시작 시 호출 — 백그라운드에서 조용히 체크
    func checkInBackground() {
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 8

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self,
                  let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String else { return }

            let remote = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
            DispatchQueue.main.async {
                self.latestVersion = remote
                self.updateAvailable = self.isNewer(remote, than: Self.currentVersion)
            }
        }.resume()
    }

    /// GitHub Releases 페이지 열기
    func openReleasePage() {
        NSWorkspace.shared.open(releasesURL)
    }

    // MARK: - Semantic Version Comparison

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
