import Foundation

protocol Analytics {
    func send(_ event: AnalyticsEvent, forceSend: Bool)
}

extension Analytics {
    func send(_ event: AnalyticsEvent) {
        self.send(event, forceSend: false)
    }

    func send(_ events: AnalyticsEvent..., forceSend: Bool = false) {
        events.forEach { event in
            self.send(event, forceSend: forceSend)
        }
    }
}

final class MatchumbeopAnalytics: Analytics {
    static let shared = MatchumbeopAnalytics()

    private let firebaseAnalyticsEngine: AnalyticsEngine

    private init() {
        self.firebaseAnalyticsEngine = FirebaseAnalyticsEngine()
    }

    func send(_ event: AnalyticsEvent, forceSend: Bool) {
        if event is MatchumbeopAnalyticsEvent {
            self.firebaseAnalyticsEngine.sendAnalyticsEvent(named: event.name, parameters: event.parameters, forceSend: forceSend)
        }
    }
}
