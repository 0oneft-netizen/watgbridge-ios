import Foundation
import NaturalLanguage

enum UltraLanguagePolicy {
    static func detected(_ text: String) -> String? {
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard letters.count >= 4 else { return nil }
        let recognizer = NLLanguageRecognizer(); recognizer.processString(text)
        guard let language = recognizer.dominantLanguage, recognizer.languageHypotheses(withMaximum: 1)[language, default: 0] >= 0.7 else { return nil }
        let code = language.rawValue
        return ["he","en","ar","ru","fr","es","de","pt","uk"].contains(code) ? code : nil
    }
    static func skipHebrew(_ text: String, target: String) -> Bool {
        guard target == "he" else { return false }
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard !letters.isEmpty else { return true }
        let hebrew = letters.filter { (0x0590...0x05FF).contains($0.value) }.count
        return Double(hebrew) / Double(letters.count) >= 0.8
    }
}
