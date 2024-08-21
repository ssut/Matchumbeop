import Foundation

extension String {
    var containsWhitespace: Bool {
        self.rangeOfCharacter(from: .whitespacesAndNewlines) != nil
    }

    func trimmed() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func condenseWhitespace() -> String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
}
