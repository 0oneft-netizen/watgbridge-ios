#!/bin/bash
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
swiftc -swift-version 5 -parse-as-library \
 "$root/WhatsAppBridge/Models/Message.swift" \
 "$root/WhatsAppBridge/Services/ReplyQuotePreview.swift" \
 "$root/tools/ReplyQuoteTests.swift" -o "$work/reply-quote-tests"
"$work/reply-quote-tests"
