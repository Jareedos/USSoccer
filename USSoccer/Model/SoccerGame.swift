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
    
    var usTeam : String! {
        let changedTitle = title!.replacingOccurrences(of: "VS", with: "vs")
        let teamsTitles = changedTitle.components(separatedBy: "vs")
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
    
    
    var gameKey : String {
        return SoccerGame.gameKey(title: title ?? "", date: date ?? "")
    }
    
    static func gameKey(title: String, date: String) -> String {
        return firebaseCompatibleString(fromString: title + date)!
    }
    
    
    /**
     Artificial sorting function - we're determining how high should the game appear in the list
     The higher the number, the more to the top it should be displayed
     */
    func order() -> Double {
        if let timestamp = timestamp {
            let now = Date()
            // Check if the timestamp is in the past
            if timestamp.compare(now) == .orderedAscending {
                return timestamp.timeIntervalSince1970 * 2
            } else {
                // It's in the future
                return timestamp.timeIntervalSince1970
            }
        } else {
            return 0
        }
    }
    
    func isInThePast() -> Bool {
        if let timestamp = timestamp {
            let now = Date()
            // Check if the timestamp is in the past
            if timestamp.compare(now) == .orderedAscending {
                return true
            } else {
                return false
            }
        }
        return true
    }
    
}
