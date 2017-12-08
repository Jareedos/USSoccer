//
//  ApiCall.swift
//  USSoccer
//
//  Created by Jared Sobol on 11/28/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import Firebase
import CoreData

class ApiCaller{
    static let shared = ApiCaller()
    private init () {}
    var currentGameArray = [SoccerGame]()
    var updatedGameDictArray = [[String: Any]]()
    
    func ApiCall() {
        Alamofire.request("https://www.parsehub.com/api/v2/projects/tZQ5VDy6j2JB/last_ready_run/data?api_key=trmNdK43wwBZ").responseJSON { response in
            
            if let jsonData = response.result.value as? Dictionary<String, AnyObject> {
                let data = jsonData["Data"] as? [[String: AnyObject]]
                let arrayLength = data?.count
                
                let dispatchGroup = DispatchGroup()
                
                for index in 0..<arrayLength! {
                    var currentArray = data![index]
                    let title = currentArray["Title"] as! String
                    let venue = currentArray["Venue"]
                    let time = currentArray["Time"]
                    let date = currentArray["Date"]
                    let stations = (currentArray["Stations"] as? String) ?? "ussoccer.com"
                    let formatter = DateFormatter()
                    var castedTime = time as! String
                    
                    if !castedTime.contains(":") {
                        castedTime.insert(contentsOf: [":", "0", "0"], at: castedTime.index(castedTime.startIndex, offsetBy: 1))
                    }
                    let castedDate = date as! String
                    let timeWithoutTimeZoneString = castedTime[..<castedTime.index(castedTime.endIndex, offsetBy: -2)]
                    let dateAndTimeStringWithProperTimeZone = castedDate + " " + timeWithoutTimeZoneString + self.timezoneFromTimeString(timeString: castedTime)
                    
                    // Date parsing, Time parsing
                    formatter.dateFormat = "MMMM dd, yyyy h:mm a ZZZ"
                    let dateFormated = formatter.date(from: dateAndTimeStringWithProperTimeZone)
                   
                    
                    let dict: [String: Any] = ["title": title as Any, "venue": venue as Any, "time": time as Any, "date": date as Any, "stations": stations, "timestamp": dateFormated?.timeIntervalSince1970 as Any]
                    self.updatedGameDictArray.append(dict)
                    
                    dispatchGroup.enter()
                    gamesRef.child(title).observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
                        
                        if snapshot.exists() {
                            let game = SoccerGame(snapShot: snapshot)
                            self.currentGameArray.append(game)
                        }
                        dispatchGroup.leave()
                    })
                }
                
                
                // Checking incoming game titles against current games to ensure only new games are written to Firebase & CoreData
                dispatchGroup.notify(queue: .main) {
                    let titles = (self.currentGameArray as NSArray).mutableArrayValue(forKey: "title") as! [String]
                    // Sync Firebase (add missing ones)
                    for dict in self.updatedGameDictArray {
                        if !titles.contains(dict["title"] as! String) {
                        
                            gamesRef.childByAutoId().setValue(dict)
                        }
                    }
                    
                    
                    // Sync local database
                    self.syncLocalDatabase()
                }
            }
        }
    }
    
    func syncLocalDatabase() {
        gamesRef.observeSingleEvent(of: .value) { snapshot in
            
            var currentGames = [SoccerGame]()
            
            for child in snapshot.children {
                let game = SoccerGame(snapShot: (child as? DataSnapshot)!)
                currentGames.append(game)
            }
            
            // Check the local database and insert the new ones
            let localGames = CoreDataService.shared.fetchGames()
            let localGameTitles = (localGames as NSArray).mutableArrayValue(forKey: "title")
            for currentGame in currentGames {
                if localGameTitles.contains(currentGame.title) == false {
                    // We don't store this game locally yet
                    // Insert into the local database
                    let game = NSEntityDescription.entity(forEntityName: "Game", in: CoreDataService.shared.managedContext!)!
                    game.setValue(currentGame.title, forKey: "title")
                    game.setValue(currentGame.venue, forKey: "venue")
                    game.setValue(currentGame.time, forKey: "string")
                    game.setValue(false, forKey: "notification")
                    game.setValue(currentGame.date, forKey: "date")
                    game.setValue(currentGame.timestamp, forKey: "timeStamp")
                    CoreDataService.shared.saveContext()
                }
            }
        }
    }
    
    
    func timezoneFromTimeString(timeString: String) -> String {
        // Default Eastern Time Zone -0500
        let timeZoneString = (timeString as NSString).substring(from: timeString.count - 2)
        
        switch timeZoneString {
        case "ET":
            return "-0500"
        case "CT":
            return "-0600"
        case "MT":
            return "-0700"
        case "PT":
            return "-0800"
        default:
            return "-0500"
        }
    }

    func parseJson(json: Any){
        
    }
}
