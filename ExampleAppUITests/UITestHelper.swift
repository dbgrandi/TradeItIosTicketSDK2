import XCTest

extension XCUIElement {
    func scrollToElement(element: XCUIElement) {
        while !element.visible() {
            swipeUp()
        }
    }
    
    func visible() -> Bool {
        guard self.exists && !self.frame.isEmpty else { return false }
        return XCUIApplication().windows.element(boundBy: 0).frame.contains(self.frame)
    }
}

extension XCTestCase {
    func predicateDoesntExist() -> NSPredicate {
        return NSPredicate(format: "exists == false")
    }

    func predicateExists() -> NSPredicate {
        return NSPredicate(format: "exists == true")
    }

    func predicateIsNotHittable() -> NSPredicate {
        return NSPredicate(format: "hittable == false")
    }

    func predicateIsHittable() -> NSPredicate {
        return NSPredicate(format: "hittable == true")
    }

    func predicateHasKeyboardFocus() -> NSPredicate {
        return NSPredicate(format:"hasKeyboardFocus == true")
    }

    func predicateNotHasKeyboardFocus() -> NSPredicate {
        return NSPredicate(format:"hasKeyboardFocus == false")
    }
    
    func predicateBeginsWith(label: String) -> NSPredicate {
        return NSPredicate(format: ("label BEGINSWITH '\(label)'"))
    }

    func waitForElementToDisappear(_ element: XCUIElement, withinSeconds seconds: TimeInterval = 5) {
        usleep(100_000)
        self.expectation(for: self.predicateDoesntExist(), evaluatedWith:element, handler: nil)
        self.waitForExpectations(timeout: seconds, handler: nil)
    }

    func waitForElementToAppear(_ element: XCUIElement, withinSeconds seconds: TimeInterval = 10) {
        usleep(100_000)
        self.expectation(for: self.predicateExists(), evaluatedWith:element, handler: nil)
        self.waitForExpectations(timeout: seconds, handler: nil)
    }

    func waitForElementNotToBeHittable(_ element: XCUIElement, withinSeconds seconds: TimeInterval = 5) {
        usleep(100_000)
        self.expectation(for: self.predicateIsNotHittable(), evaluatedWith:element, handler: nil)
        self.waitForExpectations(timeout: seconds, handler: nil)
    }

    func waitForElementToBeHittable(_ element: XCUIElement, withinSeconds seconds: TimeInterval = 10) {
        usleep(100_000)
        self.expectation(for: self.predicateIsHittable(), evaluatedWith:element, handler: nil)
        self.waitForExpectations(timeout: seconds, handler: nil)
    }

    func waitForElementToHaveKeyboardFocus(_ element: XCUIElement, withinSeconds seconds: TimeInterval = 5) {
        usleep(100_000)
        self.expectation(for: self.predicateHasKeyboardFocus(), evaluatedWith:element, handler: nil)
        self.waitForExpectations(timeout: seconds, handler: nil)
    }

    func waitForElementNotToHaveKeyboardFocus(_ element: XCUIElement, withinSeconds seconds: TimeInterval = 5) {
        usleep(100_000)
        self.expectation(for: self.predicateNotHasKeyboardFocus(), evaluatedWith:element, handler: nil)
        self.waitForExpectations(timeout: seconds, handler: nil)
    }
    
    //******************//
    //* Helper methods *//
    //******************//
     func symbolSearch(_ app: XCUIApplication, symbol: String){
        let symbolSearchField = app.textFields["Enter a symbol"]
        waitForElementToHaveKeyboardFocus(symbolSearchField)
        symbolSearchField.typeText("\(symbol)")
    }
    
    func testConfirmation(_ app: XCUIApplication){
        XCTAssert(app.images["success_icon.png"].exists)
        XCTAssert(app.staticTexts["Confirmation"].exists)
        XCTAssert(app.buttons["Trade Again"].exists)
        XCTAssert(app.buttons["View Portfolio"].exists)
    }
    
    func testPreviewValues(_ app: XCUIApplication, symbol: String, limitPrice: String, stopPrice: String, quantity: String){
        XCTAssert(app.staticTexts["ACCOUNT"].exists)
        XCTAssert(app.staticTexts["SYMBOL"].exists)
        XCTAssert(app.staticTexts["QUANTITY"].exists)
        XCTAssert(app.staticTexts["ACTION"].exists)
        XCTAssert(app.staticTexts["PRICE"].exists)
        XCTAssert(app.staticTexts["EXPIRATION"].exists)
        XCTAssert(app.staticTexts["SHARES OWNED"].exists)
        XCTAssert(app.staticTexts["SHARES HELD SHORT"].exists)
        XCTAssert(app.staticTexts["BUYING POWER"].exists)
        XCTAssert(app.staticTexts["BROKER FEE"].exists)
        XCTAssert(app.staticTexts["ESTIMATED COST"].exists)
        XCTAssert(app.staticTexts["\(symbol)"].exists)
        XCTAssert(app.staticTexts["\(quantity)"].exists)
        XCTAssert(app.staticTexts["$\(limitPrice).00 (trigger: $\(stopPrice).00)"].exists)
        XCTAssert(app.buttons["Place Order"].exists)
    }
    
    func fillOrder(_ app: XCUIApplication, orderAction: String, orderType: String, limitPrice: String, stopPrice: String, quantity: String, expiration: String){
        //Shares
        app.textFields["Quantity"].tap()
        waitForElementToHaveKeyboardFocus(app.textFields["Quantity"])
        app.textFields["Quantity"].typeText("\(quantity)")
        //Limit Price
        app.textFields["Limit Price"].tap()
        waitForElementToHaveKeyboardFocus(app.textFields["Limit Price"])
        app.textFields["Limit Price"].typeText("\(limitPrice)")
        //Stop Price
        app.textFields["Stop Price"].tap()
        waitForElementToHaveKeyboardFocus(app.textFields["Stop Price"])
        app.textFields["Stop Price"].typeText("\(stopPrice)")
    }
    
    func testTradeScreenValues(_ app: XCUIApplication){
        XCTAssert(app.buttons["Buy"].exists)
        XCTAssert(app.buttons["Market"].exists)
        XCTAssert(app.textFields["Quantity"].exists)
        app.buttons["Buy"].tap()
        waitForElementToAppear(app.sheets["Order Action"])
        XCTAssert(app.sheets.buttons["Buy"].exists)
        XCTAssert(app.sheets.buttons["Sell"].exists)
        XCTAssert(app.sheets.buttons["Buy to Cover"].exists)
        XCTAssert(app.sheets.buttons["Sell Short"].exists)
        XCTAssert(app.buttons["Cancel"].exists)
        app.buttons["Cancel"].tap()
        waitForElementToDisappear(app.sheets["Order Action"])
        app.buttons["Market"].tap()
        waitForElementToAppear(app.sheets["Order Type"])
        XCTAssert(app.sheets.buttons["Market"].exists)
        XCTAssert(app.sheets.buttons["Limit"].exists)
        XCTAssert(app.sheets.buttons["Stop Market"].exists)
        XCTAssert(app.sheets.buttons["Stop Limit"].exists)
        XCTAssert(app.buttons["Cancel"].exists)
        app.sheets.buttons["Stop Limit"].tap()
        waitForElementToDisappear(app.sheets["Order Type"])
        XCTAssert(app.textFields["Limit Price"].exists)
        XCTAssert(app.textFields["Stop Price"].exists)
        XCTAssert(app.buttons["Good for day"].exists)
        app.buttons["Good for day"].tap()
        waitForElementToAppear(app.sheets["Order Expiration"])
        XCTAssert(app.sheets.buttons["Good for day"].exists)
        XCTAssert(app.sheets.buttons["Good until canceled"].exists)
        XCTAssert(app.buttons["Cancel"].exists)
        app.sheets.buttons["Good until canceled"].tap()
        waitForElementToDisappear(app.sheets["Order Expiration"])
    }
    
    func clearData(_ app: XCUIApplication) {
        let deleteLinkedBrokersText = app.tables.staticTexts["Unlink all brokers"]
        scrollDownTo(app, element: deleteLinkedBrokersText)
        deleteLinkedBrokersText.tap()
        let alert = app.alerts["Deletion complete."]
        waitForElementToAppear(alert)
        alert.buttons["OK"].tap()
    }
    
    func scrollDownTo(_ app: XCUIApplication, element: XCUIElement, retry: Int = 3) {
        let table = app.tables.element(boundBy: 0)
        
        table.swipeUp()
        
        if (!element.exists && retry > 0) {
            scrollDownTo(app, element: element, retry: (retry - 1))
        }
        
        if (!element.exists && retry == 0) {
            scrollUpTo(app, element: element, retry: (retry + 1))
        }
    }
    
    func scrollUpTo(_ app: XCUIApplication, element: XCUIElement, retry: Int = 3) {
        let table = app.tables.element(boundBy: 0)
        
        table.swipeDown()
        
        if (!element.exists && retry > 0) {
            scrollUpTo(app, element: element, retry: (retry - 1))
        }
    }
    
    func handleWelcomeScreen(_ app: XCUIApplication, launchOption: String) {
        let launchPortfolioText = app.tables.staticTexts["\(launchOption)"]
        scrollUpTo(app, element: launchPortfolioText)
        launchPortfolioText.tap()
        waitForElementToAppear(app.navigationBars["Welcome"])
        app.buttons["Get started"].tap()
    }
    
    func selectBrokerFromTheBrokerSelectionScreen(_ app: XCUIApplication, longBrokerName: String) {
        XCTAssert(app.navigationBars["Select your broker"].exists)
        XCTAssert(app.tables.cells.count > 0)
        let dummyBrokerStaticText = app.tables.staticTexts[longBrokerName]
        XCTAssert(dummyBrokerStaticText.exists)
        app.tables.staticTexts[longBrokerName].tap()
    }
    
    func submitValidCredentialsOnTheLoginScreen(_ app: XCUIApplication, longBrokerName: String, username: String = "dummy", password: String = "dummy") {
        let usernameTextField = app.textFields["\(longBrokerName) Username"]
        let passwordTextField = app.secureTextFields["\(longBrokerName) Password"]
        waitForElementToAppear(usernameTextField)
        usernameTextField.tap()
        
        waitForElementToHaveKeyboardFocus(usernameTextField)
        usernameTextField.typeText(username)
        passwordTextField.tap()
        waitForElementToHaveKeyboardFocus(passwordTextField)
        waitForElementNotToHaveKeyboardFocus(usernameTextField)
        passwordTextField.typeText(password)
        
        app.buttons["Sign In"].tap()
    }
    
    func completeOauthScreen(_ app: XCUIApplication) {
        let successText = app.staticTexts["Success!"]
        waitForElementToAppear(successText)
        XCTAssert(successText.exists)
        app.buttons["Continue"].tap()
    }
    
    func tapCloseButton(_ app: XCUIApplication) {
        let closeButton = app.buttons["Close"]
        waitForElementToBeHittable(closeButton)
        closeButton.tap()
    }
    
    func selectAccountOnPortfolioScreen(_ app: XCUIApplication, rowNum: Int) {
        waitForElementToAppear(app.navigationBars["Portfolio"])
        var ezLoadingActivity = app.staticTexts["Authenticating"]
        waitForElementToDisappear(ezLoadingActivity, withinSeconds: 10)
        ezLoadingActivity = app.staticTexts["Retreiving Account Summary"]
        waitForElementToDisappear(ezLoadingActivity)
        let tableView = app.tables.element(boundBy: 0)
        XCTAssertTrue(tableView.cells.count > 0)
        let cell = tableView.cells.element(boundBy: UInt(rowNum)) // index 0 is header
        cell.tap()
    }
    
    func testPortfolioValues(_ app: XCUIApplication, brokerName: String){
        if(brokerName == "Dummy"){
            //Balances
            XCTAssert(app.tables.staticTexts["Individual**0001"].exists)
            testPortfolioValues(app)
        }
        else if(brokerName == "dummyMultipleAcct1"){
            //Balances
            XCTAssert(app.tables.staticTexts["Individual**0001"].exists)
            testPortfolioValues(app)
        }
        else if(brokerName == "jointIRA"){
            //Balances
            XCTAssert(app.tables.staticTexts["Joint IRA **0002"].exists)
            testPortfolioValues(app)
        }
        else if(brokerName == "Joint401k"){
            //Balances
            XCTAssert(app.tables.staticTexts["Joint 401k**0003"].exists)
            testPortfolioValues(app)
        }
        else if(brokerName == "MargicAcct"){
            //Balances
            XCTAssert(app.tables.staticTexts["Margin Acc**0004"].exists)
            testPortfolioValues(app)
        }
        else if(brokerName == "OptionAcct"){
            //Balances
            XCTAssert(app.tables.staticTexts["OPTIONS SU**0005"].exists)
            testPortfolioValues(app)
        }
    }
    
    private func testPortfolioValues(_ app: XCUIApplication) {
        XCTAssert(app.tables.staticTexts["$2,408.12"].exists)
        XCTAssert(app.tables.staticTexts["$76,489.23"].exists)
        XCTAssert(app.tables.staticTexts[" (+22.84%)"].exists)
        //Positions
        waitForElementToAppear(app.tables.staticTexts["AAPL"]) //change
        XCTAssert(app.tables.staticTexts["1 shares"].exists)
        XCTAssert(app.tables.staticTexts["$103.34"].exists)
        XCTAssert(app.tables.staticTexts["$112.34"].exists)
        //Positions details
        app.tables.staticTexts["AAPL"].tap()
        waitForElementToAppear(app.tables.staticTexts["Bid / Ask"])
        XCTAssert(app.tables.staticTexts["Total Value"].exists)
        XCTAssert(app.tables.staticTexts["Total Return"].exists)
        XCTAssert(app.tables.staticTexts["Day Return"].exists)
        waitForElementToDisappear(app.tables.staticTexts["N/A"])
        app.tables.staticTexts["AAPL"].tap()
        let portfolioBackButton = app.buttons["Portfolio"]
        waitForElementToBeHittable(portfolioBackButton)
        portfolioBackButton.tap()
    }
}
