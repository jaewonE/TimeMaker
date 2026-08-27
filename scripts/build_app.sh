#!/bin/zsh

set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
OUTPUT_ROOT="${TIMEMAKER_OUTPUT_DIR:-${PROJECT_ROOT}/dist}"
APP_BUNDLE="${OUTPUT_ROOT}/TimeMaker.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
BUILD_ARCH="${TIMEMAKER_ARCH:-arm64}"

cd "${PROJECT_ROOT}"

swift build -c release --arch "${BUILD_ARCH}"
SWIFT_BIN_DIR="$(swift build -c release --arch "${BUILD_ARCH}" --show-bin-path)"

if [[ "${APP_BUNDLE}" != "${PROJECT_ROOT}/dist/TimeMaker.app" && \
      "${APP_BUNDLE}" != "${TIMEMAKER_OUTPUT_DIR:-}/TimeMaker.app" ]]; then
    print -u2 "Refusing unexpected app bundle path: ${APP_BUNDLE}"
    exit 1
fi

rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

ditto "${SWIFT_BIN_DIR}/TimeMaker" "${MACOS_DIR}/TimeMaker"
ditto "${PROJECT_ROOT}/Info.plist" "${CONTENTS_DIR}/Info.plist"
ditto "${PROJECT_ROOT}/assets/TimeMaker.icns" "${RESOURCES_DIR}/TimeMaker.icns"
ditto "${PROJECT_ROOT}/Sources/TimeMaker/Resources/en.lproj" "${RESOURCES_DIR}/en.lproj"
ditto "${PROJECT_ROOT}/Sources/TimeMaker/Resources/ko.lproj" "${RESOURCES_DIR}/ko.lproj"

chmod 755 "${MACOS_DIR}/TimeMaker"
plutil -lint "${CONTENTS_DIR}/Info.plist"
codesign --force --deep --sign - --identifier com.jaewone.timemaker "${APP_BUNDLE}"
codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE}"

print "Built ${APP_BUNDLE}"
