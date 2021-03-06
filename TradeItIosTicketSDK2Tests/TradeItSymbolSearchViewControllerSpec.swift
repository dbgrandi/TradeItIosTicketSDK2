import Quick
import Nimble
@testable import TradeItIosTicketSDK2

class TradeItSymbolSearchViewControllerSpec : QuickSpec {
    override func spec() {
        var controller: TradeItSymbolSearchViewController!
        var window: UIWindow!
        var nav: UINavigationController!
        var marketDataService: FakeTradeItMarketService!
        var delegate: FakeTradeItSymbolSearchViewControllerDelegate!
        
        describe("initialization") {
            beforeEach {
                marketDataService = FakeTradeItMarketService(apiKey: "My api key", environment: TradeItEmsTestEnv)
                TradeItSDK._marketDataService = marketDataService
                delegate = FakeTradeItSymbolSearchViewControllerDelegate()
                
                window = UIWindow()
                let bundle = TradeItBundleProvider.provide()
                let storyboard: UIStoryboard = UIStoryboard(name: "TradeIt", bundle: bundle)
                
                controller = storyboard.instantiateViewController(withIdentifier: TradeItStoryboardID.symbolSearchView.rawValue) as! TradeItSymbolSearchViewController
                controller.delegate = delegate
                
                nav = UINavigationController(rootViewController: controller)
                
                window.addSubview(nav.view)
                
                flushAsyncEvents()
            }
            
            xdescribe("symbolSearchWasCalledWith") {
                beforeEach {
                    // TODO call the good method
                   //controller.symbolSearchWasCalledWith("MySymbol")
                }
                
                it("performs a symbolLookup on the marketDataService") {
                    expect(marketDataService.calls.forMethod("symbolLookup(_:onSuccess:onFailure:)").count).to(equal(1))
                }
                
                context("when symbolLookup succeeds") {
                    var results: [TradeItSymbolLookupCompany] = []
                    beforeEach {
                        let onSuccess = marketDataService.calls.forMethod("symbolLookup(_:onSuccess:onFailure:)")[0].args["onSuccess"] as! (([TradeItSymbolLookupCompany]) -> Void)
                        let result1 = TradeItSymbolLookupCompany()
                        let result2 = TradeItSymbolLookupCompany()
                        results = [result1, result2]
                        onSuccess(results)
                    }

                    // TODO check if we update the results
//                    it("calls the updateSymbolResults on the symbolSearchTableViewManager with the results") {
//                        let calls = symbolSearchTableViewManager.calls.forMethod("updateSymbolResults(withResults:)")
//                        expect(calls.count).to(equal(1))
//                        
//                        let resultsArg = calls[0].args["symbolResults"] as! [TradeItSymbolLookupCompany]
//                        expect(resultsArg).to(equal(results))
//                        
//                    }
                }
                
                context("when symbolLookup fails") {
                    beforeEach {
                        let onFailure = marketDataService.calls.forMethod("symbolLookup(_:onSuccess:onFailure:)")[0].args["onFailure"] as! ((TradeItErrorResult) -> Void)
                        onFailure(TradeItErrorResult())
                    }
// TODO check if we update the results
//                    it("calls the updateSymbolResults on the symbolSearchTableViewManager with an empty array") {
//                        let calls = symbolSearchTableViewManager.calls.forMethod("updateSymbolResults(withResults:)")
//                        expect(calls.count).to(equal(1))
//                        
//                        let resultArg = calls[0].args["symbolResults"] as! [TradeItSymbolLookupCompany]
//                        expect(resultArg).to(beEmpty())
//                    }
                }
            }
            
            xdescribe("symbolWasSelected") {
                beforeEach {
                    //TODO call the good method
                    //controller.symbolWasSelected("MySelectedSymbol")
                }
                
                it("calls the symbolSearchViewController:didSelectSymbol: method on the delegate with the selected symbol") {
                    let calls = delegate.calls.forMethod("symbolSearchViewController(_:didSelectSymbol:)")
                    expect(calls.count).to(equal(1))
                    
                    let selectedSymbolArg = calls[0].args["didSelectSymbol"] as! String
                    expect(selectedSymbolArg).to(equal("MySelectedSymbol"))
                    
                }
            }
            
        }
    }
}
