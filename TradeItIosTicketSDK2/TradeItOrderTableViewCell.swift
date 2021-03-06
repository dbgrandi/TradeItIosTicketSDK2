import UIKit

class TradeItOrderTableViewCell: UITableViewCell {
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var expirationLabel: UILabel!
    @IBOutlet weak var orderTypeDescriptionLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var indentationIconView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func populate(
        withOrderStatusDetailsPresenter orderStatusPresenter: TradeItOrderStatusDetailsPresenter
    ) {
        self.symbolLabel?.text = orderStatusPresenter.getSymbol()
        self.descriptionLabel?.text = orderStatusPresenter.getFormattedDescription()
        self.expirationLabel.text = orderStatusPresenter.getFormattedExpiration()
        self.orderTypeDescriptionLabel.text = orderStatusPresenter.getFormattededOrderTypeDescription()
        if !orderStatusPresenter.belongsToOpenCategory() {
            self.statusLabel.text = orderStatusPresenter.getFormattedStatus()
        } else {
            self.statusLabel.text = ""
        }

        if orderStatusPresenter.isGroupOrderChild {
            self.indentationIconView.isHidden = false
        } else {
            self.indentationIconView.isHidden = true
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
