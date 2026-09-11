# Whiteout for macOS

> 아이패드의 **화이트포인트 낮추기** 기능을 macOS에서 구현한 메뉴바 앱

[![최신 릴리즈](https://img.shields.io/github/v/release/tank-jw/Whiteout?label=최신%20버전&color=orange)](https://github.com/tank-jw/Whiteout/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-13%2B-blue)](https://github.com/tank-jw/Whiteout)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](https://github.com/tank-jw/Whiteout)

## 📱 스크린샷 및 소개

<p align="center">
  <img src="assets/media__1781458526509.png" width="320" alt="Whiteout UI Screenshot 1" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/media__1781459352094.png" width="320" alt="Whiteout UI Screenshot 2" />
</p>

### 🌐 공식 웹페이지 & 가이드
본 프로젝트의 `docs` 디렉토리는 GitHub Pages를 통해 인터랙티브한 웹페이지로 호스팅될 수 있도록 제작되었습니다. GPU 감마 조절의 동작 원리와 대비 비교 슬라이더, 실시간 감마 곡선 시각화 그래프를 제공합니다.

<p align="center">
  <img src="assets/media__1781620544415.png" width="650" alt="Whiteout Webpage Preview" />
</p>

---

## 📥 다운로드

**[→ 최신 버전 DMG 다운로드](https://github.com/tank-jw/Whiteout/releases/latest)**

> ⚠️ **처음 실행 시 Gatekeeper 경고가 뜨면:**
> - **방법 1 (간단):** 앱을 우클릭 → 열기 → 열기
> - **방법 2 (터미널):** `xattr -dr com.apple.quarantine /Applications/Whiteout.app`

---

## 어떻게 다른가요?

소프트웨어 오버레이가 아닌 **CoreGraphics의 `CGSetDisplayTransferByTable` API**로 디스플레이의 감마 테이블을 직접 수정합니다.

|  | 일반 밝기 낮추기 | 이 앱 |
|---|---|---|
| 검정 | 영향받음 | **그대로 유지** |
| 대비 | 손상됨 | **유지됨** |
| 구현 방식 | 백라이트 조절 | GPU 감마 테이블 |
| 다중 모니터 | 메인만 | **모두 적용** |

비선형 곡선(`scaleFactor(t) = 1 - t^n × (1 - maxOutput)`)으로 어두운 영역은 최대한 보존하고 밝은 영역만 집중 감소시킵니다.

---

## 기능

- 🌤 **메뉴바 앱** — Dock에 아이콘 없음
- 🎚 **감소량 슬라이더** — 0~30%, 5% 단위 스냅
- ⌨️ **사용자 설정 글로벌 단축키** — 언제 어디서나 키보드 단축키로 온/오프 가능
- 🖥 **디스플레이별 개별 제어** — 모든 모니터를 일괄 제어하거나 개별 모니터(내장/외장)마다 다른 감소량 및 곡선 지수 개별 적용 지원
- 🛡 **앱별 자동 설정 규칙** — 사파리, 엑스코드 등 특정 앱이 포커스를 얻을 때 사전에 설정한 감소량 및 곡선이 자동으로 적용되고, 포커스가 빠지면 복원되는 자동화 프리셋 기능
- ⏰ **시간별 자동 설정 규칙** — 지정된 시간대(예: 야간 17:00 ~ 23:00 등)에 화이트포인트 감소율이 자동으로 조절되는 시간 계획 자동화 프리셋 지원
- 🔘 **곡선 타입 선택** — 일반(2.5) / 문서·PDF(4.0) / 하이라이트(6.0)로 세분화하여 T값 표기
- 🔄 **자동 업데이트** — 새 버전 출시 시 팝오버에서 클릭 한 번으로 업데이트
- 💾 **설정 자동 저장** — 재시작 후에도 유지 (연결 해제된 디스플레이 설정 정보도 유지)
- ✅ **안전한 종료** — 앱 종료 시 원래 밝기 자동 복원

---

## 곡선 타입

| 타입 | 지수 | 특징 |
|---|---|---|
| 일반 | t = 2.5 | 전반적으로 부드럽게 감소 |
| 문서·PDF | t = 4.0 | 텍스트(검정) 보호, 흰 배경 집중 감소 |
| 하이라이트 | t = 6.0 | 어두운 영역 완전 보호, 밝은 부분만 |

---

## 요구 사항

- macOS 13 (Ventura) 이상
- Swift 5.9 이상 (소스 빌드 시)

## 소스에서 실행

```bash
git clone https://github.com/tank-jw/Whiteout.git
cd Whiteout
swift run
```

## DMG 직접 빌드

```bash
bash build_dmg.sh
# → Whiteout.dmg, Whiteout.zip 생성
```

---

## 새 버전 배포 체크리스트

새 기능/버그 수정 후 릴리즈할 때 반드시 확인:

### 1. 코드 및 환경 설정 체크
- [x] `UpdateChecker.swift` — `currentVersion = "x.x.x"` 업데이트 (2.0.0 완료)
- [x] `build_dmg.sh` — `VERSION="x.x.x"` 동일하게 업데이트 (2.0.0 완료)
- [x] `README.md` — **업데이트 내역** 테이블에 새 버전 추가 (2.0.0 완료)
- [x] `bash build_dmg.sh` 실행 → DMG + ZIP 생성 확인 (v2.0.0 완료)
- [x] `git commit` + `git push` (v2.0.0 완료)
- [x] `gh release create vx.x.x Whiteout.dmg Whiteout.zip` (v2.0.0 완료)

### 2. 🧪 배포 전 필수 무결성 검증 시나리오 테스트 (GTM/유료화 대비)
- [x] **디스플레이 감쇄**: 슬라이더(0~30%) 이동 시 감마가 실시간으로 조정되며, 비활성화 시 정상적인 원래 감마로 즉각 복구되는지 확인.
- [x] **곡선 보정**: Normal(2.5), Document(4.0), Highlight(6.0) 타입 선택 시 감쇄 형태가 각 지수에 맞게 변동되는지 확인.
- [x] **다중 디스플레이**: 외부 모니터 연결/해제 시 개별 인가값 캐시가 정상 동작하며 예외 크래시가 없는지 확인.
- [x] **앱별 자동화**: 등록된 앱 포커스 진입/이탈 시 감쇄율이 즉각 변동 및 복원되는지 확인.
- [x] **시간 범위 자동화**: 자정 경계(예: 야간 23:00 ~ 익일 06:00) 설정 시에도 정상 활성화 및 타이머 오프셋 동작 확인.
- [x] **글로벌 단축키 & 로그인 실행**: Carbon HotKey 기반 글로벌 온/오프 토글 및 SMAppService 로그인 자동 실행 등록이 정상 기능하는지 확인.
- [x] **감마 복원 가드 (`isTableDistorted`)**: 앱 비정상 종료 등으로 왜곡된 하드웨어 감마 상태에서 재시작할 때 왜곡된 감마를 기본값으로 잘못 캐싱하는 현상을 차단하고, 선형(Linear) 감마 재생성을 통해 즉각 자동 복구하는지 검증.
- [x] **패키징 및 리소스**: `.dmg` 마운트 시 Retina 대응 144 DPI 배경(sunset platinum)이 화면을 꽉 채우고 두 아이콘이 슬롯 가이드 내에 정밀 배치되며, `AppIcon.icns` 누락 없이 애플리케이션 및 메뉴바에 정상 노출되는지 확인.

## 파일 구조

```
Sources/Whiteout/
├── WhiteoutApp.swift         — @main, MenuBarExtra
├── AppDelegate.swift         — Dock 아이콘 숨김
├── DisplayManager.swift      — 다중 모니터 감마 테이블 관리 및 Carbon 단축키 로직 연동
├── ContentView.swift         — SwiftUI 메인 팝오버 컨테이너 뷰
├── CurveGraphView.swift      — 감마 곡선 실시간 시각화 그래프 뷰
├── DetailsSectionView.swift   — 다중 모니터, 앱 규칙, 시간 규칙 등 상세 제어 뷰
├── Models.swift              — 규칙(Rule) 및 비즈니스 데이터 모델 정의
├── LocalizedStrings.swift    — 한국어/영어 다국어 번역 딕셔너리
├── ShortcutRecorderView.swift — Carbon API 기반 글로벌 단축키 녹화용 뷰
├── Shortcuts.swift           — 단축키 등록 및 Carbon HotKey 연동 정의
└── UpdateChecker.swift        — GitHub Releases 기반 자동 업데이트 엔진
```

## 업데이트 내역

| 버전 | 내용 |
|---|---|
| **v2.0.1** | **시간 기반 규칙 밝기 동기화 버그 픽스 및 메뉴바 팝오버 윈도우 축 안정화**<br>- `DisplayManager`의 struct 값 복사 캐싱(`activeTimeRule`, `activeAppRule`)을 실시간 계산 프로퍼티로 리팩토링하여 시간/앱 규칙 활성화 중 슬라이더 및 Picker 조절 시 화면 밝기 미반영 버그 완벽 해결<br>- 자동화 규칙 활성화 중 슬라이더 조작 시 사용자의 기본 영구 설정(`UserDefaults`)이 오버라이트되지 않도록 가드 보강<br>- 메뉴바 온/오프 토글 시 비율 수치 노출로 인한 가로 너비 확장 및 팝오버 창 좌우 흔들림(축 이동) 현상을 방지하기 위해 메뉴바 아이콘 프레임 너비(46pt)를 고정 안정화 |
| **v2.0.0** | **차세대 네이티브 2.0 카드형 UI 전면 리디자인 및 웹 디자인 동기화**<br>- macOS Control Center 스타일의 인셋 카드(Inset Grouped Card) 아키텍처 및 톱니바퀴 Preferences 슬라이드 네비게이션 적용<br>- 110pt 실시간 전달 곡선 모니터(Live Transfer Curve)를 메인 화면에 전면 배치하여 60fps 하이테크 캘리브레이터 시각화 완성<br>- Shortcuts 특수문자 키코드 매핑 보강 및 앱 규칙 즉시 감지(`getFrontmostApplication`) 구조 도입<br>- 웹 랜딩 페이지 100% 무채색 순수 화이트포인트 감쇄 통일 및 순백색(#ffffff) 배경 리디자인 배포 |
| **v1.7.4** | **정밀 코드 감사 개선 및 엣지 케이스 안정성 강화**<br>- 규칙 삭제 시 인덱스 경계 검사(Bounds Check) 가드 추가로 삭제 연타 크래시 원천 차단<br>- 단축키 녹화기에서 보조키 조합 Delete 키(`Cmd+Delete` 등) 등록 지원<br>- 외장 모니터 연결 해제 시 디스플레이 Picker 목록 실시간 동기화(`activeDisplaySettings`)<br>- 인앱 업데이터 스크립트 실행 후 자체 파일 자동 청소(`rm -f "$0"`) 적용<br>- `DisplayManager`에 `@MainActor` 적용으로 Swift 6 엄격 동시성(Concurrency) 대비<br>- `build_dmg.sh` 이전 잔여 볼륨 자동 언마운트 가드 및 랜딩 페이지 최신 릴리즈 다운로드 링크(`latest`) 연결 |
| **v1.7.3** | **코드 품질 전수 점검 및 안정성/호환성 강화**<br>- `build_dmg.sh` 내 `Info.plist` 중복 CFBundleIconFile 선언 정리 및 유니버셜 바이너리(arm64+x86_64) 패키징 무결성 강화<br>- `DisplayManager`의 NotificationCenter 옵저버 해제(deinit) 누수 방지 로직 추가<br>- `ContentView` 슬라이더 바인딩 내 중복 감마 적용 연산 제거로 슬라이더 조작 반응성 향상<br>- Apple Silicon 및 Intel Mac, macOS 13+ 전 기종 무결성 전수 검증 통과 |
| **v1.7.2.1** | **품질 보증 테스트 스위트 및 의존성 주입(DI) 아키텍처 도입**<br>- `Package.swift` 구조 개편을 통해 코어 로직을 `WhiteOutKit` 라이브러리로 분리하고 단위/통합 테스트 타겟 구축<br>- 모의 디스플레이 및 시간 환경 하에서 작동하는 9대 시나리오 전수 검사 스위트(`swift test`) 완성<br>- 자동 규칙(시간/앱) 적용 시 `UserDefaults` 사용자 초기 설정이 오버라이트되는 버그 수정 |
| **v1.7.2** | **코드 구조 모듈화 리팩토링 및 안정성/패키징 대폭 개선**<br>- 비대해진 `ContentView.swift`를 `CurveGraphView`, `DetailsSectionView`, `Models` 파일로 역할별 깔끔히 모듈화 분리<br>- 앱 강제 종료 상태에서 재시작 시 왜곡된 감마가 오인 캐싱되는 복원력 버그 방지 가드(`isTableDistorted`) 탑재<br>- Active Rules 포인터 O(1) 캐싱 및 시간 규칙 비동기 중복 연산 최적화<br>- `build_dmg.sh` 내 고해상도 앱 아이콘(`AppIcon.icns`) 누락 패키징 버그 수정 및 Info.plist CFBundleIconFile 주입 완료 |
| **v1.7.1.1** | **내부 백엔드 코드 리팩토링 및 최적화**<br>- 디스플레이별 감쇄율 계산 루프와 중복 함수들(`applyReductionForActiveRule`, `applyReductionForActiveTimeRule`)을 단일화된 연산 메서드로 병합하여 중복 코드를 극적으로 줄이고 유지 보수 편의성 극대화 |
| **v1.7.1** | **시간별 화이트포인트 자동 설정 규칙 기능 추가**<br>- 사용자가 지정한 시간 범위(예: 17:00 ~ 23:00)에 맞춰 화이트포인트 감소 강도가 실시간으로 자동 변경되고, 범위를 벗어날 시 원래 설정값으로 자동 복원되는 주기 엔진 및 Time Picker UI 도입 |
| **v1.7.0** | **디스플레이별 개별 제어 및 앱별 자동화 규칙 대대적 추가**<br>- 연결된 모니터(내장/외장)별 독립적인 화이트포인트 감소량 및 곡선 지수 개별 설정 지원<br>- 특정 앱(예: Safari 등)이 전면에 활성화되면 전용 화이트포인트 프리셋을 자동으로 즉각 적용하고, 다른 앱으로 이동 시 기본값으로 안전 복구하는 자동화 규칙 엔진 추가 |
| **v1.6.5** | 다른 Mac에서 실행 시 단축키 리소스 누락으로 인한 크래시 해결 및 Intel/Apple Silicon 유니버설 아키텍처 통합 지원 |
| **v1.6.4** | 로그인 시 자동 실행(Launch at Login) 설정 기능 추가 (macOS 13+ SMAppService API 활용) |
| **v1.6.3** | 디스플레이 감마 연산 최적화(Multi-monitor 캐싱), 다국어 번역 딕셔너리 분리(LocalizedStrings.swift), 실시간 곡선 그래프 연산 최적화(steps=60) 및 SwiftUI 레이아웃(updateBanner) 구조 간소화 |
| **v1.6.2** | 헤더 타이틀을 두 줄("화이트" / "아웃")의 위트 있는 레이아웃으로 변경(비활성화 시 "화이트"만 표시), "아웃" 및 슬라이더 아래 "흰색 최대값 X%" 라벨의 텍스트 색상을 감소분 강도(0% ~ 30%)에 연동하여 주황색 그라데이션으로 실시간 연동 처리 |
| v1.6.1 | 팝오버 헤더의 텍스트가 잘리는 현상 해결을 위해 긴 상태 설명 문구를 '흰색 최대값 X%'로 컴팩트화 |
| v1.6.0 | 한국어/영어 다국어 선택(KR/EN 토글) 기능 추가 및 전체 UI 영어 번역 지원, 팝오버 헤더의 기본 한글 표기명을 '화이트아웃'으로 명시화, 초기화 버튼 제거 |
| v1.5.3 | 감마 곡선 시각화 그래프의 입력/출력 축 이름 추가 및 변화가 적은 0~30% 구간을 축소하여 고대비 시각화 개선 |
| v1.5.2 | 메뉴바 정보 버튼을 통한 비선형 감쇄 곡선 실시간 시각화 패널 및 GPU 감마 조절 원리 설명 추가 |
| v1.5.1 | 곡선 타입 버튼 텍스트 복원 및 지수(T값) 레이블 헤더 배치로 레이아웃 개선, 최신 버전일 때의 수동 업데이트 확인 알림 제거(조용히 통과) |
| v1.5.0 | 앱 이름을 **Whiteout**으로 리브랜딩, 사용자 정의 글로벌 단축키로 On/Off 제어 추가 |
| v1.4.2 | 코드 최적화: 이중 Divider 버그 수정, 런타임 모니터 연결/해제 즉시 반영, 중복 코드 제거 |
| v1.4.1 | 자동 업데이트 후 재실행 버그 수정 (`nohup` 프로세스 분리) |
| v1.4.0 | 120시간 주기 자동 업데이트 확인 + 수동 확인 버튼 |
| v1.3.0 | 자동 업데이트 (다운로드 → 설치 → 재실행) |
| v1.2.0 | 인앱 업데이트 알림 |
| v1.1.0 | 다중 모니터 지원 |
| v1.0.0 | 최초 공개 |

---

## 주의사항

앱이 강제종료(`kill -9`)되면 감마 테이블이 복원되지 않을 수 있습니다.  
이 경우 **로그아웃 → 로그인** 또는 **시스템 설정 > 디스플레이** 열기로 복원됩니다.

---

## 🤖 AI 에이전트 오케스트레이션 (AI Agent Orchestration)

본 프로젝트는 각 개발 단계 및 비즈니스 목적에 최적화된 **7종의 전문 AI 에이전트**들과 협업하여 개발되었습니다. 아래는 각 대화별 에이전트의 역할 분류와 이를 재현하거나 독립적으로 호출할 때 사용할 수 있는 프롬프트 템플릿입니다.

| 대화 ID / 에이전트 역할 | 에이전트 성격 및 설명 | 핵심 프롬프트 (Prompt / Persona) |
|---|---|---|
| **Core App Developer**<br>`848151ae-1c96-4666-a1c0-365d981ddb5b` | **macOS Swift & GPU 하드웨어 개발 전문가**<br>디스플레이 드라이버 및 GPU 감마 조절 API 분석, 비선형 감쇄 수학 곡선 공식 구현 및 Swift 코어 기능 설계 | *밑의 상세 프롬프트 참고* |
| **Mathematical Explainer**<br>`1342c8b9-d9e5-4c21-b82f-d95f64dde6f8` | **기술 시각화 및 디스플레이 공학 설명 전문가**<br>감마 곡선의 비선형 조절 원리를 수학적으로 쉽게 해설하고 어두운 영역 보존 이유 설명 | *밑의 상세 프롬프트 참고* |
| **Web Frontend Developer**<br>`941bcd4e-b46e-40fa-98fe-11248c5e3aab` | **크리에이티브 UX/UI 엔지니어**<br>대조군 비교 슬라이더, 실시간 감마 곡선 그래프 등 인터랙티브 기능을 담은 고품격 랜딩 페이지 디자인 및 제작 | *밑의 상세 프롬프트 참고* |
| **DevOps & Web Hosting Consultant**<br>`4710943e-9cbb-4b42-94bc-8d0e5b39b735` | **인프라/클라우드 아키트텍트**<br>GitHub Pages, Vercel, Cloudflare, Oracle Cloud 등 호스팅 플랫폼 비교 분석 및 배포/도메인 매핑 | *밑의 상세 프롬프트 참고* |
| **Business Strategist**<br>`2e5f1ff0-a59c-46fb-afcb-d1adbd5be686` | **글로벌 비즈니스 및 소프트웨어 마케팅 전략가**<br>수익화 모델(유료 앱스토어 vs 후원형 오픈소스) 장단점 분석 및 북미/영어권 시장 마케팅 전략 수립 | *밑의 상세 프롬프트 참고* |
| **Business Auditor & PM**<br>`737ba8ad-c67d-42b3-bf01-352e88a9c735` | **냉철하고 직설적인 비즈니스 진단 전문가**<br>진행 상황을 뼈아프게 분석하여 시간 낭비 요소 제거, MVP 출시 독려 및 마케팅 방향성 피드백 | *밑의 상세 프롬프트 참고* |
| **QA Engineer & Integrity Verifier**<br>*(새로운 대화)* | **품질 보증 및 통합 시나리오 테스트 전문가**<br>코드 수정 및 릴리즈 배포 전 전 기능 시나리오 테스트를 수행하여 비즈니스 무결성 및 무중단 안정성 검증 | *밑의 상세 프롬프트 참고* |

---

### 에이전트별 상세 역할 및 프롬프트

#### 1. Core App Developer (핵심 앱 개발 에이전트)
* **대화 링크**: [Go to Conversation](file:///Users/jw/.gemini/antigravity/brain/848151ae-1c96-4666-a1c0-365d981ddb5b)
* **프롬프트**:
  ```text
  너는 macOS Swift 및 하드웨어 연동 개발 전문가야. macOS 디스플레이의 감마 테이블을 직접 조작하여 밝은 영역의 강도를 지수 곡선에 따라 줄여주는 화이트포인트 낮추기 메뉴바 앱을 구축하려고 해.

  요구사항:
  1. 소프트웨어 투명 오버레이를 씌우는 방식이 아니라, CoreGraphics의 `CGSetDisplayTransferByTable` API를 사용해 GPU 감마 테이블을 직접 수정해야 해.
  2. 비선형 감쇄 곡선 `scaleFactor(t) = 1 - t^n * (1 - maxOutput)` 공식을 구현하여, 검은색(어두운 영역)과 전체 대비는 보존하고 흰색(밝은 영역)만 집중적으로 감소시켜야 해.
  3. 다중 모니터 개별 제어, 단축키 지원, 백그라운드 메뉴바 앱 구조를 가진 SwiftUI + Swift 프로젝트 코드를 설계해줘.
  ```

#### 2. Mathematical & Technical Explainer (수학적/기술적 설명 에이전트)
* **대화 링크**: [Go to Conversation](file:///Users/jw/.gemini/antigravity/brain/1342c8b9-d9e5-4c21-b82f-d95f64dde6f8)
* **프롬프트**:
  ```text
  너는 디스플레이 기술 및 컴퓨터 그래픽스 원리를 명확하게 설명해주는 기술 교육 전문가야.
  macOS에서 GPU 감마 테이블 조작(`CGSetDisplayTransferByTable`)을 사용해 화이트포인트를 낮추는 비선형 압축 곡선의 수학적 원리를 일반인과 개발자 모두가 쉽게 이해할 수 있도록 구조화해서 설명해줘.
  
  요구사항:
  1. 단순 밝기 조절(선형 감소)과 비선형 감쇄 곡선의 차이점을 수학적/시각적으로 대비하여 설명해줘.
  2. 어두운 영역(Black level)과 대비(Contrast)가 어떻게 보존되는지 명확한 이유를 제시해줘.
  3. UI 상에서 실시간으로 감마 곡선을 시각화할 수 있도록 SVG 및 수학적 좌표 연산 로직을 설명해줘.
  ```

#### 3. Web Frontend Developer (홍보 웹페이지 제작 에이전트)
* **대화 링크**: [Go to Conversation](file:///Users/jw/.gemini/antigravity/brain/941bcd4e-b46e-40fa-98fe-11248c5e3aab)
* **프롬프트**:
  ```text
  너는 웹 프론트엔드 개발자이자 UX 디자이너야. macOS 화이트포인트 조절 앱 'WhiteOut'의 홍보 및 원리 설명용 프리미엄 1페이지 웹사이트를 제작해줘.

  요구사항:
  1. HTML, Vanilla CSS, Vanilla Javascript만 사용해서 제작하고 라이브러리 의존성을 최소화해줘.
  2. 다음 인터랙티브 요소를 반드시 포함해야 해:
     - 일반 밝기 조절 vs GPU 화이트포인트 감소를 눈으로 비교할 수 있는 이미지 대비 슬라이더 (Split-screen slider)
     - 사용자가 선택한 곡선 지수(n=2.5, 4.0, 6.0)와 감소율(0~30%)에 따라 실시간으로 변하는 SVG 감마 곡선 그래프
  3. 디자인은 다크 모드 기반의 프리미엄 글래스모피즘(Glassmorphism) 스타일과 고급스러운 그라데이션, 부드러운 애니메이션을 적용해줘.
  ```

#### 4. DevOps & Web Hosting Consultant (웹 호스팅 배포 에이전트)
* **대화 링크**: [Go to Conversation](file:///Users/jw/.gemini/antigravity/brain/4710943e-9cbb-4b42-94bc-8d0e5b39b735)
* **프롬프트**:
  ```text
  너는 DevOps 엔지니어이자 웹 배포 전문가야. 정적 홍보용 웹사이트(HTML/CSS/JS)를 호스팅하기 위해 GitHub Pages, Vercel, Cloudflare Pages, Oracle Cloud Free Tier의 장단점을 비용, 성능(CDN), SSL 자동화, 배포 편의성 측면에서 비교 분석해줘. 
  비교 후 가장 비용 효율적이고 안정적인 플랫폼(Cloudflare Pages 등)에 도메인을 연동하고 배포하는 세부 단계와 트러블슈팅 가이드를 작성해줘.
  ```

#### 5. Business Strategist & Marketing Expert (비즈니스 및 글로벌 세일즈 전략 에이전트)
* **대화 링크**: [Go to Conversation](file:///Users/jw/.gemini/antigravity/brain/2e5f1ff0-a59c-46fb-afcb-d1adbd5be686)
* **프롬프트**:
  ```text
  너는 글로벌 모바일/데스크톱 소프트웨어 비즈니스 전략가야. macOS 유틸리티 앱의 비즈니스 모델(App Store Paid, In-app Purchase Freemium, Donation-based Open Source)을 다각도로 분석하고, 영어권(특히 북미/서유럽) 시장을 타겟으로 한 세일즈 및 마케팅 전략을 제시해줘.
  
  요구사항:
  1. 오픈소스로 깃허브에 코드를 공개하면서 인앱 결제를 유도하는 전략(예: alt-tab-macos)의 장단점과 코드 우회 취약점을 다뤄줘.
  2. 7일 무료 평가판 제공 후 라이선스 구매를 유도하는 모델의 기술적 실현 가능성을 평가해줘.
  3. Reddit, Product Hunt 등을 활용한 오가닉 마케팅 카피라이팅 가이드라인을 제공해줘.
  ```

#### 6. Product Reviewer & Business Auditor (프로덕트 검토 및 비즈니스 감사 에이전트)
* **대화 링크**: [Go to Conversation](file:///Users/jw/.gemini/antigravity/brain/737ba8ad-c67d-42b3-bf01-352e88a9c735)
* **프롬프트**:
  ```text
  너는 냉철하고 직설적인 소프트웨어 비즈니스 감사원(Business Auditor)이자 프로덕트 매니저야.
  현재까지 진행된 대화 내용과 개발 상황을 바탕으로, 비즈니스 관점에서 시간 낭비 요소는 없었는지, 프로덕트 방향성이 올바른지 날카롭고 냉정하게 비판해줘.
  
  요구사항:
  1. 듣기 좋은 위로나 타협 없이, 오직 '출시(Go-To-Market)'와 '수익 창출' 관점에서만 평가해줘.
  2. 유저가 불필요하게 파고들고 있는 기술적 함정이나 과도한 기획이 있다면 지적하고, 당장 MVP를 출시하여 돈을 벌기 위해 필요한 핵심 액션 아이템 리스트를 뼈아프게 제시해줘.
  ```

#### 7. QA Engineer & Integrity Verifier (품질 보증 및 무결성 검증 에이전트)
* **프롬프트**:
  ```text
  너는 macOS 애플리케이션 QA 엔지니어이자 소프트웨어 무결성 검증 전문가야. 
  Whiteout 앱의 유료화 출시 및 배포 안정성을 확보하기 위해 다음 주요 기능들에 대한 시나리오 테스트를 수행하고 결함 유무를 완벽하게 검증해줘.

  주요 검증 기능 및 테스트 케이스:
  1. 기본 디스플레이 감쇄 기능: 슬라이더 값 변경(0~30%)에 따른 GPU 감마 테이블 갱신 및 비활성화 시 정상 복원 여부
  2. 곡선 타입 동작 검증: Normal(2.5), Document(4.0), Highlight(6.0) 곡선 지수값 인가 시의 GPU 테이블 보정 곡선 유효성
  3. 다중 디스플레이 제어: 모니터 연결/해제 시 개별 인가값 유지 및 크래시 가드 작동 검증
  4. 앱별/시간별 규칙 트리거: 타겟 앱 포커스 진입/이탈, 시간 지정(자정 교차 범위 포함) 트리거 시 정확한 인가율 전환 및 복원 여부
  5. 전역 단축키 & 로그인 시 실행: Carbon HotKey 단축키 온/오프 토글 및 SMAppService 자동 실행의 샌드박스 무결성 검증
  6. 감마 왜곡 복원 가드: 비정상 종료 후 이미 왜곡된 감마 테이블 상태로 재실행될 때, 오인 캐싱을 차단하고 선형(Linear) 감마 재생성 가드가 작동하는지 검증
  7. 빌드/패키징 무결성: build_dmg.sh 내의 AppIcon.icns 누락 여부, Info.plist 아이콘 연결 및 Retina용 144 DPI 배경/아이콘 좌표 정렬 검증
  ```

---

### 📌 핵심 의사결정 이력 (Key Decision Log)

프로젝트 진행 과정에서 전반적인 대화 기록을 통해 합의 및 확정된 주요 기술적/비즈니스적 핵심 아키텍처 및 의사결정 이력입니다. 모든 에이전트는 작업을 시작할 때 이 사항을 반드시 숙지하고 설계에 반영해야 합니다.

* **브랜드명 및 포지셔닝 (Brand & Narrative)**:
  - 앱 공식 명칭은 **Whiteout**으로 최종 확정함 (기존 안이었던 Veil은 존재감이 부족하여 폐기).
  - 극지방이나 설원에서 반사광 과다로 시야를 잃는 기상 현상인 **"화이트아웃/설맹 현상(Snow Blindness)"**을 브랜드 서사로 채택함. "당신의 화면 속 흰색 배경이 눈을 멀게 하고 있다"는 스토리라인을 바탕으로 북미/영어권의 눈 피로에 민감한 헤비 유저(밤샘 개발자/디자이너 등)를 타겟팅함.
  - 브랜드 시그니처 테마 색상으로 **오렌지 & 옐로우 그라데이션** (`#ff7600` ~ `#ffb800`)을 적용하여 강렬하고 프리미엄한 인상을 심어줌.

* **디스플레이 감쇄 알고리즘 (Display Engine)**:
  - 단순 소프트웨어 반투명 오버레이를 화면에 씌우는 저품질 렌더링 방식을 배제하고, macOS의 GPU 디스플레이 감마 조절 API인 **`CGSetDisplayTransferByTable`**을 사용하여 하드웨어 레벨에서 화이트포인트를 직접 제어함.
  - 비선형 지수 감쇄 곡선 공식 **`scaleFactor(t) = 1 - t^n × (1 - maxOutput)`**을 구현하여, 어두운 영역(True Black)과 전체 대비(Contrast)를 완벽하게 유지하면서 화면 내의 밝은 흰색 부분만 효과적으로 감소시킴.
  - 다중 모니터 개별 제어 및 백엔드 설정 값 적용 우선순위(App Rule ➔ Time Rule ➔ User Settings)를 단일화된 루프(`DisplayManager.swift`) 내에서 연산 처리하도록 최적화함.

* **시간 기반 & 앱 기반 자동화 규칙 (Automation Engine)**:
  - 사용자가 지정한 야간 시간대(예: `23:00 ~ 06:00` 등 자정을 걸쳐 넘어가는 오프셋 포함)를 30초 주기로 백그라운드 타이머가 체크하여 자동으로 밝기를 감소 및 복원하는 시간 주기 엔진 탑재.
  - 특정 앱(Xcode, Safari 등) 포커스 이동 시 사전 설정 프리셋으로 즉각 전환 및 복구하는 활성 앱 규칙 엔진 연동.

* **안정성 및 의존성 최소화 (Build & Stability)**:
  - 타사 오픈소스 라이브러리(`KeyboardShortcuts` 등)의 버그로 인한 크래시를 방지하기 위해, 번들 리소스 의존성을 완전히 제거하고 시스템 내장 **Carbon HotKey API**(`Shortcuts.swift`)로 전역 단축키를 직접 연동함.

* **DMG 배포 패키징 최적화 (`build_dmg.sh`)**:
  - macOS Finder 캐시 우회를 위해 볼륨명을 **`WhiteOut Installer`**로 지정하고, 마운트 직후 Finder 프로세스가 `.DS_Store` 파일 버퍼를 쓰기 전에 디태치되는 현상을 방지하고자 **AppleScript 실행 후 `sleep 5` 대기 처리**를 추가하여 메타데이터 저장을 보장함.
  - Retina 디스플레이 대응을 위해 배포 배경 이미지(`assets/dmg_background.png`)의 해상도를 sips 명령어를 통해 **144 DPI**로 강제 출력 처리하여 600x600 pt 크기에 깨짐 없이 채움. Finder 내 아이콘 크기를 **115 pt**로 맞춰 배경 이미지 슬롯 가이드와 일치시킴.

* **웹 랜딩 페이지 스펙 & 호스팅 (Web & Hosting)**:
  - `docs/` 및 `new_web/`에 퍼포먼스 중심의 Vanilla CSS/JS 정적 페이지 구축.
  - **핵심 요소**: Split-screen 이미지 대비 슬라이더, 지수 값(n=2.5, 4.0, 6.0) 및 슬라이더 조절에 반응하는 실시간 Canvas/SVG 감마 곡선 그래프, 단축키 녹화/자동 실행 Mockup UI를 포함.
  - `navigator.language` 기반 다국어 자동 설정 및 KR/EN 로컬 스토리지 연동 수동 전환 토글 지원.
  - GitHub API(`fetchLatestVersion()`)를 통해 런타임에 최신 버전 명칭을 실시간으로 가져와 화면에 표시.
  - 배포는 CDN 캐싱이 빠르고 안정적인 **Cloudflare Pages** 호스팅 인프라를 채택함.

---

### 🧠 에이전트별 누적 학습 사항 (Key Learnings)

각 에이전트가 작업을 수행하면서 겪은 문제 해결 과정이나 핵심 노하우를 대화 종료 시점에 자동으로 이 영역에 업데이트합니다.

* **Core App Developer**:
  - [2026-06-30] 비대화되었던 SwiftUI 파일(ContentView)을 CurveGraphView, DetailsSectionView, Models로 깔끔하게 컴포지션 분리하여 가독성을 높이고, 이미 왜곡된 감마 상태로 재시작 시 오인 캐싱을 유발하는 치명적인 복원력 버그를 선형(Linear) 감마 재생성 가드를 통해 완벽하게 해결함.
  - [2026-06-30] DisplayManager를 5개의 독립된 서비스 프로토콜로 의존성 주입 리팩토링하고 WhiteOutKit 라이브러리 분할 및 단위 테스트 타겟(WhiteOutKitTests)을 구축하여 테스트 가능성 및 모듈성을 대폭 향상시킴.
  - [2026-08-17] Info.plist 중복 키 정리, NotificationCenter 옵저버 토큰 deinit 해제 처리 및 SwiftUI 슬라이더 바인딩 중복 감마 인가 호출 제거로 반응성과 라이프사이클 무결성을 극대화하여 v1.7.3으로 배포함.
  - [2026-09-11] 규칙 삭제 시 인덱스 경계 검사 가드 추가, ShortcutRecorderView의 보조키 조합 Delete 키 허용, 외장 모니터 해제 시 활성 디스플레이 실시간 필터링 및 @MainActor 선언으로 Swift 6 엄격 동시성 안정성을 확보하여 v1.7.4로 배포함.
  - [2026-09-11] 수직 나열식 Divider 구조와 토글 남발을 탈피하여 macOS Control Center 스타일의 인셋 카드(Inset Grouped Card) 구조와 톱니바퀴 환경설정(Preferences) 슬라이드 네비게이션으로 리디자인하고, Shortcuts의 특수문자 키코드(24번 등) 누락 매핑을 수정하여 네이티브 완성도를 극대화함.
  - [2026-09-11] 메인 제어 카드의 실시간 감마 변환 곡선 모니터(Live Transfer Curve)를 설정창 내 진단 그래프와 동일한 110pt 높이로 규격을 일치시키고 하단 반투명 오렌지 그라데이션 면적 채우기와 상/하단 100%·0% 축 레이블을 완비하여, 슬라이더 감쇄율 조절 및 T계수 모드 전환 시 60fps로 즉각 반응하는 하이테크 디스플레이 캘리브레이터 시각화 UX를 완성함.
  - [2026-09-11] Main develop의 앱별 자동화 규칙 추가 버튼 구조(실제 앱 아이콘, 오렌지 강조 바, 동적 앱 명칭)를 원형 그대로 복원하고, DisplayManager의 lastActiveApp 속성을 @Published 및 DI 프로토콜(WorkspaceServiceProtocol.getFrontmostApplication) 기반 즉시 감지 구조로 보강하여 앱 시작 직후나 포커스 전환 시에도 추가 버튼이 누락 없이 즉각 반응하도록 안정성을 확보함.
  - [2026-09-11] 네이티브 2.0 카드형 UI 리디자인, 110pt 실시간 전달 곡선 모니터 전면 배치 및 Preferences 슬라이드 전환을 완성하여 v2.0.0으로 정식 배포함.
  - [2026-09-11] TimeRule/AppRule의 Swift struct 값 복사(Snapshot) 캐싱으로 인해 규칙 활성 중 슬라이더 변경 시 CoreGraphics 감마 테이블에 이전 복사본 값이 재인가되던 버그를 계산 프로퍼티(Live Computed Property) 구조로 전면 리팩토링하여 해결하고, MenuBarExtra 라벨의 고정 프레임(46pt)을 설정하여 온/오프 시 팝오버 윈도우의 좌우 축 흔들림을 완벽 차단함.
* **Mathematical Explainer**:
  - (여기에 에이전트가 학습 사항을 기록합니다)
* **Web Frontend Developer**:
  - [2026-06-30] 다국어(Ko/En) 지원을 위해 navigator.language 기반 자동 감지 기능과 localStorage 및 EN/KR 수동 토글 버튼을 결합하여 동적 렌더링을 구현하고, 극지 화이트아웃(설맹) 서사에 맞는 텍스트 카피와 Before 영역의 과노출 화이트아웃 펄스 글로우(radial-gradient & animation) 시각 효과를 적용함.
  - [2026-06-30] 모바일 디바이스(iPhone 등 480px 이하 뷰포트)에서 헤더 네비게이션이 겹치는 현상과 슬라이더 영역 내 320px 노트북 가로 너비로 인한 가로 스크롤 레이아웃 깨짐을 방지하기 위해, 패딩 감소 및 로고/토글/CTA 버튼 폰트·패딩을 정교하게 최적화하는 미디어 쿼리를 개발하여 완벽한 모바일 반응성을 확보함.
  - [2026-09-11] 랜딩 페이지 다운로드 링크를 고정 버전(v1.0.0)에서 GitHub Releases latest 엔드포인트로 현대화하고, 실제 시스템 요구사항에 맞추어 최소 OS 요구 사양을 macOS 13.0+로 정정함.
  - [2026-09-11] 웹 네비게이션 상단 로고를 macOS 네이티브 DMG 앱 아이콘(`AppIcon.png`)으로 통일하고, 레이아웃 변경 없이 차가운 쿨 다크 톤에서 눈이 편안한 누르스름한 웜 다크 톤(Warm Espresso & Amber Gold)으로 컬러 시스템을 리디자인함.
  - [2026-09-11] 기술 정밀도(Tech Explanation) 및 비교 분석 테이블(Comparison Table), 슬라이더 뱃지 등에서 누락되었던 20여 개 요소에 data-ko / data-en 및 localStorage 우선 감지 스크립트를 전수 매핑하여, 영문 모드(EN) 접속 시 한글이 단 하나도 섞이지 않는 완전한 글로벌 다국어 렌더링 무결성을 달성함.
  - [2026-09-11] 웹 전체의 테마를 순백색(0% 감쇄)부터 20% 감쇄된 웜 오프화이트까지 Hero 인터랙티브 비교 슬라이더의 위치(0~100%)와 60fps로 실시간 연동되는 Dynamic Whiteout Lerp 시스템을 구현하고, 텍스트 대비(Contrast) 100% 보존 가독성 및 핸들 실시간 감쇄율 뱃지, 슬라이더 하단 라벨 겹침 방지 레이아웃을 완성함.
  - [2026-09-11] 화이트포인트 낮추기(Reduce White Point)는 Night Shift와 달리 색온도 왜곡(누르스름한 웜톤) 없이 화이트 스펙트럼의 피크 휘도만 순수하게 감쇄하는 기능이므로, 웹 전체 색상 체계 및 슬라이더 보간 공식을 완전한 무채색 중립 그레이(R=G=B) 감쇄로 전환하여 제품 본연의 정체성을 완벽히 일치시킴.
  - [2026-09-11] Hero 비교 슬라이더 조작 시 밝기 변화가 체감되지 않던 원인(노트북 화면 내 브라우저의 정적 배경색 하드코딩, 좌측 다크 IDE 구간 드래그 시 우측 화면 불변 현상, 구 다크 모드 잔재 배경색)을 진단하고, 노트북 브라우저 모의 화면 배경을 CSS 변수(--slider-browser-bg)와 60fps 실시간 연동하며 포인터 캡처(setPointerCapture) 및 에셋 캐시 버스팅(?v=2.1.0)을 적용해 슬라이더 조작 전 구간에서 즉각적인 화이트포인트 감쇄 반응성을 확보함.
  - [2026-09-11] script.js 내 isDragging 중복 선언(SyntaxError)으로 인한 슬라이더 비동작 및 --slider-width 미설정으로 인한 노트북 우측 치우침 버그를 해결함. .comparison-slider에 container-type: inline-size를 도입하여 JS 실행 전후 무관하게 노트북 및 상단 눈 그래픽의 50% 분할선 정렬을 완벽 보장하고, 포인터·마우스·터치 통합 드래그 리스너 및 캐시 버스팅(?v=2.2.0)을 적용해 60fps 무결성 조작을 복원함.
  - [2026-09-11] 슬라이더 조작 시 분할된 서로 다른 창(IDE/브라우저)이 튀어나오며 노트북 위치가 왜곡되던 문제를 해결하기 위해, 단일 웹 문서 창 및 CSS clip-path 마스킹 구조로 전면 리팩토링함. 노트북을 화면 정중앙에 영구 고정하고 슬라이더 핸들 좌우로 오직 WhiteOut ON(감쇄 및 보호 쉴드)/OFF(눈부신 순백색 및 플래시뱅) 시각 효과만 실시간 대비되도록 구현하여 비교 UX의 직관성과 무결성을 완성함.
* **DevOps & Web Hosting Consultant**:
  - [2026-09-11] Cloudflare Pages와 GitHub master 브랜치(docs/ 타겟) 연동을 통해 정적 리소스 캐시 버스팅(?v=2.1.0) 및 무중단 글로벌 CDN 배포 무결성을 실시간 검증하고, GitHub Releases v2.0.0 바이너리(WhiteOut.dmg)와의 다운로드 엔드포인트 연동 상태를 최종 확인 완료함.
* **Business Strategist**:
  - [2026-07-07] 스마트 귀마개 dBud의 Flat Attenuation(균일 감쇄) 철학을 Whiteout의 GPU 감마 테이블 제어 기술에 대입하여, 화면의 선명도(대비)는 보존하고 눈부신 광원의 볼륨만 깎아내는 인지 부하 저감 중심의 국문 브랜드 카피를 설계함.
  - [2026-07-23] 맥 유틸리티 앱의 다중 채널(Mac App Store + 웹사이트 직접 판매) 병행 판매 전략(Omnichannel) 분석 및 채널 간 상호 보완 마케팅 시너지 구조 정리.
  - [2026-07-23] 기능 스펙(다중 모니터 개별 제어, 앱/시간 자동화 규칙) 및 서양권 유저의 심리적 결제 장벽을 고려한 맥 앱스토어 최적 가격 정책($3.99~$4.99 일회성 소장) 도출.
  - [2026-07-23] 북미(미국) 물가 체감(라떼 1잔 $5~$7)을 반영한 $3.99~$4.99 앱 가격의 'Buy Me a Coffee' 구매 심리 가성비 검증.
  - [2026-09-11] AI 코딩 툴 고도화 시대에서의 구매 심리(코드 생성이 아닌 0-Setup 완제품 경험 소비) 및 초기 비용(20만원) 리스크를 0으로 만드는 웹 기반 사전 검증(Lemon Squeezy MoR 린 런칭) 프레임워크 수립.
  - [2026-09-11] Lemon Squeezy 등 MoR(Merchant of Record) 플랫폼의 글로벌 세금 대행 구조 및 한국 세법(초기 개인 정산/종소세 신고, 사업화 시 외화 영세율 부가세 0% 적용) 합법성 및 세무 전략 정립.
  - [2026-09-11] 애플 앱스토어의 한국 지역 유료 판매 규정(전자상거래법 사업자 정보 요구)과 글로벌(북미/유럽) 타겟 출시 시 개인(Individual) 정산 프로세스 및 통신판매업 면제 요건 분석.
* **Business Auditor & PM**:
  - [2026-06-30] macOS에 존재하지 않는 "흰색점 줄이기(Reduce White Point)" 기능을 재발견하여 iOS와의 차이를 검증하고, 이를 경쟁 제품군(BetterDisplay, Lunar 등) 분석에 연동하여 차별화된 영문 마케팅(극지 화이트아웃/설맹 서사) 및 타겟 포지셔닝(밤샘 개발자 중심) 전략을 수립함.
  - [2026-06-30] 에이전트들이 이전 의사결정 사항(Whiteout 명명 및 하드웨어 감마 테이블 등)을 일관성 있게 준수하며 개발할 수 있도록 AGENTS.md 행동 수칙 및 README.md 핵심 의사결정 이력(Key Decision Log) 자동화 연동을 설계 및 구현함.
  - [2026-06-30] 프로젝트 전체 대화 및 5종의 아키텍처 워크스루(Swift 앱, 웹 프론트엔드, 호스팅 배포, DMG 빌드 등)를 정밀 분석하여, AI 협업 싱글 소스용 고밀도 '핵심 의사결정 이력(Key Decision Log)'을 정교하게 재작성함.
* **QA Engineer & Integrity Verifier**:
  - [2026-06-30] 감쇄율 연동, 곡선 지수 보정, 다중 디스플레이, 시간/앱별 자동화 O(1) 매핑, 전역 핫키 및 왜곡된 감마의 복원 가드(isTableDistorted) 검증을 포괄하는 8대 무결성 시나리오 교차 테스트 프로토콜을 수립하고 전원 통과를 확인하여 v1.7.2로 배포함.
  - [2026-06-30] DisplayManager의 감쇄 공식, 앱/시간 자동화 규칙, 전역 핫키 토글, 그리고 왜곡된 감마 복원 가드를 검증하는 5대 시나리오 통합 테스트 케이스를 구현하고, 테스트 중 발견된 Rule 활성화 시 UserDefaults의 사용자 설정 값이 오버라이트되는 버그를 수정함.
* **Preview Explorer**:
  - [2026-06-30] CoreGraphics C-API, Timer, NSWorkspace, 및 SMAppService 등의 강결합을 해제하기 위한 프로토콜 기반 의존성 주입(Dependency Injection) 아키텍처를 설계하고, 자정 교차 시간 규칙 테스트용 MockClockService 등 5종의 Mock 구조를 수립함.
  - [2026-06-30] Designed a testable architecture for Whiteout using dependency injection, decoupling DisplayManager from CoreGraphics, Date/Timer, NSWorkspace, and SMAppService with fully mockable protocols.
  - [2026-06-30] DisplayManager 내의 6대 핵심 결합 위치를 정밀 추적하고, 기존 SwiftUI 앱의 하위 호환성을 유지하기 위한 기본값 생성자(Default Initializer Param) 형태의 DI 리팩토링 방안을 제안함.
* **Preview Auditor**:
  - [2026-06-30] macOS Whiteout 통합 테스트 스위트와 DisplayManager/DisplayServices의 무결성 검증을 완료하고, Mocking 환경 하에서 10초 이내(실제 0.085초)의 헤드리스 정상 수행을 입증함.
* **Preview Packaging Tester**:
  - [2026-06-30] `build_dmg.sh` 스크립트를 사용하여 arm64 및 x86_64 아키텍처용 유니버설 바이너리 생성 및 DMG/ZIP 패키징 전 과정을 성공적으로 검증함.


---

## 라이선스

MIT

```
Reduce_whitepoint
├─ .claude
│  └─ settings.local.json
├─ Package.swift
├─ README.md
├─ Sources
│  └─ Whiteout
│     ├─ AppDelegate.swift
│     ├─ ContentView.swift
│     ├─ DisplayManager.swift
│     ├─ LocalizedStrings.swift
│     ├─ ShortcutRecorderView.swift
│     ├─ Shortcuts.swift
│     ├─ UpdateChecker.swift
│     └─ WhiteoutApp.swift
├─ WhiteOut.app
│  └─ Contents
│     ├─ Info.plist
│     ├─ MacOS
│     │  └─ WhiteOut
│     ├─ Resources
│     │  └─ AppIcon.icns
│     └─ _CodeSignature
│        └─ CodeResources
├─ WhiteOut.zip
├─ assets
│  ├─ AppIcon.icns
│  ├─ AppIcon.png
│  ├─ dmg_background.png
│  ├─ media__1781458526509.png
│  ├─ media__1781458648529.png
│  ├─ media__1781459352094.png
│  ├─ media__1781619648112.png
│  ├─ media__1781620166220.png
│  └─ media__1781620544415.png
├─ build_dmg.sh
├─ docs
│  ├─ index.html
│  ├─ script.js
│  └─ style.css
├─ generate_assets.sh
└─ mask_icon.swift

```