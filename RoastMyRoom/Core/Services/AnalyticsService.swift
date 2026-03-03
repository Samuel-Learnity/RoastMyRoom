import FirebaseAnalytics

protocol AnalyticsServiceProtocol: Sendable {
    func track(_ event: AnalyticsEvent)
    func setUserProperty(_ value: String?, forName name: String)
}

final class AnalyticsService: AnalyticsServiceProtocol {
    func track(_ event: AnalyticsEvent) {
        Analytics.logEvent(event.name, parameters: event.parameters)
    }

    func setUserProperty(_ value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
}
