# Workspace addon — proof of concept 0.1

This is a source package, not a compiled or signed IPA. No device test has been
performed. Apple SDK compilation is performed by the included GitHub Actions
workflow; installation and runtime validation must follow.

## Included

- A separate UIKit test app and an arm64 injected addon using the same controller.
- Existing `/auth/login` and `/auth/me` authentication against the fixed HTTPS
  origin `https://5jjltkwg.tail256e07.ts.net`.
- Token storage in this bundle's Keychain; passwords are not saved.
- Authenticated `/conversations` and `/messages-v2` reads. Message requests carry
  both account_id and chat_jid. Tenant identity comes only from server auth.
- List, text-message preview, pull-to-refresh, and explicit logout.
- Native host button in supported WhatsApp releases. No private method hooks.
- A separate, narrowly guarded packaging utility, blocked for original bundle IDs
  by default, and tests of binary byte preservation.

## Not included or proven

Native WhatsApp chat database integration, message sending, media playback,
customer group editing, multiple WhatsApp identities in the original UI,
app-lock integration, voice/video calling, background sync, APNs/Web Push,
camera capture, and automated app replacement. Existing server data is displayed
in our own screen, not imported into WhatsApp's private database. This addon
does not grant or alter WhatsApp entitlements. The preview and addon use separate
Keychain accounts because their bundle IDs differ; log in separately in each.

The source uses the server contract from the reviewed October 6 code. A changed
server response must be inspected and adapted rather than guessed.

## Build from SSH

Unzip this package under `/root`, then:

```
python3 /root/watusi-workspace-poc/install_build.py --push
```

This installs `tools/watusi-workspace-poc` and one manual workflow in the existing
iOS repository, commits only those new paths, and pushes main. Existing main
push workflows may also build the unchanged native app. No server service restart,
database migration, source replacement, or third-party IPA upload occurs.

The workflow builds `WorkspacePreview-unsigned.ipa`, `WBGWorkspace.dylib`, and
SHA256SUMS. Sign only the preview IPA through your existing Sideloadly setup first.
Connect Tailscale. Verify login, own conversations, two account IDs, message reads,
logout, a second app user, and reopening. A successful compilation alone does not
prove any of these runtime properties.

If GitHub workflow dispatch returns not-found immediately after pushing, retry:

```
gh workflow run watusi-workspace-poc.yml --repo 0oneft-netizen/watgbridge-ios --ref main
```

## Later integration, after the preview works

Download the matching `WhatsApp Business Duplicate` IPA from the maintainer's
No Jailbreak section; version 26.38.74 is the only currently enabled host version.
The provided original bundle `net.whatsapp.WhatsAppSMB` is deliberately blocked
by default because installing it could replace the installed business app.
Keep both the maintainer IPA and the built addon local; do not upload them to
the public source repository.

```
python3 package_ipa.py WhatsAppBusiness-Duplicate.ipa WBGWorkspace.dylib WorkspaceBusiness-unsigned.ipa
```

This adds one library load command only if unused header padding exists. It will
refuse encrypted binaries, occupied padding, unsupported architectures/versions,
duplicate addon entries, and existing output paths. The output must be re-signed;
the packaging utility does not sign, bypass signing, or change bundle IDs.
Do not change the bundle identifier manually to imitate a Duplicate build.

## Compatibility and updates

The injected launcher enables only for version 26.38.74 and the explicitly listed
Messenger/Business original or Watusi duplicate IDs. An untested version gets no
launcher, instead of arbitrary private hooks. The preview is independent of the
host version. Server-side data can change independently of the IPA. Executable
addon changes require an Apple SDK build, re-packaging, signing, and installation.
No perpetual WhatsApp compatibility or silent self-update is promised.

## Validation completed locally

Packaging tests and actual uploaded executable header-padding inspection. UIKit
compilation, signing, iOS 27.0.1 behavior, native addon load, and server login are
not validated locally. Review the GitHub output and device behavior before use.
