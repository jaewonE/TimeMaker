# Changelog

## 1.0.2 — 2026-08-28

### English

- Increased minute-scroll adjustment to 4× and second-scroll adjustment to 2× the configured base step.
- Made minute adjustment stop at `00:00` and `1440:00` rather than wrapping.
- Moved today-progress dots to an eight-row maximum grid overlaid at the left of the timer window.
- Made the timer window open at app launch and restored the visible scroll-step value in Settings.
- Added an opt-in Mac default notification-sound setting.

### 한국어

- 분 스크롤은 설정 기준값의 4배, 초 스크롤은 2배로 조절 폭을 확대.
- 분 조절이 `00:00`과 `1440:00`에서 순환하지 않고 멈추도록 변경.
- 오늘의 진행 도트를 타이머 창 좌측의 최대 8행 오버레이 그리드로 이동.
- 앱 실행 시 타이머 창을 열고, 설정에서 스크롤 기준 숫자가 보이도록 수정.
- Mac 기본 알림음을 사용할지 선택하는 설정 추가.

## 1.0.1 — 2026-08-28

### English

- Changed the menu-bar right click to start, pause, or resume the timer directly.
- Made the compact timer an independent borderless window with its original custom close control.
- Added a reset control and an opt-in setting for recording elapsed cancelled time in analytics.
- Added a configurable `work` default label, resilient label matching, keyboard autocomplete navigation, and reliable label-focus cleanup.
- Refined the compact light-mode timer UI, including its `#F5F5F5` background and smaller playback control.

### 한국어

- 메뉴바 우클릭으로 메뉴를 열지 않고 타이머를 바로 시작·일시정지·재시작하도록 변경.
- 기존의 단일 닫기 버튼을 유지한 독립형 borderless 타이머 창으로 변경.
- 초기화 버튼과 초기화 시점의 경과 시간을 분석에 기록할지 선택하는 설정 추가.
- 설정 가능한 기본값 `work`, 유연한 라벨 매칭, 키보드 자동완성 선택, 라벨 포커스 정리 동작 추가.
- `#F5F5F5` 라이트 배경과 더 작은 재생 컨트롤을 포함해 컴팩트 타이머 UI 개선.

## 1.0.0 — 2026-08-27

### English

- Initial native macOS menu-bar release.
- Added deadline-based timer, pause/resume, restart recovery, presets, and scroll adjustment.
- Added retained activity labels and frequency-ranked autocomplete.
- Added today progress dots and local Analytics/Settings workspace.
- Added login-item registration, silent native notifications, appearance settings, and English/Korean localization.

### 한국어

- 네이티브 macOS 메뉴바 앱 최초 릴리스.
- 종료 시각 기반 타이머, 일시정지·재시작, 앱 재실행 복구, 프리셋, 스크롤 조절 추가.
- 유지되는 활동 라벨과 사용 빈도순 자동완성 추가.
- 오늘의 진행 도트와 로컬 분석·설정 창 추가.
- 로그인 항목, 소리 없는 네이티브 알림, 화면 모드, 영어·한국어 현지화 추가.
