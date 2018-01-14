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
    var currentGamesInFirebaseArray = [[String: Any]]()
    var updatedGamesFromAPIArray = [[String: Any]]()
    
    func gameKey(title: String, date: String) -> String {
        return stringTrimmer(stringToTrim: title + date)!
    }
    
    func ApiCall(completion: @escaping ()->Void) {
        
        Alamofire.request("https://www.parsehub.com/api/v2/projects/tZQ5VDy6j2JB/last_ready_run/data?api_key=trmNdK43wwBZ").responseJSON { response in
            
            if let jsonData = response.result.value as? Dictionary<String, AnyObject> {
                guard let data = jsonData["Data"] as? [[String: AnyObject]] else {
                    completion()
                    return
                }
                let arrayLength = data.count
                let currentDate = Date()
                
         //       if its been only 3 days sense the lasttime data was updated then move on and load from coredata, else display alert about network error connection errror and needing to update data.
                
                if data.isEmpty {
                    completion()
                    return
                }
                
                ref.child("LastUpdate").observeSingleEvent(of: .value, with: { (snapShot) in
                    let lastUpdateTimeStamp : Double = snapShot.value as? Double ?? 0.0
                    let lastUpdateDate = Date(timeIntervalSince1970: lastUpdateTimeStamp)
                    
                    ref.child("LastUpdate").setValue(currentDate.timeIntervalSince1970)
                    
                    let thresholdTimeInterval : TimeInterval = 24.0 * 3.0 * 3600.0
                    if currentDate.timeIntervalSince(lastUpdateDate) > thresholdTimeInterval {
                        // It's been more than 3 days
                        //alert here
                        completion()
                        return
                    }
                    
                    
                    let dispatchGroup = DispatchGroup()
                    
                    for index in 0..<arrayLength {
                        var currentArray = data[index]
                        let title = currentArray["Title"] as! String
                        let venue = currentArray["Venue"]
                        let time = currentArray["Time"]
                        let date = currentArray["Date"] as! String
                        let stations = (currentArray["Stations"] as? String) ?? "ussoccer.com"
                        let teamSeperated = title.components(separatedBy: "vs")
                        let team = stringTrimmer(stringToTrim: teamSeperated[0])
                        let formatter = DateFormatter()
                        var castedTime = time as! String
                        
                        if !castedTime.contains(":") {
                            castedTime.insert(contentsOf: [":", "0", "0"], at: castedTime.index(castedTime.startIndex, offsetBy: 1))
                        }
                        let castedDate = date
                        let timeWithoutTimeZoneString = castedTime[..<castedTime.index(castedTime.endIndex, offsetBy: -2)]
                        let dateAndTimeStringWithProperTimeZone = castedDate + " " + timeWithoutTimeZoneString + self.timezoneFromTimeString(timeString: castedTime)
                        
                        // Date parsing, Time parsing
                        formatter.dateFormat = "MMMM dd, yyyy h:mm a ZZZ"
                        let dateFormated = formatter.date(from: dateAndTimeStringWithProperTimeZone)
                        let dict: [String: Any] = ["title": title as Any, "venue": venue as Any, "time": time as Any, "date": date as Any, "stations": stations, "timestamp": dateFormated?.timeIntervalSince1970 as Any, "team": team as Any]
                        self.updatedGamesFromAPIArray.append(dict)
                        
                        dispatchGroup.enter()
                        let gameKey = self.gameKey(title: title, date: date)
                        gamesRef.child(gameKey).observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
                            
                            if let dict = snapshot.value as? [String: Any] {
                                self.currentGamesInFirebaseArray.append(dict)
                            }
                            dispatchGroup.leave()
                        })
                    }
                    
                    
                    // Checking incoming game titles against current games to ensure only new games are written to Firebase & CoreData
                    dispatchGroup.notify(queue: .main) {
                        let titles = (self.currentGamesInFirebaseArray as NSArray).mutableArrayValue(forKey: "title").flatMap({return $0 as? String})
                        // Sync Firebase (add missing f)
                        for dict in self.updatedGamesFromAPIArray {
                            
                            let title = dict["title"] as! String
                            let date = dict["date"] as! String
                            if !titles.contains(title) {
                                
                                let gameKey = self.gameKey(title: title, date: date)
                                gamesRef.child(gameKey).setValue(dict)
                            }
                        }
                        
                        
                        // Sync local database
                        self.syncLocalDatabase(completion: completion)
                    }
                    
                })
                
            }
        }
    }
    
    
    func asdf() {
        
    }
    
    
    func syncLocalDatabase(completion: @escaping ()->Void) {
        gamesRef.observeSingleEvent(of: .value) { snapshot in
            
            let currentGameSnapshots = snapshot.children.allObjects as! [DataSnapshot]
            
            // Check the local database and insert the new ones
            let localGames = CoreDataService.shared.fetchGames()
            let localGameTitles = (localGames as NSArray).mutableArrayValue(forKey: "title")
            for currentGameSnapshot in currentGameSnapshots {
                if let dict = currentGameSnapshot.value as? [String: Any], let title = dict["title"] {
                    if localGameTitles.contains(title) == false {
                        // We don't store this game locally yet
                        // Insert into the local database
                        SoccerGame.insert(snapShot: currentGameSnapshot)
                        //let game = SoccerGame(snapShot: currentGameSnapshot)
                        //print("game.title: \(game.title)")
                    }
                }
            }
            
            
            // All is finished :)
            completion()
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
}
