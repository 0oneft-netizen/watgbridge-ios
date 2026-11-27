import Foundation
import SwiftUI

@MainActor
@MainActor
struct ReplyQuoteCard: View {
    let message: Message
    let localPreview: ReplyQuotePreview?
    @State private var remote: ReplyQuotePreview?
    @State private var failed = false
    @State private var retry = 0
    @State private var scope = UserWorkspace.id
    private var preview: ReplyQuotePreview? { localPreview ?? remote }
    var body: some View {
        Button {
            if let preview, preview.available && preview.navigable {
                NotificationCenter.default.post(name: .replyQuoteNavigation, object: ReplyQuoteNavigation(
                    workspace: scope, account: preview.accountID, chat: preview.chatJID, messageID: preview.messageID))
            } else if preview == nil { retry += 1 }
        } label: {
            HStack(spacing: 7) {
                RoundedRectangle(cornerRadius: 2).fill(ChatDesign.accent).frame(width: 3)
                VStack(alignment: .leading, spacing: 3) {
                    Text(preview?.fromMe == true ? "בתגובה להודעה שלך" : "בתגובה להודעה")
                        .font(.caption2.weight(.semibold)).foregroundStyle(ChatDesign.accent)
                    Text(preview?.label ?? (failed ? "לחץ לטעינת ההודעה המצוטטת" : "טוען את ההודעה המצוטטת…"))
                        .font(.caption).foregroundStyle(.secondary).lineLimit(3)
                    if preview?.source == "quote" {
                        Text("הציטוט הגיע עם התשובה · המקור אינו בהיסטוריה השמורה")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                if preview?.navigable == true { Image(systemName: "arrow.up.backward").font(.caption2) }
            }.padding(7).background(Color.primary.opacity(0.055))
                .clipShape(RoundedRectangle(cornerRadius: 7))
        }.buttonStyle(.plain)
        .task(id: "\(scope)|\(message.id)|\(message.replyToID ?? "")|\(retry)") { await load() }
        .onReceive(NotificationCenter.default.publisher(for: .userAccessEnded)) { _ in remote = nil }
    }
    private func load() async {
        guard localPreview == nil, UserWorkspace.id == scope else { return }
        remote = nil; failed = false
        guard var parts = URLComponents(url: APIClient.shared.baseURL.appendingPathComponent("features/reply-preview"), resolvingAgainstBaseURL: false) else { failed = true; return }
        parts.queryItems = [URLQueryItem(name: "account_id", value: message.accountID ?? "default"),
                           URLQueryItem(name: "chat_jid", value: message.chatJID),
                           URLQueryItem(name: "message_id", value: message.messageID)]
        guard let url = parts.url else { failed = true; return }
        do {
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
            let (data, response) = try await URLSession.shared.data(for: request)
            try Task.checkCancellation()
            guard UserWorkspace.id == scope else { return }
            guard (response as? HTTPURLResponse)?.statusCode == 200, data.count <= 32768 else { throw URLError(.badServerResponse) }
            let result = try JSONDecoder().decode(ReplyQuotePreview.self, from: data)
            guard result.accountID == (message.accountID ?? "default"), result.chatJID == message.chatJID,
                  result.replyMessageID == message.messageID,
                  result.messageID == (message.replyToID ?? "") else { throw URLError(.badServerResponse) }
            remote = result
        } catch is CancellationError { }
        catch { if UserWorkspace.id == scope { failed = true } }
    }
}
