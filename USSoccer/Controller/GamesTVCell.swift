//
//  GamesTVCell.swift
//  USSoccer
//
//  Created by Jared Sobol on 11/13/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit

class GamesTVCell: UITableViewCell {
    
    @IBOutlet weak var notificationBtn: UIButton!
    @IBOutlet weak var gameTitleLbl: UILabel!
    @IBOutlet weak var vsLbl: UILabel!
    @IBOutlet weak var opponentLbl: UILabel!
    @IBOutlet weak var gameDateLbl: UILabel!
    @IBOutlet weak var gameTimeLbl: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
