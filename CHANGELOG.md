# Changelog

## Unreleased

### English

- Removed the standalone Analytics toolbar icon while retaining Analytics in the More menu.
- Changed the accent palette from soft green to a similarly light lavender purple.
- Added a default-off setting that allows scroll adjustment for the current running or paused timer.

### 한국어

- 단독 분석 도구 막대 아이콘을 제거하고 더보기 메뉴의 분석 항목은 유지했습니다.
- 포인트 색상을 연한 초록색에서 비슷한 밝기의 연보라색으로 변경했습니다.
- 실행·일시정지 중인 현재 타이머를 스크롤로 조정하는 기본값 꺼짐 설정을 추가했습니다.

## 1.0.4 — 2026-08-28

### English

- Restored the separate timer-increment setting, so an accepted scroll changes the chosen number of minutes or seconds again.
- Replaced the scroll-distance stepper with a discrete horizontal sensitivity slider: 0.5×, 1×, 2×, 3×, 4×, or 5× (default 1×); minutes apply an additional 2× sensitivity.
- Changed the optional completion sound to the built-in `Glass.aiff` chime.

### 한국어

- 인식된 스크롤마다 타이머 숫자를 몇 칸 바꿀지 정하는 별도 스크롤 단위 설정을 복원했습니다.
- 스크롤 거리를 0.5×, 1×, 2×, 3×, 4×, 5× 중 하나만 고르는 이산 가로 감도 슬라이더로 변경했습니다. 기본값은 1×이며 분에는 2배의 감도가 추가로 적용됩니다.
- 선택 가능한 완료음을 내장 `Glass.aiff` 차임으로 변경했습니다.

## 1.0.3 — 2026-08-28

### English

- Corrected scroll behavior so each accepted movement changes the timer by one unit; minutes now require 4× and seconds 2× the base scroll distance.
- Restored compact spacing between the timer and playback control, and resized the timer panel to match.
- Made the optional completion sound play the Mac system alert sound directly.
- Opened the timer panel when a completion notification is clicked.
- Added confirmed preset-period clearing for completed timer records: 1 day, 3 days, 1 week, 1/3/6 months, 1 year, or all time.

### 한국어

- 시간 증감 폭 대신 스크롤 이동 거리에 감도를 적용하도록 수정했습니다. 한 번의 조절은 시간 1단위이며 분은 기준 거리의 4배, 초는 2배가 필요합니다.
- 타이머와 재생 버튼 사이 간격을 라벨과 타이머 간격에 맞추고 타이머 창 크기를 조정했습니다.
- 선택한 완료 알림 소리를 Mac 시스템 알림음으로 직접 재생하도록 수정했습니다.
- 완료 알림을 클릭하면 타이머 창이 열리도록 추가했습니다.
- 1일, 3일, 일주일, 1/3/6개월, 1년, 전체 프리셋 중 하나를 고르고 확인 후 완료 기록을 초기화하는 기능을 추가했습니다.

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
