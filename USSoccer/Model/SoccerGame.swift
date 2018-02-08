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
    
    init?(snapShot: DataSnapshot) {let snapShotValue = snapShot.value as! [String: AnyObject]
        
        guard let title = snapShotValue["title"] as? String,
            let date = snapShotValue["date"] as? String,
            let time = snapShotValue["time"] as? String,
            let venue = snapShotValue["venue"] as? String,
            let stations = snapShotValue["stations"] as? String else {
                return nil
        }
        
        let managedContext = CoreDataService.shared.managedContext
        let entity = NSEntityDescription.entity(forEntityName: "Game", in: managedContext!)!
        super.init(entity: entity, insertInto: managedContext)
        
        self.title = title
        self.date = date
        self.time = time
        self.venue = venue
        self.stations = stations
        if let ts = snapShotValue["timestamp"] as? Double {
            timestamp = Date(timeIntervalSince1970: ts)
        }
        
        try? managedContext?.save()
    }
    
    static func insert(snapShot: DataSnapshot) {
        let snapShotValue = snapShot.value as! [String: AnyObject]
        
        guard let title = snapShotValue["title"] as? String,
        let date = snapShotValue["date"] as? String,
        let time = snapShotValue["time"] as? String,
        let venue = snapShotValue["venue"] as? String,
            let stations = snapShotValue["stations"] as? String else {
                return
        }
        
        let managedContext = CoreDataService.shared.managedContext
        let game = NSEntityDescription.insertNewObject(forEntityName: "Game", into: managedContext!) as! SoccerGame
        game.title = title
        game.date = date
        game.time = time
        game.venue = venue
        game.stations = stations
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
        
        try? managedContext?.save()
    }
    
    func isPlaceholder() -> Bool {
        if title == "No Upcoming Games" || title == "Internet Access Required!" {
            return true
        }
        return false
    }
    
    
}
