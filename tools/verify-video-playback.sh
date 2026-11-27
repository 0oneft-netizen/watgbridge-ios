#!/bin/bash
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
swiftc -swift-version 5 -parse-as-library \
 "$root/WhatsAppBridge/Services/ManagedVideoPlayback.swift" \
 "$root/tools/VideoPlaybackLifecycleTests.swift" -o "$work/video-playback-tests"
"$work/video-playback-tests"
