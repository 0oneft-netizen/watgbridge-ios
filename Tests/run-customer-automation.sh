#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_AUTOMATION_TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TASK_AUTOMATION_TEST_DIR"' EXIT
swiftc -swift-version 5 -parse-as-library -target "$(uname -m)-apple-macosx13.0" \
  WhatsAppBridge/Services/CustomerAutomation.swift \
  Tests/CustomerAutomationContracts.swift \
  -o "$TASK_AUTOMATION_TEST_DIR/automation-contracts"
"$TASK_AUTOMATION_TEST_DIR/automation-contracts" "$PWD/Tests/Fixtures"
