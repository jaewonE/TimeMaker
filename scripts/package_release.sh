#!/bin/zsh

set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
OUTPUT_ROOT="${TIMEMAKER_OUTPUT_DIR:-${PROJECT_ROOT}/dist}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${PROJECT_ROOT}/Info.plist")"
ARCHIVE_NAME="TimeMaker-${VERSION}-macOS-arm64.zip"
ARCHIVE_PATH="${OUTPUT_ROOT}/${ARCHIVE_NAME}"
CHECKSUM_PATH="${ARCHIVE_PATH}.sha256"

"${PROJECT_ROOT}/scripts/build_app.sh"

rm -f "${ARCHIVE_PATH}" "${CHECKSUM_PATH}"
ditto -c -k --sequesterRsrc --keepParent "${OUTPUT_ROOT}/TimeMaker.app" "${ARCHIVE_PATH}"
(
    cd "${OUTPUT_ROOT}"
    shasum -a 256 "${ARCHIVE_NAME}" > "${ARCHIVE_NAME}.sha256"
)

print "Packaged ${ARCHIVE_PATH}"
print "Checksum ${CHECKSUM_PATH}"
