import SwiftUI
import UIKit

struct PushDiagnosticsView: View {
    @State private var status:
        PushStatus?

    var body: some View {
        Form {
            Section("Notification Permission") {
                LabeledContent(
                    "Authorization",
                    value:
                        status?.authorization ??
                        "Checking…"
                )

                LabeledContent(
                    "Alerts",
                    value:
                        status?.alerts ??
                        "Checking…"
                )

                LabeledContent(
                    "Sound",
                    value:
                        status?.sound ??
                        "Checking…"
                )

                LabeledContent(
                    "Badge",
                    value:
                        status?.badge ??
                        "Checking…"
                )
            }

            Section {
                Button(
                    "Register for Push Again"
                ) {
                    UIApplication.shared
                        .registerForRemoteNotifications()
                }

                Button(
                    "Open iPhone Notification Settings"
                ) {
                    guard
                        let url = URL(
                            string:
                                UIApplication
                                .openNotificationSettingsURLString
                        )
                    else {
                        return
                    }

                    UIApplication.shared
                        .open(url)
                }
            }

            Section {
                Text(
                    "Notifications while the app is fully terminated require Apple Push Notification service (APNs)."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
            }
        }
        .navigationTitle(
            "Push Diagnostics"
        )
        .task {
            status =
                await PushDiagnostics.status()
        }
    }
}
