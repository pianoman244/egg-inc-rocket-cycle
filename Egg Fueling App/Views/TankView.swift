//
//  RocketTankView.swift
//  Egg Fueling App
//
//  Created by Nathan Chasse on 7/14/21.
//

import UIKit

class TankView: UIView {
    
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var imageButton: UIButton!
    
    var linkedTank: StorageTank?
    var linkedFuelID: Int?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("TankView", owner: self, options: nil)
        addSubview(mainView)
        mainView.frame = self.bounds
        mainView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageButton.contentMode = .center
        imageButton.imageView?.contentMode = .scaleAspectFit
    }
}
