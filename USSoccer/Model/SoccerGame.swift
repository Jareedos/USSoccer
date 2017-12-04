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
import CoreData

@objc(SoccerGame)
public class SoccerGame: NSManagedObject  {
    let title: String = ""
    let date: String = ""
    let time: String = ""
    let venue: String = ""
    let stations: String = ""
    var notification: Bool = false
    var timestamp: Date?
//    var ref: DataReference?
    var usTeam : String! {
        let teamsTitles = title.components(separatedBy: "vs")
        let trimmedTitle = stringTrimmer(stringToTrim: teamsTitles[0].uppercased())
        return trimmedTitle
    }
    
    
    init(snapShot: DataSnapshot) {
        let managedContext = CoreDataService.shared.managedContext
        let entity = NSEntityDescription.entity(forEntityName: "Game", in: managedContext!)!
        super.init(entity: entity, insertInto: managedContext)
        
//        ref = snapShot.ref
        let snapShotValue = snapShot.value as! [String: AnyObject]
        title = snapShotValue["title"] as! String
        date = snapShotValue["date"] as! String
        time = snapShotValue["time"] as! String
        venue = snapShotValue["venue"] as! String
        stations = snapShotValue["stations"] as! String
        if let ts = snapShotValue["timestamp"] as? Double {
            timestamp = Date(timeIntervalSince1970: ts)
        }
    }
    
    init(title: String, date: String, time: String, venue: String, stations: String ) {
        let managedContext = CoreDataService.shared.managedContext
        let entity = NSEntityDescription.entity(forEntityName: "Game", in: managedContext!)!
        super.init(entity: entity, insertInto: managedContext)
        self.stations = stations
        self.title = title
        self.date = date
        self.time = time
        self.venue = venue
    }
    
    
}
