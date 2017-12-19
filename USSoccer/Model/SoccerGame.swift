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
    @NSManaged public var title: String?
    @NSManaged public var date: String?
    @NSManaged public var time: String?
    @NSManaged public var venue: String?
    @NSManaged public var stations: String?
    @NSManaged public var notification: NSNumber?
    @NSManaged public var timestamp: Date?
//    var ref: DataReference?
    var usTeam : String! {
        let teamsTitles = title!.components(separatedBy: "vs")
        let trimmedTitle = stringTrimmer(stringToTrim: teamsTitles[0].uppercased())
        return trimmedTitle
    }
    
    override public init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(snapShot: DataSnapshot) {
        let managedContext = CoreDataService.shared.managedContext
        let entity = NSEntityDescription.entity(forEntityName: "Game", in: managedContext!)!
        super.init(entity: entity, insertInto: managedContext)
        
//        ref = snapShot.ref
        let snapShotValue = snapShot.value as! [String: AnyObject]
        title = snapShotValue["title"] as? String
        date = snapShotValue["date"] as? String
        time = snapShotValue["time"] as? String
        venue = snapShotValue["venue"] as? String
        stations = snapShotValue["stations"] as? String
        if let ts = snapShotValue["timestamp"] as? Double {
            timestamp = Date(timeIntervalSince1970: ts)
        }
        
        try? managedContext?.save()
    }
    
    static func insert(snapShot: DataSnapshot) {
        let managedContext = CoreDataService.shared.managedContext
        let game = NSEntityDescription.insertNewObject(forEntityName: "Game", into: managedContext!) as! SoccerGame
        let snapShotValue = snapShot.value as! [String: AnyObject]
        game.title = snapShotValue["title"] as? String
        game.date = snapShotValue["date"] as? String
        game.time = snapShotValue["time"] as? String
        game.venue = snapShotValue["venue"] as? String
        game.stations = snapShotValue["stations"] as? String
        if let ts = snapShotValue["timestamp"] as? Double {
            game.timestamp = Date(timeIntervalSince1970: ts)
        }
        
        try? managedContext?.save()
    }
    
    init(title: String, date: String, time: String, venue: String, stations: String) {
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
