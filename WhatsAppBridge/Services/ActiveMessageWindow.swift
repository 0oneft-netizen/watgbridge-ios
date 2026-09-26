import Foundation

@MainActor
final class ActiveMessageWindow:
    ObservableObject {

    @Published
    private(set)
    var renderedCount =
        ChatPerformancePolicy
            .initialRenderedMessages

    func messages(
        from all:
            [Message]
    ) -> [Message] {

        ChatPerformancePolicy
            .renderWindow(
                all,
                count:
                    renderedCount
            )
    }

    func remaining(
        total: Int
    ) -> Int {

        max(
            0,
            total
            -
            min(
                renderedCount,
                ChatPerformancePolicy
                    .maximumRenderedMessages
            )
        )
    }

    func loadEarlier() {
        renderedCount =
            min(
                renderedCount
                +
                ChatPerformancePolicy
                    .pageIncrement,
                ChatPerformancePolicy
                    .maximumRenderedMessages
            )
    }

    func reset() {
        renderedCount =
            ChatPerformancePolicy
                .initialRenderedMessages
    }
}
