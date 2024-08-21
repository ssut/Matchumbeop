import Foundation
import FirebaseAnalytics

protocol AnalyticsEngine: AnyObject {
    func sendAnalyticsEvent(named name: String, parameters: [String: Any]?, forceSend: Bool)
}

extension AnalyticsEngine {
    func sendAnalyticsEvent(named name: String) {
        self.sendAnalyticsEvent(named: name, parameters: nil, forceSend: false)
    }
}

final class FirebaseAnalyticsEngine: AnalyticsEngine {
    init() {}

    func sendAnalyticsEvent(named name: String, parameters: [String: Any]?, forceSend: Bool) {
        let processedName = self.processString(name)
        let processedParameters: [String: Any]? = {
            guard let parameters = parameters else {
                return nil
            }

            return Dictionary(uniqueKeysWithValues: parameters.map { (self.processString($0), $1) })
        }()

        FirebaseAnalytics.Analytics.logEvent(processedName, parameters: processedParameters)
        print("event logged: \(processedName) with parameters: \(String(describing: processedParameters))")
    }

    private func processString(_ string: String) -> String {
        guard string.containsWhitespace else {
            return string
        }

        return string
            .replacingOccurrences(of: " ", with: "_")
            .lowercased()
    }
}
