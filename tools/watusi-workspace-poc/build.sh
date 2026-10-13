#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p out/WorkspacePreview.app
sdk="$(xcrun --sdk iphoneos --show-sdk-path)"
sim_sdk="$(xcrun --sdk iphonesimulator --show-sdk-path)"
# Compile against both real Apple SDKs. No private frameworks or runtime hooks.
xcrun clang -fobjc-arc -fmodules -fsyntax-only -Wall -Wextra \
  -Wno-unused-parameter -target arm64-apple-ios15.1-simulator \
  -isysroot "$sim_sdk" src/Workspace.m src/Addon.m src/Preview.m
xcrun clang -fobjc-arc -fmodules -O2 -target arm64-apple-ios15.1 \
  -isysroot "$sdk" -framework UIKit -framework Foundation -framework Security \
  src/Workspace.m src/Preview.m -o out/WorkspacePreview.app/WorkspacePreview
xcrun clang -fobjc-arc -fmodules -O2 -dynamiclib -target arm64-apple-ios15.1 \
  -isysroot "$sdk" -framework UIKit -framework Foundation -framework Security \
  -install_name '@executable_path/WBGWorkspace.dylib' \
  src/Workspace.m src/Addon.m -o out/WBGWorkspace.dylib
python3 - <<'PY'
import plistlib
from pathlib import Path
p = Path('out/WorkspacePreview.app/Info.plist')
p.write_bytes(plistlib.dumps({
 'CFBundleIdentifier':'com.watgbridge.workspace.preview',
 'CFBundleExecutable':'WorkspacePreview', 'CFBundleName':'Workspace Preview',
 'CFBundleDisplayName':'Workspace Test', 'CFBundlePackageType':'APPL',
 'CFBundleShortVersionString':'0.1.0','CFBundleVersion':'1',
 'MinimumOSVersion':'15.1','LSRequiresIPhoneOS':True,
 'UIDeviceFamily':[1], 'UILaunchScreen':{},
 'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait']
}))
PY
mkdir -p out/Payload
cp -R out/WorkspacePreview.app out/Payload/
(cd out && ditto -c -k --keepParent Payload WorkspacePreview-unsigned.ipa)
shasum -a 256 out/WBGWorkspace.dylib out/WorkspacePreview-unsigned.ipa > out/SHA256SUMS
