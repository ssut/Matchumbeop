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
    
    func chunked(into size: Int) -> [String] {
        var chunks: [String] = []
        var startIndex = self.startIndex
        
        while startIndex < self.endIndex {
            let endIndex = self.index(startIndex, offsetBy: size, limitedBy: self.endIndex) ?? self.endIndex
            let chunk = String(self[startIndex..<endIndex])
            chunks.append(chunk)
            startIndex = endIndex
        }
        
        return chunks
    }
}
