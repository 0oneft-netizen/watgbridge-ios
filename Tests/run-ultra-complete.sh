#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_COMPLETE_TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TASK_COMPLETE_TEST_DIR"' EXIT
swiftc -swift-version 5 -parse-as-library -target "$(uname -m)-apple-macosx13.0" \
  WhatsAppBridge/Models/Message.swift \
  WhatsAppBridge/Models/Conversation.swift \
  WhatsAppBridge/Services/UltraLanguagePolicy.swift \
  WhatsAppBridge/Services/UltraComplete.swift \
  WhatsAppBridge/Services/UltraStorage.swift \
  WhatsAppBridge/Services/MediaCache.swift \
  Tests/UltraCompleteContracts.swift \
  -o "$TASK_COMPLETE_TEST_DIR/ultra-complete-tests"
"$TASK_COMPLETE_TEST_DIR/ultra-complete-tests"
