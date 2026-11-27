import Foundation
@main struct ReplyQuoteTests {
    static func main() throws {
        func message(_ id: String, account: String = "a", chat: String = "chat", text: String = "hello", kind: String = "text", deleted: Bool = false, reply: String = "") throws -> Message {
            let json: [String: Any] = ["id": 1,"message_id": id,"account_id": account,"chat_jid": chat,"sender_jid": "sender","text": text,"type": kind,"from_me": true,"created_at": 1,"deleted_remote": deleted,"reply_to_id": reply]
            return try JSONDecoder().decode(Message.self, from: JSONSerialization.data(withJSONObject: json))
        }
        let reply = try message("reply", reply: "original")
        let original = try message("original", text: "על ההודעה הזאת")
        let local = ReplyQuotePreview.local(reply: reply, messages: [original])
        precondition(local?.label == "על ההודעה הזאת" && local?.navigable == true)
        let wrong = try message("original", account: "b")
        precondition(ReplyQuotePreview.local(reply: reply, messages: [wrong]) == nil)
        let wrongChat = try message("original", chat: "other")
        precondition(ReplyQuotePreview.local(reply: reply, messages: [wrongChat]) == nil)
        let deleted = try message("original", text: "secret", deleted: true)
        let removed = ReplyQuotePreview.local(reply: reply, messages: [deleted])
        precondition(removed?.available == false && removed?.text == "")
        let once = try message("original", text: "secret", kind: "view_once_image")
        precondition(ReplyQuotePreview.local(reply: reply, messages: [once])?.available == false)
        let audio = try message("original", text: "", kind: "voice")
        precondition(ReplyQuotePreview.local(reply: reply, messages: [audio])?.label == "הודעה קולית")
        print("PASS: quoted text, media label, same-account/chat routing and tombstone protection")
    }
}
