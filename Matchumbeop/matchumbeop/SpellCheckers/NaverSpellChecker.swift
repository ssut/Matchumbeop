import Foundation
import Alamofire
import SwiftSoup

class NaverSpellChecker : SpellChecker {
    private let SPELLER_PROVIDER_URL = "https://m.search.naver.com/search.naver?query=%EB%A7%9E%EC%B6%A4%EB%B2%95%EA%B2%80%EC%82%AC%EA%B8%B0"
    private let PASSPORT_KEY_REGEX = "SpellerProxy\\?passportKey=([a-zA-Z0-9]+)"
    private let SPELLER_API_URL_BASE = "https://m.search.naver.com/p/csearch/ocontent/util/SpellerProxy?passportKey="
    
    private var spellerApiUrl: String?
    private var session: Session
    
    init() {
        session = Session()
        
        Task {
            await updateSpellerApiUrl()
        }
    }
    
    private func updateSpellerApiUrl() async {
        do {
            let html = try await fetchHtml(from: SPELLER_PROVIDER_URL)
            let passportKey = try extractPassportKey(from: html)
            spellerApiUrl = SPELLER_API_URL_BASE + passportKey + "&color_blindness=0&q="
        } catch {
            print(error)
        }
    }
    
    private func fetchHtml(from url: String) async throws -> String {
        let response = try await AF.request(url).serializingString().value
        return response
    }
    
    private func extractPassportKey(from html: String) throws -> String {
        let document = try SwiftSoup.parse(html)
        let scripts = try document.select("script").array()
        
        for script in scripts {
            let content = try script.html()
            if content.contains("SpellerProxy?passportKey=") {
                let regex = try NSRegularExpression(pattern: PASSPORT_KEY_REGEX)
                if let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) {
                    if let range = Range(match.range(at: 1), in: content) {
                        return String(content[range])
                    }
                }
            }
        }
        throw NSError(domain: "com.spellchecker.error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Passport key not found"])
    }
    
    func correctText(_ text: String, eol: String) async throws -> SpellerApiResponse {
        guard let apiUrl = spellerApiUrl else {
            throw NSError(domain: "com.spellchecker.error", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speller API URL not set"])
        }
        
        let url = apiUrl + text.addingPercentEncoding(withAllowedCharacters: .afURLQueryAllowed)!
        
        do {
            var spellerResponse = try await fetchSpellerResponse(from: url)
            if let error = spellerResponse.message.error, !error.isEmpty {
                await updateSpellerApiUrl()
                spellerResponse = try await correctText(text, eol: eol)
            }
            
            return spellerResponse
        } catch {
            print(error)
            throw error
        }
    }
    
    private func fetchSpellerResponse(from url: String) async throws -> SpellerApiResponse {
        let response = try await AF.request(url).serializingDecodable(SpellerApiResponse.self).value
        return response
    }
}

struct SpellerApiResponse: Codable {
    let message: Message
}

struct Message: Codable {
    let result: Result
    let error: String?
}

struct Result: Codable {
    let html: String
    let errata_count: Int
    let origin_html: String
    let notag_html: String
}
