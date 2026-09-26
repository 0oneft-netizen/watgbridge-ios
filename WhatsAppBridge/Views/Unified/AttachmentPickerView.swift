import SwiftUI

struct AttachmentPickerView: View {
    let onSelect:
        (ComposerAttachment) -> Void

    var body: some View {
        HStack(spacing: 24) {
            ForEach(
                ComposerAttachment.allCases
            ) { item in
                Button {
                    AppHaptics.selection()
                    onSelect(item)
                } label: {
                    VStack(spacing: 7) {
                        ZStack {
                            Circle()
                                .fill(
                                    ChatDesign
                                        .subtleFill
                                )

                            Image(
                                systemName:
                                    item.systemImage
                            )
                            .font(.title3)
                            .foregroundStyle(
                                ChatDesign.accent
                            )
                        }
                        .frame(
                            width: 48,
                            height: 48
                        )

                        Text(item.title)
                            .font(.caption)
                            .foregroundStyle(
                                .primary
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
