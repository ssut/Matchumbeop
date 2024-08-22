import Foundation
import Defaults

protocol SpellChecker {
    func correctText(_ text: String, eol: String) async throws -> SpellerApiResponse
}

