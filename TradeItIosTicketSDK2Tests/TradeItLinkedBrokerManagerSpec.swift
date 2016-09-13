import Quick
import Nimble
@testable import TradeItIosEmsApi

class TradeItLinkedBrokerManagerSpec: QuickSpec {
    override func spec() {
        var linkedBrokerManager: TradeItLinkedBrokerManager!
        var tradeItConnector: FakeTradeItConnector! = FakeTradeItConnector()
        var tradeItSession: FakeTradeItSession!
        var tradeItSessionProvider: FakeTradeItSessionProvider!

        beforeEach {
            tradeItConnector = FakeTradeItConnector()
            tradeItSession = FakeTradeItSession()
            tradeItSessionProvider = FakeTradeItSessionProvider()
            tradeItSessionProvider.tradeItSessionToProvide = tradeItSession

            linkedBrokerManager = TradeItLinkedBrokerManager(connector: tradeItConnector)
            linkedBrokerManager.tradeItSessionProvider = tradeItSessionProvider
        }

        describe("getAvailableBrokers") {
            var onSuccessCallbackWasCalled = 0
            var onFailureCallbackWasCalled = 0

            var returnedBrokers: [TradeItBroker]!

            beforeEach {
                onSuccessCallbackWasCalled = 0
                onFailureCallbackWasCalled = 0
                returnedBrokers = nil

                linkedBrokerManager.getAvailableBrokers(
                    onSuccess: { (availableBrokers: [TradeItBroker]) -> Void in
                        onSuccessCallbackWasCalled += 1
                        returnedBrokers = availableBrokers
                    },
                    onFailure: { () -> Void in
                        onFailureCallbackWasCalled += 1
                    }
                )
            }

            it("gets the list of available brokers from the connector") {
                expect(tradeItConnector.calls.count).to(equal(1))
                let getBrokersCalls = tradeItConnector.calls.forMethod("getAvailableBrokersWithCompletionBlock")
                expect(getBrokersCalls.count).to(equal(1))
            }

            context("when getting available brokers succeeds") {
                var brokersResult: [TradeItBroker]!

                beforeEach {
                    brokersResult = [
                        TradeItBroker.init(shortName: "My Special Short Name",
                                           longName: "My Special Long Name")
                    ]

                    let getBrokersCalls = tradeItConnector.calls.forMethod("getAvailableBrokersWithCompletionBlock")
                    let completionBlock = getBrokersCalls[0].args["completionBlock"] as! ([TradeItBroker]?) -> Void

                    completionBlock(brokersResult)
                }

                it("passes the brokers to onSuccess") {
                    expect(onSuccessCallbackWasCalled).to(equal(1))
                    expect(onFailureCallbackWasCalled).to(equal(0))
                    expect(returnedBrokers).to(equal(brokersResult))
                }
            }

            context("when getting available brokers fails") {
                beforeEach {
                    let getBrokersCalls = tradeItConnector.calls.forMethod("getAvailableBrokersWithCompletionBlock")
                    let completionBlock = getBrokersCalls[0].args["completionBlock"] as! ([TradeItBroker]?) -> Void

                    completionBlock(nil)
                }

                it("calls onFailure") {
                    expect(onSuccessCallbackWasCalled).to(equal(0))
                    expect(onFailureCallbackWasCalled).to(equal(1))
                }
            }
        }

        describe("linkBroker") {
            var onSuccessCallbackWasCalled = 0
            var onFailureCallbackWasCalled = 0

            var returnedLinkedBroker: TradeItLinkedBroker! = nil
            var returnedErrorResult: TradeItErrorResult! = nil


            beforeEach {
                onSuccessCallbackWasCalled = 0
                onFailureCallbackWasCalled = 0

                let authInfo = TradeItAuthenticationInfo(id: "My Special Username",
                                                         andPassword: "My Special Password",
                                                         andBroker: "My Special Broker")

                linkedBrokerManager.linkBroker(
                    authInfo: authInfo,
                    onSuccess: { (linkedBroker: TradeItLinkedBroker) -> Void in
                        onSuccessCallbackWasCalled += 1
                        returnedLinkedBroker = linkedBroker
                    },
                    onFailure: { (tradeItErrorResult: TradeItErrorResult) in
                        onFailureCallbackWasCalled += 1
                        returnedErrorResult = tradeItErrorResult
                    }
                )
            }

            it("links the broker with the connector") {
                expect(tradeItConnector.calls.count).to(equal(1))
                let linkCalls = tradeItConnector.calls.forMethod("linkBrokerWithAuthenticationInfo(_:andCompletionBlock:)")
                expect(linkCalls.count).to(equal(1))
            }

            context("when linking succeeds") {
                let linkResult = TradeItAuthLinkResult()
                let linkedLogin = TradeItLinkedLogin()

                beforeEach {
                    tradeItConnector.tradeItLinkedLoginToReturn = linkedLogin

                    let linkCalls = tradeItConnector.calls.forMethod("linkBrokerWithAuthenticationInfo(_:andCompletionBlock:)")
                    let completionBlock = linkCalls[0].args["andCompletionBlock"] as! (TradeItResult!) -> Void

                    completionBlock(linkResult)
                }

                it("saves the linkedLogin to the Keychain") {
                    let saveLinkToKeychainCalls = tradeItConnector.calls.forMethod("saveLinkToKeychain(_:withBroker:)")
                    expect(saveLinkToKeychainCalls.count).to(equal(1))

                    let linkResultArg = saveLinkToKeychainCalls[0].args["link"] as! TradeItAuthLinkResult
                    expect(linkResultArg).to(be(linkResult))

                    let brokerArg = saveLinkToKeychainCalls[0].args["broker"] as! String
                    expect(brokerArg).to(equal("My Special Broker"))
                }

                it("adds the linked broker to the list of linkedBrokers") {
                    expect(linkedBrokerManager.linkedBrokers.count).to(equal(1))
                    expect(linkedBrokerManager.linkedBrokers[0].linkedLogin).to(be(linkedLogin))
                }

                it("calls the onSuccess callback with the linkedBroker") {
                    expect(onSuccessCallbackWasCalled).to(equal(1))
                    expect(onFailureCallbackWasCalled).to(equal(0))

                    expect(returnedLinkedBroker.session).to(be(tradeItSession))
                    expect(returnedLinkedBroker.linkedLogin).to(be(linkedLogin))
                }
            }

            context("when linking fails") {
                let errorResult = TradeItErrorResult()

                beforeEach {
                    let linkCalls = tradeItConnector.calls.forMethod("linkBrokerWithAuthenticationInfo(_:andCompletionBlock:)")
                    let completionBlock = linkCalls[0].args["andCompletionBlock"] as! (TradeItResult!) -> Void

                    completionBlock(errorResult)
                }

                it("calls the onFailure callback with the error") {
                    expect(onSuccessCallbackWasCalled).to(equal(0))
                    expect(onFailureCallbackWasCalled).to(equal(1))

                    expect(returnedErrorResult).to(be(errorResult))
                }
            }
        }
        
        describe("getAllAccounts") {
            var returnedAccounts: [TradeItLinkedBrokerAccount] = []

            beforeEach {
                returnedAccounts = []
                linkedBrokerManager.linkedBrokers = []
            }

            context("when there are no linked brokers") {
                it("returns an empty array") {
                    returnedAccounts = linkedBrokerManager.getAllAccounts()
                    expect(returnedAccounts.count).to(equal(0))
                }
            }

            context("when there are linked brokers") {
                var account11: TradeItLinkedBrokerAccount!
                var account12: TradeItLinkedBrokerAccount!
                var account31: TradeItLinkedBrokerAccount!

                beforeEach {
                    let linkedOldLogin1 = TradeItLinkedLogin(label: "My linked login 1", broker: "Broker #1", userId: "userId1", andKeyChainId: "keychainId1")
                    let linkedOldLogin2 = TradeItLinkedLogin(label: "My linked login 2", broker: "Broker #2", userId: "userId2", andKeyChainId: "keychainId2")
                    let linkedOldLogin3 = TradeItLinkedLogin(label: "My linked login 3", broker: "Broker #3", userId: "userId3", andKeyChainId: "keychainId3")

                    let tradeItSession1 = FakeTradeItSession()
                    let linkedOldBroker1 = TradeItLinkedBroker(session: tradeItSession1, linkedLogin: linkedOldLogin1)
                    account11 = TradeItLinkedBrokerAccount(linkedBroker: linkedOldBroker1, brokerName: "Broker #1", accountName: "My account #11", accountNumber: "123456789", balance: nil, fxBalance: nil, positions: [])
                    linkedOldBroker1.accounts.append(account11)
                    account12 = TradeItLinkedBrokerAccount(linkedBroker: linkedOldBroker1, brokerName: "Broker #1", accountName: "My account #12", accountNumber: "234567890", balance: nil, fxBalance: nil, positions: [])
                    linkedOldBroker1.accounts.append(account12)

                    let tradeItSession2 = FakeTradeItSession()
                    let linkedOldBroker2 = TradeItLinkedBroker(session: tradeItSession2, linkedLogin: linkedOldLogin2)
                    
                    let tradeItSession3 = FakeTradeItSession()
                    let linkedOldBroker3 = TradeItLinkedBroker(session: tradeItSession3, linkedLogin: linkedOldLogin3)
                    account31 = TradeItLinkedBrokerAccount(linkedBroker: linkedOldBroker3, brokerName: "Broker #3", accountName: "My account #31", accountNumber: "5678901234", balance: nil, fxBalance: nil, positions: [])
                    linkedOldBroker3.accounts.append(account31)

                    linkedBrokerManager.linkedBrokers.append(linkedOldBroker1)
                    linkedBrokerManager.linkedBrokers.append(linkedOldBroker2)
                    linkedBrokerManager.linkedBrokers.append(linkedOldBroker3)
                    

                    returnedAccounts = linkedBrokerManager.getAllAccounts()
                }

                it("returns all the accounts of the linkedBrokers") {
                    expect(returnedAccounts.count).to(equal(3))
                    expect(returnedAccounts[0]).to(be(account11))
                    expect(returnedAccounts[1]).to(be(account12))
                    expect(returnedAccounts[2]).to(be(account31))
                }
            }
        }

        describe("authenticateAll") {
            context("when there are linked brokers") {
                var authenticatedLinkedBroker: FakeTradeItLinkedBroker!
                var failedUnauthenticatedLinkedBroker: FakeTradeItLinkedBroker!
                var successfulUnauthenticatedLinkedBroker: FakeTradeItLinkedBroker!
                var securityQuestionUnauthenticatedLinkedBroker: FakeTradeItLinkedBroker!
                var securityQuestionCalledWith: TradeItSecurityQuestionResult?
                var onFinishedAuthenticatingWasCalled = 0

                beforeEach {
                    authenticatedLinkedBroker = FakeTradeItLinkedBroker()
                    authenticatedLinkedBroker.isAuthenticated = true

                    failedUnauthenticatedLinkedBroker = FakeTradeItLinkedBroker()
                    failedUnauthenticatedLinkedBroker.isAuthenticated = false

                    successfulUnauthenticatedLinkedBroker = FakeTradeItLinkedBroker()
                    successfulUnauthenticatedLinkedBroker.isAuthenticated = false

                    securityQuestionUnauthenticatedLinkedBroker = FakeTradeItLinkedBroker()
                    securityQuestionUnauthenticatedLinkedBroker.isAuthenticated = false

                    linkedBrokerManager.linkedBrokers = [
                        authenticatedLinkedBroker,
                        failedUnauthenticatedLinkedBroker,
                        successfulUnauthenticatedLinkedBroker,
                        securityQuestionUnauthenticatedLinkedBroker
                    ]

                    onFinishedAuthenticatingWasCalled = 0

                    linkedBrokerManager.authenticateAll(
                        onSecurityQuestion: { (result: TradeItSecurityQuestionResult) -> String in
                            securityQuestionCalledWith = result
                            return ""
                        },
                        onFinished: {
                            onFinishedAuthenticatingWasCalled += 1
                        }
                    )
                }

                it("calls authenticate only on non authenticated linkedBokers") {
                    var authenticateCalls = authenticatedLinkedBroker.calls.forMethod("authenticate(onSuccess:onSecurityQuestion:onFailure:)")
                    expect(authenticateCalls.count).to(equal(0))

                    authenticateCalls = failedUnauthenticatedLinkedBroker.calls.forMethod("authenticate(onSuccess:onSecurityQuestion:onFailure:)")
                    expect(authenticateCalls.count).to(equal(1))

                    authenticateCalls = successfulUnauthenticatedLinkedBroker.calls.forMethod("authenticate(onSuccess:onSecurityQuestion:onFailure:)")
                    expect(authenticateCalls.count).to(equal(1))

                    authenticateCalls = securityQuestionUnauthenticatedLinkedBroker.calls.forMethod("authenticate(onSuccess:onSecurityQuestion:onFailure:)")
                    expect(authenticateCalls.count).to(equal(1))
                }

                it("doesn't call onFinishedAuthenticating before all linked brokers have finished") {
                    expect(onFinishedAuthenticatingWasCalled).to(equal(0))
                }

                it("calls onSecurityQuestion for security questions") {
                    let authenticateCalls = securityQuestionUnauthenticatedLinkedBroker.calls.forMethod("authenticate(onSuccess:onSecurityQuestion:onFailure:)")
                    let onSecurityQuestion = authenticateCalls[0].args["onSecurityQuestion"] as! (TradeItSecurityQuestionResult) -> String
                    let expectedSecurityQuestionResult = TradeItSecurityQuestionResult()

                    expect(securityQuestionCalledWith).to(beNil())

                    onSecurityQuestion(expectedSecurityQuestionResult)

                    expect(securityQuestionCalledWith).to(be(expectedSecurityQuestionResult))
                }

                describe("after all brokers have finished trying to authenticate") {
                    beforeEach {
//                        var authenticateCalls = authenticatedLinkedBroker.calls.forMethod("authenticate(onSuccess:onSecurityQuestion:onFailure:)")
//                        var onSuccess = authenticateCalls[0].args["onSuccess"] as! () -> Void
//                        onSuccess()

                        var authenticateCalls = failedUnauthenticatedLinkedBroker.calls.forMethod("authenticate(onSuccess:onSecurityQuestion:onFailure:)")
                        let onFailure = authenticateCalls[0].args["onFailure"] as! (TradeItErrorResult) -> Void
                        onFailure(TradeItErrorResult())

                        authenticateCalls = successfulUnauthenticatedLinkedBroker.calls.forMethod("authenticate(onSuccess:onSecurityQuestion:onFailure:)")
                        var onSuccess = authenticateCalls[0].args["onSuccess"] as! () -> Void
                        onSuccess()

                        authenticateCalls = securityQuestionUnauthenticatedLinkedBroker.calls.forMethod("authenticate(onSuccess:onSecurityQuestion:onFailure:)")
                        onSuccess = authenticateCalls[0].args["onSuccess"] as! () -> Void
                        onSuccess()

                        flushAsyncEvents()
                    }

                    it("calls onFinishedAuthenticating") {
                        expect(onFinishedAuthenticatingWasCalled).to(equal(1))
                    }
                }
            }

            context("when there are no linked brokers") {
                it("calls onFinishedAuthenticating") {
                    linkedBrokerManager.linkedBrokers = []

                    var onFinishedAuthenticatingWasCalled = 0

                    linkedBrokerManager.authenticateAll(
                        onSecurityQuestion: { (result: TradeItSecurityQuestionResult) -> String in
                            return ""
                        },
                        onFinished: {
                            onFinishedAuthenticatingWasCalled += 1
                        }
                    )

                    flushAsyncEvents()

                    expect(onFinishedAuthenticatingWasCalled).to(equal(1))
                }
            }
        }

        describe("refreshAccountBalances") {
            var onFinishedRefreshingBalancesWasCalled = 0
            var linkedBroker1: FakeTradeItLinkedBroker!
            var linkedBroker2: FakeTradeItLinkedBroker!
            var linkedBroker3: FakeTradeItLinkedBroker!
            beforeEach {
                let linkedLogin1 = TradeItLinkedLogin(label: "My linked login 1", broker: "Broker #1", userId: "userId1", andKeyChainId: "keychainId1")

                let tradeItSession = FakeTradeItSession()
                linkedBroker1 = FakeTradeItLinkedBroker(session: tradeItSession, linkedLogin: linkedLogin1)
                let account11 = TradeItLinkedBrokerAccount(linkedBroker: linkedBroker1,brokerName: "Broker #1", accountName: "My account #11", accountNumber: "123456789", balance: nil, fxBalance: nil, positions: [])
                let account12 = TradeItLinkedBrokerAccount(linkedBroker: linkedBroker1, brokerName: "Broker #1", accountName: "My account #12", accountNumber: "234567890", balance: nil, fxBalance: nil, positions: [])
                linkedBroker1.accounts = [account11, account12]
                linkedBroker1.isAuthenticated = true

                let linkedLogin2 = TradeItLinkedLogin(label: "My linked login 2", broker: "Broker #2", userId: "userId2", andKeyChainId: "keychainId2")
                let tradeItSession2 = FakeTradeItSession()
                linkedBroker2 = FakeTradeItLinkedBroker(session: tradeItSession2, linkedLogin: linkedLogin2)
                let account21 = TradeItLinkedBrokerAccount(linkedBroker: linkedBroker2, brokerName: "Broker #2", accountName: "My account #21", accountNumber: "5678901234", balance: nil, fxBalance: nil, positions: [])
                linkedBroker2.accounts = [account21]
                linkedBroker2.isAuthenticated = true

                let linkedLogin3 = TradeItLinkedLogin(label: "My linked login 3", broker: "Broker #3", userId: "userId3", andKeyChainId: "keychainId2")
                let tradeItSession3 = FakeTradeItSession()
                linkedBroker3 = FakeTradeItLinkedBroker(session: tradeItSession3, linkedLogin: linkedLogin3)
                let account31 = TradeItLinkedBrokerAccount(linkedBroker: linkedBroker3, brokerName: "Broker #3", accountName: "My account #31", accountNumber: "5678901234", balance: nil, fxBalance: nil, positions: [])
                linkedBroker3.accounts = [account31]
                linkedBroker3.isAuthenticated = false

                linkedBrokerManager.linkedBrokers = [linkedBroker1, linkedBroker2, linkedBroker3]

                linkedBrokerManager.refreshAccountBalances(
                    onFinished: {
                        onFinishedRefreshingBalancesWasCalled += 1
                    }
                )
            }

            it("refreshes all the authenticated linkedBrokers") {
                expect(linkedBroker1.calls.forMethod("refreshAccountBalances(onFinished:)").count).to(equal(1))
                expect(linkedBroker2.calls.forMethod("refreshAccountBalances(onFinished:)").count).to(equal(1))
            }

            it("doesn't refresh the unauthenticated linkedBroker") {
                expect(linkedBroker3.calls.forMethod("refreshAccountBalances(onFinished:)").count).to(equal(0))
            }

            it("doesn't call the callback until the refresh is finished") {
                expect(onFinishedRefreshingBalancesWasCalled).to(equal(0))
            }

            describe("when all the linkedBroker are refreshed") {
                beforeEach {
                    let onFinished1 = linkedBroker1.calls.forMethod("refreshAccountBalances(onFinished:)")[0].args["onFinished"] as! () -> Void
                    onFinished1()

                    let onFinished2 = linkedBroker2.calls.forMethod("refreshAccountBalances(onFinished:)")[0].args["onFinished"] as! () -> Void
                    onFinished2()

                    flushAsyncEvents()
                }

                it("calls onFinishedRefreshingBalancesWasCalled") {
                    flushAsyncEvents()
                    expect(onFinishedRefreshingBalancesWasCalled).to(equal(1))
                }
            }
        }
    }
}