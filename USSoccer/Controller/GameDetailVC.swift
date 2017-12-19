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
    @IBOutlet weak var gameVenueCityState: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Game Details"
        gameTitleLbl.text = soccerGame.title!.uppercased()
        gameDateLbl.text = soccerGame.date!.uppercased()
        let date = soccerGame.timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        let strDate = dateFormatter.string(from: date!)
        gameTimeLbl.text = strDate.uppercased()
        if soccerGame.stations == "ussoccer.com" {
            gameStaionsLbl.text = soccerGame.stations
        } else {
            var stationComponents = soccerGame.stations!.components(separatedBy: "Tickets")
            let removingSlash = stationComponents[1].replacingOccurrences(of: "\n", with: "")
            gameStaionsLbl.text = removingSlash
        }
        var venueComponents = soccerGame.venue!.components(separatedBy: ";")
        let removeFantasyCamp = venueComponents[1].replacingOccurrences(of: "\nFantasy Camp", with: "")
        gameVenueLbl.text = venueComponents[0]
        gameVenueCityState.text = removeFantasyCamp
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
