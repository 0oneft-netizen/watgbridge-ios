import SwiftUI
import UIKit
import Combine

// A separate scene window sits above sheets, media viewers and navigation.
// It also replaces sensitive content before iOS captures an app-switcher snapshot.
struct AppLockWindowBridge: UIViewRepresentable {
    func makeUIView(context: Context) -> AppLockAttachmentView { AppLockAttachmentView() }
    func updateUIView(_ uiView: AppLockAttachmentView, context: Context) {}
}

final class AppLockAttachmentView: UIView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let window { AppLockWindow.shared.attach(to: window) }
    }
}

@MainActor
private final class AppLockWindow {
    static let shared = AppLockWindow()
    private weak var contentWindow: UIWindow?
    private var shield: UIWindow?
    private var subscriptions = Set<AnyCancellable>()
    private let lock = AppLockStore.shared
    private init() {
        lock.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.update() }
        }.store(in: &subscriptions)
        NotificationCenter.default.publisher(for: UIScene.willDeactivateNotification)
            .sink { [weak self] event in self?.activity(event, active: false) }
            .store(in: &subscriptions)
        NotificationCenter.default.publisher(for: UIScene.didActivateNotification)
            .sink { [weak self] event in self?.activity(event, active: true) }
            .store(in: &subscriptions)
    }
    func attach(to window: UIWindow) {
        guard let scene = window.windowScene else { return }
        if shield?.windowScene !== scene {
            shield?.isHidden = true
            let cover = UIWindow(windowScene: scene)
            cover.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.alert.rawValue + 1)
            cover.rootViewController = UIHostingController(rootView: AppUnlockView())
            cover.rootViewController?.view.accessibilityViewIsModal = true
            cover.backgroundColor = .systemBackground
            shield = cover
        }
        contentWindow = window
        lock.activity(scene.activationState == .foregroundActive)
        update()
    }
    private func activity(_ event: Notification, active: Bool) {
        guard let scene = event.object as? UIWindowScene, scene === contentWindow?.windowScene else { return }
        lock.activity(active)
        update()
    }
    private func update() {
        guard let shield else { return }
        if lock.enabled && lock.locked {
            shield.isHidden = false
            if lock.foreground && !shield.isKeyWindow { shield.makeKeyAndVisible() }
        } else {
            let wasKey = shield.isKeyWindow
            shield.isHidden = true
            if wasKey { contentWindow?.makeKey() }
        }
    }
}
