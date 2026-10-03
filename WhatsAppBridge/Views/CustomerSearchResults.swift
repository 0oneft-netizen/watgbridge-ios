import SwiftUI

struct CustomerSearchResults: View {
    let query: String
    @State private var hits: [CustomerSearchHit] = []
    @State private var loading = false
    @State private var error: String?
    @State private var hasMore = false
    @State private var loadedQuery = ""
    @State private var generation = 0
    var body: some View {
        Section("הודעות מכל הצ׳אטים") {
            if loading { ProgressView("מחפש הודעות…") }
            if let error { Text(error).font(.caption).foregroundStyle(.secondary) }
            if !loading && error == nil && hits.isEmpty { Text("לא נמצאו הודעות תואמות").foregroundStyle(.secondary) }
            ForEach(hits) { hit in
                NavigationLink {
                    ChatView(conversation: hit.conversation, initialMessageID: hit.message.messageID)
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(hit.name).font(.headline)
                        searchHighlight(hit.message.text, query: query).font(.subheadline).lineLimit(3)
                        Text("\(hit.accountName.isEmpty ? (hit.message.accountID ?? "default") : hit.accountName) · \(Date(timeIntervalSince1970: Double(hit.message.createdAt)).formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if hasMore { Button("תוצאות נוספות") { Task { await load(more: true) } }.disabled(loading) }
        }
        .task(id: query) {
            generation += 1
            hits = []; hasMore = false; error = nil; loading = true; loadedQuery = query
            do { try await Task.sleep(for: .milliseconds(250)); try Task.checkCancellation(); await load(more: false) }
            catch { }
        }
    }
    @MainActor private func load(more: Bool) async {
        let expected = query
        let token = generation
        loading = true; defer { if token == generation { loading = false } }
        do {
            let result = try await CustomerFeaturesAPI.shared.search(expected, before: more ? hits.last?.id : nil)
            try Task.checkCancellation()
            guard token == generation else { return }
            if more && loadedQuery != expected { return }
            if more { let ids = Set(hits.map(\.id)); hits.append(contentsOf: result.filter { !ids.contains($0.id) }) }
            else { hits = result; loadedQuery = expected }
            hasMore = result.count == 100; error = nil
        } catch is CancellationError { }
        catch { if token == generation { self.error = error.localizedDescription } }
    }
}
func searchHighlight(_ value: String, query: String) -> Text {
    guard !query.isEmpty else { return Text(value) }
    var remaining = value[...]
    var result = Text("")
    while let range = remaining.range(of: query, options: .caseInsensitive) {
        result = result + Text(String(remaining[..<range.lowerBound])) + Text(String(remaining[range])).bold().foregroundColor(.accentColor)
        remaining = remaining[range.upperBound...]
    }
    return result + Text(String(remaining))
}

func matchesCustomerPhone(_ conversation: Conversation, query: String) -> Bool {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, trimmed.allSatisfy({ $0.isNumber || $0 == "+" || $0 == "-" || $0 == " " }) else { return false }
    guard !conversation.jid.hasSuffix("@g.us") else { return false }
    let digits = trimmed.filter(\.isNumber)
    guard !digits.isEmpty else { return false }
    let phone = ChatIdentity.customerPhone(conversation: conversation).filter(\.isNumber)
    return digits.count == 4 ? phone.hasSuffix(digits) : phone.contains(digits)
}
