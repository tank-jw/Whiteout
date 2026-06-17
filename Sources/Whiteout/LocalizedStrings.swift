import Foundation

struct LocalizedStrings {
    static func title(isEN: Bool) -> String {
        isEN ? "WhiteOut" : "화이트아웃"
    }
    static func statusActive(isEN: Bool, percent: Int) -> String {
        isEN ? "Max White: \(percent)%" : "흰색 최대값 \(percent)%"
    }
    static func statusDisabled(isEN: Bool) -> String {
        isEN ? "Disabled" : "비활성화됨"
    }
    static func reductionLabel(isEN: Bool) -> String {
        isEN ? "Reduction" : "감소량"
    }
    static func preserveBlacks(isEN: Bool) -> String {
        isEN ? "Preserve Blacks" : "검정 유지"
    }
    static func maxWhiteLevel(isEN: Bool, percent: Int) -> String {
        isEN ? "Max white level \(percent)%" : "흰색 최대값 \(percent)%"
    }
    static func shortcutToggle(isEN: Bool) -> String {
        isEN ? "Toggle via Shortcut" : "단축키로 On/Off"
    }
    static func launchAtLogin(isEN: Bool) -> String {
        isEN ? "Launch at Login" : "로그인 시 자동 실행"
    }
    static func shortcutRecord(isEN: Bool) -> String {
        isEN ? "Configure Shortcut" : "단축키 설정"
    }
    static func curveTypeLabel(isEN: Bool) -> String {
        isEN ? "Curve Type" : "곡선 타입"
    }
    static func curveGeneral(isEN: Bool) -> String {
        isEN ? "General" : "일반"
    }
    static func curveDocs(isEN: Bool) -> String {
        isEN ? "Docs · PDF" : "문서·PDF"
    }
    static func curveHighlights(isEN: Bool) -> String {
        isEN ? "Highlights" : "하이라이트"
    }
    static func manualCheckHelp(isEN: Bool) -> String {
        isEN ? "Check for updates" : "업데이트 확인 (120시간마다 자동 확인)"
    }
    static func quitLabel(isEN: Bool) -> String {
        isEN ? "Quit" : "종료"
    }
    static func detailsTitle(isEN: Bool) -> String {
        isEN ? "Brightness Curve (x-axis: Input ➔ y-axis: Output)" : "밝기 변환 곡선 (x축 : 입력 밝기 → y축 : 출력 밝기)"
    }
    static func detailsSectionTitle(isEN: Bool) -> String {
        isEN ? "Principles & Curve Analysis" : "원리 및 곡선 분석"
    }
    static func detailsHowItWorks(isEN: Bool) -> String {
        isEN ? "Comparison of Methods" : "작동 방식 차이점"
    }
    static func updateDownloading(isEN: Bool, ver: String) -> String {
        isEN ? "Downloading v\(ver)..." : "v\(ver) 다운로드 중..."
    }
    static func updateAvailable(isEN: Bool, ver: String) -> String {
        isEN ? "New version v\(ver) available" : "새 버전 v\(ver) 사용 가능"
    }
    static func updateClickToUpdate(isEN: Bool) -> String {
        isEN ? "Click to auto update" : "클릭하여 자동 업데이트"
    }
    static func updateNetworkErrorTitle(isEN: Bool) -> String {
        isEN ? "Update Error" : "업데이트 오류"
    }
    static func updateNetworkErrorMsg(isEN: Bool) -> String {
        isEN ? "Failed to get update info. Please check your network connection." : "업데이트 정보를 가져오지 못했습니다. 네트워크 연결 상태를 확인해 주세요."
    }
    static func allDisplays(isEN: Bool) -> String {
        isEN ? "All Displays" : "모든 디스플레이"
    }
    static func displayLabel(isEN: Bool) -> String {
        isEN ? "Display" : "디스플레이"
    }
    static func appRulesSectionTitle(isEN: Bool) -> String {
        isEN ? "App-Specific Rules" : "앱별 자동 설정"
    }
    static func addRuleBtn(isEN: Bool, appName: String) -> String {
        isEN ? "+ Add \(appName)" : "+ \(appName) 추가"
    }
    static func addRuleBtnDefault(isEN: Bool) -> String {
        isEN ? "+ Add App Rule" : "+ 앱 규칙 추가"
    }
    static func ruleActiveBanner(isEN: Bool, appName: String) -> String {
        isEN ? "\(appName) rules active" : "\(appName) 자동 적용 중"
    }
    static func compareOurApp(isEN: Bool) -> String {
        isEN ? "Whiteout (GPU Gamma)" : "Whiteout (GPU 감마 조절)"
    }
    static func compareOurAppDesc(isEN: Bool) -> String {
        isEN ? "Preserves 100% black level, maintaining contrast and picture quality." : "검정색(0) 레벨을 100% 보존하여 명암비와 화질이 완벽히 유지됩니다."
    }
    static func compareOverlay(isEN: Bool) -> String {
        isEN ? "Software Overlay Filter" : "소프트웨어 오버레이 필터"
    }
    static func compareOverlayDesc(isEN: Bool) -> String {
        isEN ? "Draws a dark window, elevating black levels and ruining contrast." : "화면에 검은 막을 씌워 블랙 레벨을 들뜨게 하고 명암비를 손상시킵니다."
    }
}
