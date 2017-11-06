extension TradeItOrderStatusDetails {
    var orderStatusEnum: OrderStatus {
        return OrderStatus(rawValue: self.orderStatus ?? "") ?? .unknown
    }

    var orderTypeEnum: OrderType {
        return OrderType(rawValue: self.orderType ?? "") ?? .unknown
    }

    enum OrderStatus: String {
        case pending = "PENDING"
        case open = "OPEN"
        case filled = "FILLED"
        case partFilled = "PART_FILLED"
        case cancelled = "CANCELED"
        case rejected = "REJECTED"
        case notFound = "NOT_FOUND"
        case pendingCancel = "PENDING_CANCEL"
        case expired = "EXPIRED"
        case unknown

        public var cancelable: Bool {
            return [.pending, .open, .partFilled, .pendingCancel, .unknown].contains(self)
        }
    }

    enum OrderType: String {
        case option = "OPTION"
        case equityOrEtf = "EQUITY_OR_ETF"
        case buyWrites = "BUY_WRITES"
        case spreads = "SPREADS"
        case combo = "COMBO"
        case multiLeg = "MULTILEG"
        case mutualFunds = "MUTUAL_FUNDS"
        case fixedIncome = "FIXED_INCOME"
        case cash = "CASH"
        case fx = "FX"
        case unknown = "UNKNOWN"
    }

    private typealias Category = [OrderStatus]
    private var openOrderCategory: Category {
        return  [.pending, .open, .pendingCancel]
    }
    
    private var partiallyFilledCategory: Category {
        return [.partFilled]
    }
    
    private var filledOrderCategory: Category {
        return [.filled]
    }

    private var otherOrderCategory: Category {
        return [.cancelled, .rejected, .notFound, .expired, .unknown]
    }

    private var cancellableCategory: Category {
        return openOrderCategory + partiallyFilledCategory + [.unknown]
    }

    func belongsToOpenCategory() -> Bool {
        return belongsToCategory(orderCategory: openOrderCategory)
    }
    
    func belongsToFilledCategory() -> Bool {
        return belongsToCategory(orderCategory: filledOrderCategory)
    }
    
    func belongsToOtherCategory() -> Bool {
        return belongsToCategory(orderCategory: otherOrderCategory)
    }
    
    func belongsToPartiallyFilledCategory() -> Bool {
        return belongsToCategory(orderCategory: partiallyFilledCategory)
    }
    
    func isGroupOrder() -> Bool {
        let groupOrders = self.groupOrders ?? []
        return groupOrders.count > 0
    }
    
    func isCancellable() -> Bool {
        return belongsToCategory(orderCategory: cancellableCategory)
    }
    
    // MARK: private
    
    private func belongsToCategory(orderCategory: Category) -> Bool {
        guard let groupOrders = self.groupOrders, groupOrders.count > 0 else {
            return orderCategory.contains(self.orderStatusEnum)
        }
        
        // Group orders specificity
        if orderCategory == partiallyFilledCategory { // Group orders belong to partially filled category if at least one order is filled and one other is different than filled
            let belongsToFilledOrder = groupOrders.filter { $0.belongsToFilledCategory() }.count > 0
            let belongsToOtherThanFilledOrders = groupOrders.filter { !$0.belongsToFilledCategory() }.count > 0
            return belongsToFilledOrder && belongsToOtherThanFilledOrders
        } else if orderCategory == otherOrderCategory { // Group orders belong to otherOrderCategory category if at least 2 legs are different and not filled
            let belongsToOpenCategory = groupOrders.filter { $0.belongsToOpenCategory() }.count > 0
            let belongsToPartiallyFilledCategory = groupOrders.filter { $0.belongsToPartiallyFilledCategory() }.count > 0
            let belongsToOtherCategory = groupOrders.filter { $0.belongsToOtherCategory() }.count > 0
            let belongsToDifferentCategoriesOtherThanFilled = ( belongsToOpenCategory && belongsToOtherCategory
                || belongsToOpenCategory && belongsToPartiallyFilledCategory
                || belongsToOtherCategory && belongsToPartiallyFilledCategory
            )
            let belongsToFilledCategory = groupOrders.filter { $0.belongsToFilledCategory() }.count > 0
            return belongsToDifferentCategoriesOtherThanFilled && !belongsToFilledCategory
        } else { // Group orders belong to a category if all of the legs belong to the same category
            let belongsToCategory = groupOrders.filter { $0.belongsToCategory(orderCategory: orderCategory) }.count > 0
            let belongsToAnOtherCategory = groupOrders.filter { !$0.belongsToCategory(orderCategory: orderCategory) }.count > 0
            return belongsToCategory && !belongsToAnOtherCategory
        }
    }
}
