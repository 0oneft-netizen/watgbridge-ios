#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TASK_TEST_DIR"' EXIT
swiftc -swift-version 5 -parse-as-library \
  WhatsAppBridge/Models/Message.swift \
  WhatsAppBridge/Models/Conversation.swift \
  WhatsAppBridge/Models/MessageSyncBatch.swift \
  WhatsAppBridge/Services/MessageTimelineMerge.swift \
  WhatsAppBridge/Services/ChatSnapshotStore.swift \
  WhatsAppBridge/Services/BusinessChatFilter.swift \
  Tests/BusinessRefreshRegression.swift \
  -o "$TASK_TEST_DIR/business-refresh-tests"
"$TASK_TEST_DIR/business-refresh-tests"
