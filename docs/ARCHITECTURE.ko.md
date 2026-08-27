# TimeMaker 아키텍처

[English documentation](ARCHITECTURE.md)

## 실행 구조

TimeMaker는 다음 네이티브 macOS 프레임워크로 구성한 메뉴바 전용 앱(`LSUIElement`)입니다.

- `MenuBarController`: `NSStatusItem`, 실시간 텍스트, 좌클릭 패널, 우클릭 계층형 메뉴를 관리합니다.
- `MainPanelController`: 상태 항목 아래에 붙는 borderless `NSPanel`을 관리합니다.
- `WorkspaceWindowController`: 분석·설정이 공유하는 `NSWindow`와 사이드바 이동을 관리합니다.
- 세 화면은 SwiftUI로 그리고, 메뉴바와 윈도우 동작은 AppKit으로 제어합니다.

## 타이머 상태 흐름

`TimerStore`가 정지·실행·일시정지 상태의 단일 진실 공급원입니다. 실행 중에는 카운터를 단순 차감하지 않고 종료 시각을 권위 값으로 저장합니다. 250ms UI ticker는 종료 시각으로부터 표시할 정수 초를 계산합니다. 이 방식은 시간 오차를 막고 화면 잠자기, 시스템 잠자기, 프로세스 재실행 뒤에도 타이머를 복구합니다.

저장 상태에는 다음 값이 포함됩니다.

- 단계와 설정 시간
- 일시정지 세션의 남은 시간
- 실행 세션의 종료 시각
- 활동 라벨과 최초 시작 시각
- 일시정지 전까지 누적한 활성 시간

완료 시 세션을 정확히 한 번 기록하고, 설정에 따라 소리 없는 네이티브 알림을 보냅니다. 카운트다운은 설정 시간으로 돌아가지만 마지막 라벨은 유지합니다.

## 영속화

`HistoryStore`는 Application Support에 버전이 명시된 JSON을 원자적으로 교체 저장합니다. 완료 세션과 정규화한 라벨 사용 횟수가 들어갑니다. 환경설정과 활성 타이머 복구 상태는 `UserDefaults`를 사용합니다.

자동완성은 대소문자와 발음 구별 기호를 무시한 부분 문자열 매칭을 사용합니다. 사용 횟수, 최근 사용 시각, 라벨 순으로 정렬합니다.

## 분석

`AnalyticsBuilder`는 저장 세션을 입력받는 순수 `TimeMakerCore` 변환입니다. 최근 7일의 일별 합계, 활동별 합계, 활동일 평균, 현재 연속 기록을 계산합니다. `AnalyticsView`는 Swift Charts와 네이티브 요약 카드로 결과를 표시합니다.

## 시스템 연동

- `SMAppService.mainApp`으로 로그인 항목을 등록하거나 해제합니다.
- `UNUserNotificationCenter`에는 배너 권한만 요청하고 알림음은 지정하지 않습니다.
- `NSAppearance`로 시스템, Light, Dark 선택을 모든 창에 적용합니다.

## 패키징

Swift Package Manager로 실행 파일을 빌드합니다. `scripts/build_app.sh`는 표준 `.app` 구조를 만들고 현지화 파일과 `.icns`를 복사한 뒤 ad-hoc 서명과 번들 검증을 수행합니다. `scripts/package_release.sh`는 GitHub Release에 올릴 버전 ZIP과 SHA-256 파일을 생성합니다.
