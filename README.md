# Whiteout for macOS

> 아이패드의 **화이트포인트 낮추기** 기능을 macOS에서 구현한 메뉴바 앱

[![최신 릴리즈](https://img.shields.io/github/v/release/tank-jw/Whiteout?label=최신%20버전&color=orange)](https://github.com/tank-jw/Whiteout/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-13%2B-blue)](https://github.com/tank-jw/Whiteout)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](https://github.com/tank-jw/Whiteout)

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
- 🖥 **다중 모니터 지원** — 연결된 모든 디스플레이에 동시 적용
- 🔘 **곡선 타입 선택** — 일반(2.5) / 문서·PDF(4.0) / 하이라이트(6.0)로 세분화하여 T값 표기
- 🔄 **자동 업데이트** — 새 버전 출시 시 팝오버에서 클릭 한 번으로 업데이트
- 💾 **설정 자동 저장** — 재시작 후에도 유지
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

- [ ] `UpdateChecker.swift` — `currentVersion = "x.x.x"` 업데이트
- [ ] `build_dmg.sh` — `VERSION="x.x.x"` 동일하게 업데이트
- [ ] `README.md` — **업데이트 내역** 테이블에 새 버전 추가
- [ ] `bash build_dmg.sh` 실행 → DMG + ZIP 생성 확인
- [ ] `git commit` + `git push`
- [ ] `gh release create vx.x.x Whiteout.dmg Whiteout.zip`

---

## 파일 구조

```
Sources/Whiteout/
├── WhiteoutApp.swift   — @main, MenuBarExtra
├── AppDelegate.swift   — Dock 아이콘 숨김
├── DisplayManager.swift — 다중 모니터 감마 테이블 관리 및 단축키 로직 연동
├── ContentView.swift    — SwiftUI 팝오버 UI (단축키 녹화 컨트롤 포함)
├── Shortcuts.swift      — KeyboardShortcuts 이름 등록 정의
└── UpdateChecker.swift  — GitHub Releases 자동 업데이트
```

---

## 업데이트 내역

| 버전 | 내용 |
|---|---|
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

## 라이선스

MIT
