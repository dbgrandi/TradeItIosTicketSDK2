import UIKit

class TradeItPresenter {
    static let DEFAULT_CURRENCY_CODE = "USD"
    static let MISSING_DATA_PLACEHOLDER = "N/A"

    static func stockChangeColor(_ value: Double?) -> UIColor {
        guard let value = value else { return TradeItSDK.theme.textColor }
        if value < 0.0 {
            return UIColor(named: "negative")!
        } else if value > 0.0 {
            return UIColor(named: "positive")!
        } else {
            return UIColor(named: "tertiaryText")!
        }
    }
}
