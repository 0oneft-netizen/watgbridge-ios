#!/bin/bash
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
swiftc -swift-version 5 -parse-as-library \
  "$root/WhatsAppBridge/Services/ExistingSessionReconnectPolicy.swift" \
  "$root/WhatsAppBridge/Services/ExistingSessionReconnectAPI.swift" \
  "$root/tools/ExistingSessionReconnectTests.swift" \
  -o "$work/reconnect-tests"
"$work/reconnect-tests"
