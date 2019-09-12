import UIKit

class TradeItYahooNavigationController: UINavigationController {
    var navigationBarHeight: CGFloat {
        get {
            return self.navigationBar.frame.height + UIApplication.shared.statusBarFrame.height
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupFuji()
    }

    private func setupFuji() {
        self.navigationBar.barTintColor = UIColor(named: "overlayChromeBackground")
        self.navigationBar.tintColor = UIColor(named: "button")
        self.navigationBar.titleTextAttributes = [ NSAttributedString.Key.foregroundColor: UIColor(named: "primaryText") ]

        self.navigationBar.isTranslucent = false
        self.navigationBar.barStyle = .default
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
}
