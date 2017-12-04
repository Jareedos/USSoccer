//
//  GameDetailVC.swift
//  USSoccer
//
//  Created by Jared Sobol on 11/29/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit

class GameDetailVC: UIViewController {
    var soccerGame: SoccerGame!

    @IBOutlet weak var gameTitleLbl: UILabel!
    @IBOutlet weak var gameDateLbl: UILabel!
    @IBOutlet weak var gameTimeLbl: UILabel!
    @IBOutlet weak var gameStaionsLbl: UILabel!
    @IBOutlet weak var gameVenueLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Game Details"
        gameTitleLbl.text = soccerGame.title
        gameDateLbl.text = soccerGame.date
        gameTimeLbl.text = soccerGame.time
        gameStaionsLbl.text = soccerGame.stations
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
