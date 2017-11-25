//
//  SoccerGame.swift
//  USSoccer
//
//  Created by Jared Sobol on 10/4/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import Foundation
//import Alamofire
import FirebaseDatabase


class SoccerGame {
    let title: String!
    let date: String!
    let time: String!
    let venue: String!
    var timestamp: Date?
//    var ref: DataReference?
    var usTeam : String! {
        let teamsTitles = title.components(separatedBy: "vs")
        let trimmedTitle = stringTrimmer(stringToTrim: teamsTitles[0].uppercased())
        return trimmedTitle
    }
    
    
    init(snapShot: DataSnapshot) {
//        ref = snapShot.ref
        let snapShotValue = snapShot.value as! [String: AnyObject]
        title = snapShotValue["title"] as! String
        date = snapShotValue["date"] as! String
        time = snapShotValue["time"] as! String
        venue = snapShotValue["venue"] as! String
        if let ts = snapShotValue["timestamp"] as? Double {
            timestamp = Date(timeIntervalSince1970: ts)
        }
    }
    
    init(title: String, date: String, time: String, venue: String ) {
        self.title = title
        self.date = date
        self.time = time
        self.venue = venue
    }
}
