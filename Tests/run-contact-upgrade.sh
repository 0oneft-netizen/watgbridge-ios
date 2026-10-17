#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_CONTACT_TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TASK_CONTACT_TEST_DIR"' EXIT
swiftc -swift-version 5 -parse-as-library -target "$(uname -m)-apple-macosx13.0" \
  WhatsAppBridge/Models/Message.swift \
  WhatsAppBridge/Models/Conversation.swift \
  WhatsAppBridge/Services/ContactUpgrade.swift \
  Tests/ContactUpgradeContracts.swift \
  -o "$TASK_CONTACT_TEST_DIR/contact-upgrade-tests"
"$TASK_CONTACT_TEST_DIR/contact-upgrade-tests"
