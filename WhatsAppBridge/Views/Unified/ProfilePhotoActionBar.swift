import SwiftUI

struct ProfilePhotoActionBar: View {
    let save: () -> Void
    let share: () -> Void

    var body: some View {
        HStack(spacing: 34) {
            Button(
                action: save
            ) {
                VStack(spacing: 5) {
                    Image(
                        systemName:
                            "square.and.arrow.down"
                    )
                    .font(.title2)

                    Text("Save")
                        .font(.caption)
                }
            }

            Button(
                action: share
            ) {
                VStack(spacing: 5) {
                    Image(
                        systemName:
                            "square.and.arrow.up"
                    )
                    .font(.title2)

                    Text("Share")
                        .font(.caption)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
