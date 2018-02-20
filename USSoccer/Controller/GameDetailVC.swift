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
    @IBOutlet weak var gameView: UIView!
    @IBOutlet weak var dateView: UIView!
    @IBOutlet weak var channelView: UIView!
    @IBOutlet weak var locationView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Game Details"
        gameTitleLbl.text = soccerGame.title!.uppercased()
        gameDateLbl.text = soccerGame.date!.uppercased()
        gameView.layer.borderColor = UIColor.white.cgColor
        gameView.layer.borderWidth = 2.5
        gameView.layer.cornerRadius = 10
        gameView.layer.masksToBounds = true
        dateView.layer.borderColor = UIColor.white.cgColor
        dateView.layer.borderWidth = 2.5
        dateView.layer.cornerRadius = 10
        dateView.layer.masksToBounds = true
        channelView.layer.borderColor = UIColor.white.cgColor
        channelView.layer.borderWidth = 2.5
        channelView.layer.cornerRadius = 10
        channelView.layer.masksToBounds = true
        locationView.layer.borderColor = UIColor.white.cgColor
        locationView.layer.borderWidth = 2.5
        locationView.layer.cornerRadius = 10
        locationView.layer.masksToBounds = true
        let date = soccerGame.timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        let strDate = dateFormatter.string(from: date!)
        gameTimeLbl.text = strDate.uppercased()
        if soccerGame.stations == "ussoccer.com" {
            gameStaionsLbl.text = soccerGame.stations
        } else if (soccerGame.stations?.contains("Tickets"))! {
            var stationComponents = soccerGame.stations!.components(separatedBy: "Tickets")
            let removingSlash = stationComponents[1].replacingOccurrences(of: "\n", with: "")
            gameStaionsLbl.text = removingSlash
        } else {
            gameStaionsLbl.text = soccerGame.stations
        }
        var venueComponents = soccerGame.venue!.components(separatedBy: ";")
        let removeFantasyCamp = venueComponents[1].replacingOccurrences(of: "\nFantasy Camp", with: "")
        let removeMatchGuide = removeFantasyCamp.replacingOccurrences(of: "\nMatch Guide", with: "")
        gameVenueLbl.text = venueComponents[0]
        gameVenueCityState.text = removeMatchGuide
    }
}
