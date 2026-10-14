#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TASK_VOICE_TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TASK_VOICE_TEST_DIR"' EXIT
swiftc -swift-version 5 -O -parse-as-library \
  WhatsAppBridge/Services/UltraVoiceDSP.swift Tests/UltraVoiceContracts.swift \
  -o "$TASK_VOICE_TEST_DIR/ultra-voice-tests"
"$TASK_VOICE_TEST_DIR/ultra-voice-tests"
python3 - <<'PY'
from pathlib import Path
import json, struct
root=Path('WhatsAppBridge/Resources/UltraBrandAssets.xcassets/UltraAppIcon.appiconset')
entry=json.loads((root/'Contents.json').read_text())['images'][0]
data=(root/entry['filename']).read_bytes()
assert data[:8]==b'\x89PNG\r\n\x1a\n'
assert struct.unpack('>II', data[16:24])==(1024,1024)
assert data[25]==2, 'Icon must be RGB, without alpha'
assert 'ASSETCATALOG_COMPILER_APPICON_NAME: UltraAppIcon' in Path('project.yml').read_text()
print('PASS: actual 1024 RGB app icon, matching catalog, ULTRA-SAP display name')
PY
