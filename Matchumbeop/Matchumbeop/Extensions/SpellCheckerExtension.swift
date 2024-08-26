import Foundation

let punctuationCharacters: CharacterSet = [".", ",", "!", "?", ":", ";", ")", "]", ">"]

extension SpellChecker {
    func correctLongText(_ text: String, eol: String) async throws -> [SpellerApiResponse] {
        let chunks = splitTextIntoChunks(text)
        var spellerResponses: [SpellerApiResponse] = []
        
        for chunk in chunks {
            let spellerResponse = try await correctText(chunk, eol: eol)
            spellerResponses.append(spellerResponse)
        }
        
        return spellerResponses
    }
    
    private func splitTextIntoChunks(_ text: String) -> [String] {
        var chunks: [String] = []
        var currentChunk = ""
        
        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        for word in words {
            let wordString = String(word)
            if currentChunk.count + wordString.count + 1 > 300 {
                chunks.append(currentChunk)
                currentChunk = wordString
            } else {
                if !currentChunk.isEmpty {
                    currentChunk.append(" ")
                }
                currentChunk.append(wordString)
            }
            
            if currentChunk.count >= 300 {
                chunks.append(currentChunk)
                currentChunk = ""
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        for (index, chunk) in chunks.enumerated() {
            if chunk.count > 300 {
                let hardCutChunks = chunk.chunked(into: 300)
                chunks.remove(at: index)
                chunks.insert(contentsOf: hardCutChunks, at: index)
            }
        }
        
        return chunks
    }
}
