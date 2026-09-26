import SwiftUI

struct MediaFilterPicker: View {
    @Binding
    var selection:
        SharedContentFilter

    var body: some View {
        Picker(
            "Shared content",
            selection: $selection
        ) {
            ForEach(
                SharedContentFilter
                    .allCases
            ) { filter in
                Text(filter.title)
                    .tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }
}
