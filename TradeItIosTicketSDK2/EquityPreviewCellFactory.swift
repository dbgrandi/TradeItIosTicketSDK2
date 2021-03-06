class EquityPreviewCellFactory: PreviewCellFactory {
    private let linkedBrokerAccount: TradeItLinkedBrokerAccount
    private let orderCapabilities: TradeItInstrumentOrderCapabilities?
    private let previewOrderResult: TradeItPreviewOrderResult
    var placeOrderResult: TradeItPlaceOrderResult?
    private weak var delegate: PreviewMessageDelegate?

    init(
        previewMessageDelegate delegate: PreviewMessageDelegate,
        linkedBrokerAccount: TradeItLinkedBrokerAccount,
        previewOrderResult: TradeItPreviewOrderResult
    ) {
        self.delegate = delegate
        self.linkedBrokerAccount = linkedBrokerAccount
        self.previewOrderResult = previewOrderResult
        self.orderCapabilities = self.linkedBrokerAccount.orderCapabilities.filter { $0.instrument == "equities" }.first
    }

    func generateCellData() -> [PreviewCellData] {
        guard let orderDetails = previewOrderResult.orderDetails
            else { return [] }

        var cells = [PreviewCellData]()

        cells += [
            ValueCellData(label: "Account", value: linkedBrokerAccount.getFormattedAccountName())
        ] as [PreviewCellData]

        let orderDetailsPresenter = TradeItOrderDetailsPresenter(
            orderAction: orderDetails.orderAction,
            orderExpiration: orderDetails.orderExpiration,
            orderCapabilities: orderCapabilities
        )

        if let orderNumber = self.placeOrderResult?.orderNumber {
            cells += [
                ValueCellData(label: "Order #", value: orderNumber)
                ] as [PreviewCellData]
        }

        cells += [
            ValueCellData(label: "Action", value: orderDetailsPresenter.getOrderActionLabel()),
            ValueCellData(label: "Symbol", value: orderDetails.orderSymbol),
            ValueCellData(
                label: labelForQuantity(linkedBrokerAccount: linkedBrokerAccount, orderQuantityTypeString: orderDetails.orderQuantityType),
                value: formatQuantity(rawQuantityType: orderDetails.orderQuantityType, quantity: orderDetails.orderQuantity)
            ),
            ValueCellData(label: "Price", value: orderDetails.orderPrice),
            ValueCellData(label: "Time in force", value: orderDetailsPresenter.getOrderExpirationLabel())
        ] as [PreviewCellData]

        if self.linkedBrokerAccount.userCanDisableMargin {
            cells.append(ValueCellData(label: "Type", value: MarginPresenter.labelFor(value: orderDetails.userDisabledMargin)))
        }

        if let estimatedOrderCommission = orderDetails.estimatedOrderCommission {
            cells.append(ValueCellData(label: orderDetails.orderCommissionLabel, value: self.formatCurrency(estimatedOrderCommission)))
        }

        if let estimatedTotalValue = orderDetails.estimatedTotalValue {
            let action = TradeItOrderAction(value: orderDetails.orderAction)
            let title = "Estimated \(TradeItOrderActionPresenter.SELL_ACTIONS.contains(action) ? "proceeds" : "cost")"
            cells.append(ValueCellData(label: title, value: formatCurrency(estimatedTotalValue)))
        }

        if self.placeOrderResult == nil {
            cells += generateMessageCellData()
        }

        return cells
    }

    // MARK: Private
    
    private func formatQuantity(rawQuantityType: String, quantity: NSNumber) -> String {
        if let quantityType = OrderQuantityType(rawValue: rawQuantityType),
            let maxDecimal = orderCapabilities?.maxDecimalPlacesFor(orderQuantityType: quantityType) {
            return NumberFormatter.formatQuantity(quantity, maxDecimalPlaces: maxDecimal)
        } else {
            return quantity.stringValue
        }
    }

    private func labelForQuantity(linkedBrokerAccount: TradeItLinkedBrokerAccount, orderQuantityTypeString: String) -> String {
        guard let quantityType = OrderQuantityType.init(rawValue: orderQuantityTypeString) else { return "Amount" }

        switch quantityType {
        case .totalPrice: return "Amount in \(linkedBrokerAccount.accountBaseCurrency)"
        default: return "Amount"
        }
    }

    private func generateMessageCellData() -> [PreviewCellData] {
        guard let messages = previewOrderResult.orderDetails?.warnings else { return [] }
        return messages.map(MessageCellData.init)
    }

    private func formatCurrency(_ value: NSNumber) -> String {
        return NumberFormatter.formatCurrency(value, currencyCode: self.linkedBrokerAccount.accountBaseCurrency)
    }
}
