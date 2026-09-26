import SwiftUI

struct MediaFilterPicker: View {
    @Binding
    var selection:
        ConversationMediaFilter

    var body: some View {
        Picker(
            "Shared content",
            selection: $selection
        ) {
            ForEach(
                ConversationMediaFilter
                    .allCases
            ) { filter in
                Text(filter.title)
                    .tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }
}
