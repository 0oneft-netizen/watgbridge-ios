#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
task_check_dir="$(mktemp -d)"
trap 'rm -rf "$task_check_dir"' EXIT
xcrun swiftc -parse-as-library \
  WhatsAppBridge/Services/UltraVoiceDSP.swift \
  Tests/ContactCallDSPRepairTests.swift \
  -o "$task_check_dir/voice-check"
"$task_check_dir/voice-check"
