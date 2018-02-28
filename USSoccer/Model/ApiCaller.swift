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
    
    func getFakeResponse() -> [[String: AnyObject]] {
        
        let fakeGameData : [[String: Any]] = [["Date": "February 28, 2018", "Time": "9:00 AM PT", "Title": "U-17 MNT vs Paru", "Venue": "MAPFRE Stadium; Columbus, Ohio", "Stations": "Ticket Info | Buy Tickets\nESPN2"], ["Date": "February 28, 2018", "Time": "10:30 AM PT", "Title": "U-20 MNT VS Sweden", "Venue": "MAPFRE Stadium; Columbus, Ohio", "Stations": "Ticket Info | Buy Tickets\nESPN2"]]
      //let fakeGameData1 = ["Data": [["Date": "February 18, 2018", "Time": "9:30 AM PT", "Title": "U-17 MNT VS Spain", "Venue": "MAPFRE Stadium; Columbus, Ohio", "Stations": "Ticket Info | Buy Tickets\nESPN2"]]]
    //  let fakeGameData2 = ["Data": [["Date": "February 18, 2018", "Time": "10:00 AM PT", "Title": "U-17 MNT VS Canada", "Venue": "MAPFRE Stadium; Columbus, Ohio", "Stations": "Ticket Info | Buy Tickets\nESPN2"]]]
       // let fakeGameData : [[String: Any]] = [["Date": "February 18, 2018", "Time": "11:00 AM PT", "Title": "U-23 MNT vs China", "Venue": "MAPFRE Stadium; Columbus, Ohio", "Stations": "Ticket Info | Buy Tickets\nESPN2"]]
        
        return fakeGameData as [[String : AnyObject]]
    }
    
    
    func ApiCall(completion: @escaping ()->Void) {
        //real call "https://www.parsehub.com/api/v2/projects/tZQ5VDy6j2JB/last_ready_run/data?api_key=trmNdK43wwBZ" "https://www.parsehub.com/api/v2/runs/t1mY9HfR24H5/data?api_key=trmNdK43wwBZ"
        
        // TImeout
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0) {
            if g_isLoadingData {
                // We should just let the user in the app
                completion()
            }
        }
        
        
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
                // FIXME: rename data2 to data
                guard let data2 = jsonData["Data"] as? [[String: AnyObject]] else {
                    
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
                // FIXME: remove this line (only for debugging purposes)
                let data = self.getFakeResponse()
                
                let arrayLength = data.count
                let currentDate = Date()
                
         //       if its been only 3 days sense the lasttime data was updated then move on and load from coredata, else display alert about network error connection errror and needing to update data.
                
                ref.child("LastUpdate").observeSingleEvent(of: .value, with: { (snapShot) in
                    let lastUpdateTimeStamp : Double = snapShot.value as? Double ?? 0.0
                    let lastUpdateDate = Date(timeIntervalSince1970: lastUpdateTimeStamp)
                    
                    ref.child("LastUpdate").setValue(currentDate.timeIntervalSince1970)
                    
                    let thresholdTimeInterval : TimeInterval = 24.0 * 3600.0
                    if currentDate.timeIntervalSince(lastUpdateDate) < thresholdTimeInterval {
                        // It's been less than a day
                        //messageAlert(title: "Carrier Server Error", message: "Your internet connection is not currently addiquate to update game information, \n\n Game information might be old.", from: nil)
                        self.syncLocalDatabase(completion: completion)
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
                        let fixedTitle = title.replacingOccurrences(of: "VS", with: "vs")
                        let teamSeperated = fixedTitle.components(separatedBy: "vs")
                        let team = stringTrimmer(stringToTrim: teamSeperated[0])?.uppercased()
                        let formatter = DateFormatter()
                        var castedTime = time as! String
                        if castedTime == "TBD" || date == "TBD" {
                            // Skip this game (the time hasn't been confirmed)
                            continue
                        }
                        
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
                        let gameKey = SoccerGame.gameKey(title: title, date: date)
                        
                        // Schedule a notification
                        if let team = team, let dateFormated = dateFormated {
                            ReminderService.shared.scheduleAllPushNotificationReminders(toGameKey: gameKey, gameTitle: title, team: team, timestamp: dateFormated)
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
                                
                                let gameKey = SoccerGame.gameKey(title: title, date: date)
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
                    let localGameKeys = localGames.map({ $0.gameKey })
                    for currentGameSnapshot in currentGameSnapshots {
                        
                        if let dict = currentGameSnapshot.value as? [String: Any] {
                            
                            let gameKey = SoccerGame.gameKey(title: dict["title"] as? String ?? "", date: dict["date"] as? String ?? "")
                            if localGameKeys.contains(gameKey) == false {
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
        
        let timeWithoutTimeZoneString = timeString[..<timeString.index(timeString.endIndex, offsetBy: -2)]
        let dateAndTimeStringWithProperTimeZone = dateString + " " + timeWithoutTimeZoneString
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy h:mm a "
        guard let dateFormated = formatter.date(from: dateAndTimeStringWithProperTimeZone) else {
            return "-0400"
        }
        
        // Default Eastern Time Zone -0500
        var timeZoneString = (timeString as NSString).substring(from: timeString.count - 2)
        
        let index = timeZoneString.index(timeZoneString.startIndex, offsetBy: 1)
        timeZoneString.insert("S", at: index)
        
        // Adjust for Daylight Savings Time
        let zone = TimeZone(identifier: "PST")
        formatter.dateFormat = "ZZZ"
        var components = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: dateFormated)
        components.timeZone = zone
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        } else {
            return "-0400"
        }
        
    }
}
