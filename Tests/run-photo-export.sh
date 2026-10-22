#!/bin/bash
set -euo pipefail
repo_root="$(cd -- "$(dirname -- "$0")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT
cp "$repo_root/Tests/photo-export-main.swift" "$test_dir/main.swift"
native_arch="$(uname -m)"
xcrun swiftc -target "$native_arch-apple-macosx13.0" \
  "$repo_root/WhatsAppBridge/Services/PhotoExportEncoder.swift" \
  "$test_dir/main.swift" -o "$test_dir/photo-export-tests"
"$test_dir/photo-export-tests"
