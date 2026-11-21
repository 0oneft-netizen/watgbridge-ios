#!/bin/bash
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
swiftc -swift-version 5 -parse-as-library \
  "$root/WhatsAppBridge/Models/Conversation.swift" \
  "$root/WhatsAppBridge/Models/Message.swift" \
  "$root/WhatsAppBridge/Models/MessageSyncBatch.swift" \
  "$root/WhatsAppBridge/Services/MessageTimelineMerge.swift" \
  "$root/WhatsAppBridge/Services/FastChatArchive.swift" \
  "$root/WhatsAppBridge/Services/NewChatPhone.swift" \
  "$root/tools/FastChatNativeTests.swift" \
  -o "$work/fast-chat-tests"
"$work/fast-chat-tests"
