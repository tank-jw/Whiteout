# Reduce White Point for macOS

아이패드의 **화이트포인트 낮추기** 기능을 macOS에서 구현한 메뉴바 앱입니다.

## 어떻게 다른가요?

소프트웨어 오버레이가 아닌 **CoreGraphics의 `CGSetDisplayTransferByTable` API**로 디스플레이의 감마 테이블을 직접 수정합니다.

| | 일반 밝기 낮추기 | 이 앱 |
|---|---|---|
| 검정 | 영향받음 | **그대로 유지** |
| 대비 | 손상됨 | **유지됨** |
| 구현 방식 | 백라이트 조절 | GPU 감마 테이블 |

비선형 곡선(`t^4`)으로 어두운 영역은 최대한 보존하고 밝은 영역만 집중 감소시킵니다. 특히 PDF·문서 읽기에 최적화되어 있습니다.

## 요구 사항

- macOS 13 (Ventura) 이상
- Swift 5.9 이상

## 실행 방법

```bash
git clone https://github.com/your-username/Reduce_whitepoint.git
cd Reduce_whitepoint
swift run
```

## 기능

- 🌤 **메뉴바 앱** — Dock에 아이콘 없음
- 🎚 **감소량 슬라이더** — 0~30%, 5% 단위 스냅
- 🔘 **곡선 타입 선택** — 일반 / 문서·PDF / 하이라이트
- 💾 **설정 자동 저장** — 재시작 후에도 유지
- 🔄 **안전한 종료** — 앱 종료 시 원래 밝기 자동 복원

## 곡선 타입

| 타입 | 지수 | 특징 |
|---|---|---|
| 일반 | t = 2.5 | 전반적으로 부드럽게 감소 |
| 문서·PDF | t = 4.0 | 텍스트(검정) 보호, 흰 배경 집중 감소 |
| 하이라이트 | t = 6.0 | 어두운 영역 완전 보호, 밝은 부분만 |

## 빌드 구조

```
Sources/ReduceWhitePoint/
├── ReduceWhitePointApp.swift   — @main, MenuBarExtra
├── AppDelegate.swift           — Dock 아이콘 숨김
├── DisplayManager.swift        — CGSetDisplayTransferByTable 감마 관리
└── ContentView.swift           — SwiftUI 팝오버 UI
```

## 주의사항

앱이 강제종료(`kill -9`)되면 감마 테이블이 복원되지 않을 수 있습니다.  
이 경우 **로그아웃 → 로그인** 또는 **시스템 설정 > 디스플레이** 열기로 복원됩니다.

## 라이선스

MIT
