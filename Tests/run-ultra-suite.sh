#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_SUITE_TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TASK_SUITE_TEST_DIR"' EXIT
swiftc -swift-version 5 -parse-as-library -target "$(uname -m)-apple-macosx13.0" \
  WhatsAppBridge/Models/Message.swift \
  WhatsAppBridge/Models/Conversation.swift \
  WhatsAppBridge/Services/MessageMediaPolicy.swift \
  WhatsAppBridge/Services/UltraLanguagePolicy.swift \
  WhatsAppBridge/Services/UltraSuite.swift \
  Tests/UltraSuiteContracts.swift \
  -o "$TASK_SUITE_TEST_DIR/ultra-suite-tests"
"$TASK_SUITE_TEST_DIR/ultra-suite-tests"
