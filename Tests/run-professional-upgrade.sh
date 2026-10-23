#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
professional_test_dir="$(mktemp -d)"
trap 'rm -rf -- "$professional_test_dir"' EXIT
xcrun swiftc -swift-version 5 -parse-as-library -O -target "$(uname -m)-apple-macosx13.0" \
  WhatsAppBridge/Services/UltraVoiceDSP.swift \
  WhatsAppBridge/Services/VoiceNoteEffectProcessor.swift \
  WhatsAppBridge/Services/IsraeliPhonePresentation.swift \
  WhatsAppBridge/Services/ChatIdentity.swift \
  WhatsAppBridge/Services/ChatDraftStore.swift \
  WhatsAppBridge/Services/UserWorkspace.swift \
  WhatsAppBridge/Services/ComposerTextPolicy.swift \
  WhatsAppBridge/Services/BusinessChatFilter.swift \
  WhatsAppBridge/Models/Conversation.swift \
  Tests/ProfessionalUpgradeTests.swift \
  -o "$professional_test_dir/professional-tests"
"$professional_test_dir/professional-tests"
