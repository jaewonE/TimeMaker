#!/bin/zsh

set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
SOURCE_APP="${PROJECT_ROOT}/dist/TimeMaker.app"
DESTINATION_APP="/Applications/TimeMaker.app"

"${PROJECT_ROOT}/scripts/build_app.sh"

if [[ -d "${DESTINATION_APP}" ]]; then
    osascript -e 'tell application "TimeMaker" to quit' >/dev/null 2>&1 || true
    sleep 1
    rm -rf "${DESTINATION_APP}"
fi

ditto "${SOURCE_APP}" "${DESTINATION_APP}"
xattr -dr com.apple.quarantine "${DESTINATION_APP}" 2>/dev/null || true
open "${DESTINATION_APP}"

print "Installed and opened ${DESTINATION_APP}"
