# Reduce White Point for macOS

> 아이패드의 **화이트포인트 낮추기** 기능을 macOS에서 구현한 메뉴바 앱

[![최신 릴리즈](https://img.shields.io/github/v/release/tank-jw/Reduce_whitepoint?label=최신%20버전&color=orange)](https://github.com/tank-jw/Reduce_whitepoint/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-13%2B-blue)](https://github.com/tank-jw/Reduce_whitepoint)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)](https://github.com/tank-jw/Reduce_whitepoint)

## 📥 다운로드

**[→ 최신 버전 DMG 다운로드](https://github.com/tank-jw/Reduce_whitepoint/releases/latest)**

> ⚠️ **처음 실행 시 Gatekeeper 경고가 뜨면:**
> - **방법 1 (간단):** 앱을 우클릭 → 열기 → 열기
> - **방법 2 (터미널):** `xattr -dr com.apple.quarantine /Applications/ReduceWhitePoint.app`

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
- 🖥 **다중 모니터 지원** — 연결된 모든 디스플레이에 동시 적용
- 🔘 **곡선 타입 선택** — 일반 / 문서·PDF / 하이라이트
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
git clone https://github.com/tank-jw/Reduce_whitepoint.git
cd Reduce_whitepoint
swift run
```

## DMG 직접 빌드

```bash
bash build_dmg.sh
# → ReduceWhitePoint.dmg, ReduceWhitePoint.zip 생성
```

---

## 파일 구조

```
Sources/ReduceWhitePoint/
├── ReduceWhitePointApp.swift   — @main, MenuBarExtra
├── AppDelegate.swift           — Dock 아이콘 숨김
├── DisplayManager.swift        — 다중 모니터 감마 테이블 관리
├── ContentView.swift           — SwiftUI 팝오버 UI
└── UpdateChecker.swift         — GitHub Releases 자동 업데이트
```

---

## 업데이트 내역

| 버전 | 내용 |
|---|---|
| **v1.4.1** | 자동 업데이트 후 재실행 버그 수정 (`nohup` 프로세스 분리) |
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
