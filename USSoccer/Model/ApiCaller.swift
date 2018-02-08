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
import OneSignal

class ApiCaller {
    static let shared = ApiCaller()
    private init () {}
    var currentGamesInFirebaseArray = [[String: Any]]()
    var updatedGamesFromAPIArray = [[String: Any]]()
    
    func gameKey(title: String, date: String) -> String {
        return stringTrimmer(stringToTrim: title + date)!
    }
    
    func ApiCall(completion: @escaping ()->Void) {
        //real call "https://www.parsehub.com/api/v2/projects/tZQ5VDy6j2JB/last_ready_run/data?api_key=trmNdK43wwBZ" "https://www.parsehub.com/api/v2/runs/t1mY9HfR24H5/data?api_key=trmNdK43wwBZ"
        Alamofire.request("https://www.parsehub.com/api/v2/projects/tZQ5VDy6j2JB/last_ready_run/data?api_key=trmNdK43wwBZ").responseJSON { response in
            
            
            
            if ConnectionCheck.isConnectedToNetwork() == false && response.result.value == nil {
                // No data to sync and not connected to network
                // we need to check if some data already exists in the local database
                let games = CoreDataService.shared.fetchGames()
                if games.count == 0 {
                    // Show the alert and possibly try again
                    let _ = UIAlertController.presentOKAlertWithTitle("No Connection", message: "Cannot load any games, please try again later.", okTapped: {
                        self.ApiCall(completion: completion)
                    })
                    return
                }
            }
            
            if let jsonData = response.result.value as? Dictionary<String, AnyObject> {
                guard let data = jsonData["Data"] as? [[String: AnyObject]] else {
                    
                    if ConnectionCheck.isConnectedToNetwork() == false {
                        // No data to sync and not connected to network
                        // we need to check if some data already exists in the local database
                        let games = CoreDataService.shared.fetchGames()
                        if games.count == 0 {
                            // Show the alert and possibly try again
                            let _ = UIAlertController.presentOKAlertWithTitle("No Connection", message: "Cannot load any games, please try again later.", okTapped: {
                                self.ApiCall(completion: completion)
                            })
                            return
                        }
                    } else {
                        
                        // Sync local database
                        self.syncLocalDatabase(completion: completion)
                    }
                    return
                }
                let arrayLength = data.count
                let currentDate = Date()
                
         //       if its been only 3 days sense the lasttime data was updated then move on and load from coredata, else display alert about network error connection errror and needing to update data.
                
                ref.child("LastUpdate").observeSingleEvent(of: .value, with: { (snapShot) in
                    let lastUpdateTimeStamp : Double = snapShot.value as? Double ?? 0.0
                    let lastUpdateDate = Date(timeIntervalSince1970: lastUpdateTimeStamp)
                    
                    ref.child("LastUpdate").setValue(currentDate.timeIntervalSince1970)
                    
                    let thresholdTimeInterval : TimeInterval = 24.0 * 3.0 * 3600.0
                    if currentDate.timeIntervalSince(lastUpdateDate) > thresholdTimeInterval {
                        // It's been more than 3 days
                        messageAlert(title: "Carrier Server Error", message: "Your internet connection is not currently addiquate to update game information, \n\n Game information might be old.", from: nil)
                        completion()
                        return
                    }
                    
                    
                    let dispatchGroup = DispatchGroup()
                    
                    /*
                     "Date": "March 4, 2018",
                     "Time": "12:00 PM ET",
                     */
                    
                    for index in 0..<arrayLength {
                        var currentArray = data[index]
                        let title = currentArray["Title"] as! String
                        let venue = currentArray["Venue"]
                        let time = currentArray["Time"]
                        let date = currentArray["Date"] as! String
                        let stations = (currentArray["Stations"] as? String) ?? "ussoccer.com"
                        let teamSeperated = title.components(separatedBy: "vs")
                        let team = stringTrimmer(stringToTrim: teamSeperated[0])?.uppercased()
                        let formatter = DateFormatter()
                        var castedTime = time as! String
                        
                        if let index = castedTime.index(of: " "), !castedTime.contains(":") {
                            castedTime.insert(contentsOf: [":", "0", "0"], at: index)
                        }
                        let castedDate = date
                        let timeWithoutTimeZoneString = castedTime[..<castedTime.index(castedTime.endIndex, offsetBy: -2)]
                        let dateAndTimeStringWithProperTimeZone = castedDate + " " + timeWithoutTimeZoneString + self.timezoneFromTimeString(timeString: castedTime, dateString: castedDate)
                        
                        // Date parsing, Time parsing
                        formatter.dateFormat = "MMMM dd, yyyy h:mm a ZZZ"
                        let dateFormated = formatter.date(from: dateAndTimeStringWithProperTimeZone)
                        let dict: [String: Any] = ["title": title as Any, "venue": venue as Any, "time": time as Any, "date": date as Any, "stations": stations, "timestamp": dateFormated?.timeIntervalSince1970 as Any, "team": team as Any]
                        self.updatedGamesFromAPIArray.append(dict)
                        
                        dispatchGroup.enter()
                        let gameKey = self.gameKey(title: title, date: date)
                        
                        // Schedule a notification
                        if let team = team, let dateFormated = dateFormated {
                            OneSignal.scheduleAllPushNotificationReminders(toGameTitle: title, team: team, timestamp: dateFormated)
                        }
                       
                        // Save the game to the Firebase
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
    
    
    func updateLocalTeamsNotificationSettings(completion: @escaping ()->Void) {
        
        guard let uid = Auth.auth().currentUser?.uid else { completion(); return }
        
        let group = DispatchGroup()
        
        let teams = CoreDataService.shared.fetchTeams()
        for team in teams {
            guard let title = team.title else { return }
            
            group.enter()
            
            followingRef.child(title).child(uid).observeSingleEvent(of: .value) { (snapshot) in
                if let value = snapshot.value as? Bool {
                    team.notifications = value
                    CoreDataService.shared.saveContext()
                }
                
                group.leave()
            }// End of observation
        }// End of for loop
        
        group.notify(queue: DispatchQueue.main, execute: completion)
    }
    
    
    func syncLocalDatabase(completion: @escaping ()->Void) {
        
        if ConnectionCheck.isConnectedToNetwork() {
            
            gamesRef.observeSingleEvent(of: .value) { snapshot in
                
                DispatchQueue.main.async {
                    
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
                            }
                        }
                    }
                    
                    
                    // All is finished :)
                    completion()
                }
            }
        } else {
            
            // No connection, so we need to call it quits
            completion()
        }
    }
    
    
    func timezoneFromTimeString(timeString: String, dateString: String) -> String {
        
        let justDateString = (dateString as NSString).components(separatedBy: ",").first ?? ""
        
        // Default Eastern Time Zone -0500
        let timeZoneString = (timeString as NSString).substring(from: timeString.count - 2)
        
        // Adjust for Daylight Savings Time
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd"
        let date = formatter.date(from: justDateString)
        
        let fromDate = formatter.date(from: "March 11")
        let toDate = formatter.date(from: "November 4")
        // March 11th November 4th
        var daylightSavingsTime = false
        if let date = date, let fromDate = fromDate, let toDate = toDate {
            if fromDate.timeIntervalSince1970 < date.timeIntervalSince1970 && date.timeIntervalSince1970 < toDate.timeIntervalSince1970 {
                // Daylight Savings Time
                daylightSavingsTime = true
            }
        }
        if daylightSavingsTime {
            
            switch timeZoneString {
            case "ET":
                return "-0400"
            case "CT":
                return "-0500"
            case "MT":
                return "-0600"
            case "PT":
                return "-0700"
            default:
                return "-0400"
            }
        } else {
            
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
}
