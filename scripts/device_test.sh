#!/usr/bin/env bash
# Device integration-test helper.
#   scripts/device_test.sh push-model <local-model-file>   (once per model)
#   scripts/device_test.sh run [test-file]                 (default: all_tests)
# The pushed model lives in /data/local/tmp, which `flutter test`'s uninstall
# does not touch, so tests install it from there instead of downloading.
set -euo pipefail
DIR=/data/local/tmp/uniun_test

keep_awake() {
  adb shell svc power stayon usb
  adb shell input keyevent KEYCODE_WAKEUP
  adb shell wm dismiss-keyguard
}

case "${1:-}" in
  push-model)
    adb shell mkdir -p "$DIR"
    adb push "$2" "$DIR/"
    ;;
  run)
    keep_awake
    trap 'adb shell svc power stayon false' EXIT
    flutter test "${2:-integration_test/all_tests.dart}"
    ;;
  *)
    echo "usage: $0 push-model <file> | run [test-file]" >&2
    exit 1
    ;;
esac
