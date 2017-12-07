//
//  TeamsTVC.swift
//  USSoccer
//
//  Created by Jared Sobol on 12/4/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit

class TeamsTVC: UITableViewCell {
    
    @IBOutlet weak var teamTitle: UILabel!
    @IBOutlet weak var notificationIconBtn: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(selected: Bool) {
        
        if selected {
            notificationIconBtn.image = #imageLiteral(resourceName: "bell-musical-tool")
        } else {
            notificationIconBtn.image = #imageLiteral(resourceName: "musical-bell-outline (1)")
        }
    }

}
