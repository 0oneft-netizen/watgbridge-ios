import SwiftUI

struct UltraVoiceSettingsView: View {
    @State private var selected = UltraVoiceSettings.selected
    @StateObject private var preview = UltraVoicePreview()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Label("ULTRA-SAP Voice", systemImage: "waveform")
                        .font(.title2.weight(.semibold))
                    Text("בחר אפקט לקול שלך בשיחות קול ווידאו. הבחירה נשמרת לחשבון הנוכחי ומופעלת בתחילת השיחה הבאה.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }.padding(.vertical, 8)
            }
            Section {
                ForEach(UltraVoicePreset.allCases) { preset in
                    HStack(spacing: 12) {
                        Button {
                            selected = preset; UltraVoiceSettings.selected = preset
                            if preview.hasSample { preview.play(preset) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selected == preset ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selected == preset ? ChatDesign.accent : Color.secondary)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(preset.title).foregroundStyle(.primary)
                                    Text(preset.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                            }.contentShape(Rectangle())
                        }.buttonStyle(.plain)
                        Button { preview.play(preset) } label: {
                            Image(systemName: "play.circle.fill").font(.title2)
                        }
                        .buttonStyle(.borderless)
                        .disabled(!preview.hasSample || preview.recording || preview.preparing)
                        .accessibilityLabel("השמעת \(preset.title)")
                    }.padding(.vertical, 4)
                }
            } header: { Text("הקול בשיחה") } footer: {
                Text("אלה אפקטים לקול שלך. איכות התוצאה תלויה במיקרופון ובחיבור; אפשר תמיד לבחור טבעי.")
            }
            Section("תצוגה מקדימה עם הקול שלך") {
                Button { preview.record() } label: {
                    Label(preview.preparing ? "מכין מיקרופון…" : preview.recording ? "מקליט — אמור משפט קצר…" : "הקלט דוגמה של 3 שניות", systemImage: preview.recording ? "record.circle.fill" : "mic.fill")
                }.disabled(preview.recording || preview.preparing)
                if preview.recording || preview.preparing { ProgressView() }
                if preview.hasSample {
                    Button { preview.play(selected) } label: { Label("השמע את הקול שנבחר", systemImage: "play.fill") }
                    Button { preview.play(.natural) } label: { Label("השווה לקול המקורי", systemImage: "waveform") }
                }
                if preview.playing || preview.recording || preview.preparing {
                    Button("עצירה", role: .destructive) { preview.stop(clear: false) }
                }
                if let error = preview.error { Text(error).foregroundStyle(.red).font(.footnote) }
                Text("הדוגמה נשארת בזיכרון האייפון בלבד ונמחקת ביציאה מהמסך. לא מתבצעת שיחה ללקוח בזמן הבדיקה.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("אפקטים לקול")
        .navigationBarTitleDisplayMode(.inline)
        .tint(ChatDesign.accent)
        .onDisappear { preview.stop(clear: true) }
        .onChange(of: scenePhase) { _, phase in if phase != .active { preview.stop(clear: true) } }
    }
}
