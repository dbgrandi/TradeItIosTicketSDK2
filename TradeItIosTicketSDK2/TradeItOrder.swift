public typealias TradeItPlaceOrderResult = TradeItPlaceTradeResult
public typealias TradeItPreviewOrderResult = TradeItPreviewTradeResult
public typealias TradeItPlaceOrderHandlers = (_ onSuccess: @escaping (TradeItPlaceOrderResult) -> Void,
                                              _ onFailure: @escaping (TradeItErrorResult) -> Void) -> Void

public class TradeItOrder {
    public var linkedBrokerAccount: TradeItLinkedBrokerAccount?
    public var symbol: String?
    public var action: TradeItOrderAction = TradeItOrderActionPresenter.DEFAULT
    public var type: TradeItOrderPriceType = TradeItOrderPriceTypePresenter.DEFAULT
    public var expiration: TradeItOrderExpiration = TradeItOrderExpirationPresenter.DEFAULT
    public var quantity: NSDecimalNumber?
    public var limitPrice: NSDecimalNumber?
    public var stopPrice: NSDecimalNumber?
    public var quoteLastPrice: NSDecimalNumber?

    public init() {}

    public init(linkedBrokerAccount: TradeItLinkedBrokerAccount, symbol: String) {
        self.linkedBrokerAccount = linkedBrokerAccount
        self.symbol = symbol
    }

    func requiresLimitPrice() -> Bool {
        return TradeItOrderPriceTypePresenter.LIMIT_TYPES.contains(type)
    }

    func requiresStopPrice() -> Bool {
        return TradeItOrderPriceTypePresenter.STOP_TYPES.contains(type)
    }

    func requiresExpiration() -> Bool {
        return TradeItOrderPriceTypePresenter.EXPIRATION_TYPES.contains(type)
    }

    func estimatedChange() -> NSDecimalNumber? {
        var optionalPrice: NSDecimalNumber?
        switch type {
        case .market: optionalPrice = quoteLastPrice
        case .limit: optionalPrice = limitPrice
        case .stopLimit: optionalPrice = limitPrice
        case .stopMarket: optionalPrice = stopPrice
        case .unknown: optionalPrice = 0.0
        }

        guard let quantity = quantity , quantity != NSDecimalNumber.notANumber else { return nil }
        guard let price = optionalPrice , price != NSDecimalNumber.notANumber else { return nil }

        return price.multiplying(by: quantity)
    }

    public func preview(onSuccess: @escaping (TradeItPreviewTradeResult, @escaping TradeItPlaceOrderHandlers) -> Void,
                           onFailure: @escaping (TradeItErrorResult) -> Void
        ) -> Void {
        guard let linkedBrokerAccount = linkedBrokerAccount else {
            return onFailure(TradeItErrorResult(title: "Linked Broker Account", message: "A linked broker account must be set before you preview an order.")) }
        guard let previewPresenter = TradeItOrderPreviewPresenter(order: self) else {
            return onFailure(TradeItErrorResult(title: "Preview failed", message: "There was a problem previewing your order. Please try again."))
        }

        linkedBrokerAccount.tradeService.previewTrade(previewPresenter.generateRequest(), withCompletionBlock: { result in
            switch result {
            case let previewOrderResult as TradeItPreviewOrderResult:
                onSuccess(previewOrderResult,
                          self.generatePlaceOrderCallback(tradeService: linkedBrokerAccount.tradeService,
                                                          previewOrderResult: previewOrderResult))
            case let errorResult as TradeItErrorResult:
                linkedBrokerAccount.linkedBroker.error = errorResult
                onFailure(errorResult)
            default: onFailure(TradeItErrorResult(title: "Preview failed", message: "There was a problem previewing your order. Please try again."))
            }
        })
    }

    func isValid() -> Bool {
        return validateQuantity()
            && validateOrderPriceType()
            && symbol != nil
            && linkedBrokerAccount != nil
    }

    // MARK: Private

    fileprivate func validateQuantity() -> Bool {
        guard let quantity = quantity else { return false }
        return isGreaterThanZero(quantity)
    }

    fileprivate func validateOrderPriceType() -> Bool {
        switch type {
        case .market: return true
        case .limit: return validateLimit()
        case .stopMarket: return validateStopMarket()
        case .stopLimit: return validateStopLimit()
        case .unknown: return false
        }
    }

    fileprivate func validateLimit() -> Bool {
        guard let limitPrice = limitPrice else { return false }
        return isGreaterThanZero(limitPrice)
    }

    fileprivate func validateStopMarket() -> Bool {
        guard let stopPrice = stopPrice else { return false }
        return isGreaterThanZero(stopPrice)
    }

    fileprivate func validateStopLimit() -> Bool {
        return validateLimit() && validateStopMarket()
    }

    fileprivate func isGreaterThanZero(_ value: NSDecimalNumber) -> Bool {
        return value.compare(NSDecimalNumber(value: 0 as Int)) == .orderedDescending
    }

    private func generatePlaceOrderCallback(tradeService: TradeItTradeService, previewOrderResult: TradeItPreviewOrderResult) -> TradeItPlaceOrderHandlers {
        return { onSuccess, onFailure in
            let placeOrderRequest = TradeItPlaceTradeRequest(orderId: previewOrderResult.orderId)

            tradeService.placeTrade(placeOrderRequest) { result in
                switch result {
                case let placeOrderResult as TradeItPlaceOrderResult: onSuccess(placeOrderResult)
                case let errorResult as TradeItErrorResult: onFailure(errorResult)
                default: onFailure(TradeItErrorResult.tradeError(withSystemMessage: "Error placing order."))
                }
            }
        }
    }
}
