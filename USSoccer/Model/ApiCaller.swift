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
import FirebaseDatabase
import FirebaseAuth
import CoreData
import OneSignal

class ApiCaller {
    static let shared = ApiCaller()
    private init () {}
    var currentGamesInFirebaseArray = [[String: Any]]()
    var updatedGamesFromAPIArray = [[String: Any]]()
    
    func getFakeResponse() -> [[String: AnyObject]] {
        
        let fakeGameData : [[String: Any]] = [["Date": "March 19, 2018", "Time": "2:00 PM PT", "Title": "U-15 MNT vs Iceland", "Venue": "MAPFRE Stadium; Columbus, Ohio\nFantasy Camp\nMatch Guide", "Stations": "Ticket Info"]]
        return fakeGameData as [[String : AnyObject]]
    }
    
    var isLoadingData: Bool = true {
        didSet {
            if isLoadingData == false {
                timeoutTimer?.invalidate()
            }
        }
    }
    private var completion: (()->Void)?
    var timeoutTimer: Timer?
    @objc func timeoutApiCall() {
        if isLoadingData {
            // We should just let the user in the app
            self.completion?()
        }
    }
    
    func ApiCall(completion: @escaping ()->Void) {
        //real call "https://www.parsehub.com/api/v2/projects/tZQ5VDy6j2JB/last_ready_run/data?api_key=trmNdK43wwBZ" "https://www.parsehub.com/api/v2/runs/t1mY9HfR24H5/data?api_key=trmNdK43wwBZ"
        
        // Timeout
        self.completion = completion
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(timeoutApiCall), userInfo: nil, repeats: false)
        
        
        Alamofire.request("https://www.parsehub.com/api/v2/projects/tZQ5VDy6j2JB/last_ready_run/data?api_key=trmNdK43wwBZ").responseJSON { response in
            
            
            if ConnectionCheck.isConnectedToNetwork() == false && response.result.value == nil {
                // No data to sync and not connected to network
                // we need to check if some data already exists in the local database
                let games = CoreDataService.shared.fetchGames()
                if games.count == 0 {
                    DispatchQueue.main.async {
                        self.timeoutTimer?.invalidate()
                        
                        // Show the alert and possibly try again
                        let _ = UIAlertController.presentOKAlertWithTitle("No Internet Connection", message: "Cannot load any games, please try again later.", okTapped: {
                            self.ApiCall(completion: completion)
                        })
                    }
                    return
                }
            }
            
            if let jsonData = response.result.value as? Dictionary<String, AnyObject> {
                // FIXME: rename data2 to data
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
                // FIXME: remove this line (only for debugging purposes)
                //let data = self.getFakeResponse()
                
                let arrayLength = data.count
                let currentDate = Date()
                
                ref.child("LastAPIUpdate").observeSingleEvent(of: .value, with: { (snapShot) in
                    //let lastUpdateTimeStamp : Double = snapShot.value as? Double ?? 0.0
                    //let lastUpdateDate = Date(timeIntervalSince1970: lastUpdateTimeStamp)
                    
                    //let thresholdTimeInterval : TimeInterval = 24.0 * 3600.0
//                    if currentDate.timeIntervalSince(lastUpdateDate) < thresholdTimeInterval {
                        self.syncLocalDatabase(completion: completion)
//                        return
//                    }
                    //keep "LastUpdate" for older version of app
                    ref.child("LastUpdate").setValue(currentDate.timeIntervalSince1970)
                    ref.child("LastAPIUpdate").setValue(currentDate.timeIntervalSince1970)
                    
                    let dispatchGroup = DispatchGroup()
                    for index in 0..<arrayLength {
                        var currentArray = data[index]
                        let title = currentArray["Title"] as! String
                        let venue = currentArray["Venue"]
                        let time = currentArray["Time"]
                        let date = currentArray["Date"] as! String
                        var stations = (currentArray["Stations"] as? String) ?? "ussoccer.com"
                        let fixedTitle = title.replacingOccurrences(of: "VS", with: "vs")
                        let teamSeperated = fixedTitle.components(separatedBy: "vs")
                        let team = stringTrimmer(stringToTrim: teamSeperated[0])?.uppercased()
                        let formatter = DateFormatter()
                        var castedTime = time as! String
                        
                        if stations.contains("Ticket Info | Buy Tickets\n") {
                           stations = stations.replacingOccurrences(of: "Ticket Info | Buy Tickets\n", with: "")
                            if stations.isEmpty {
                                stations = "Not Yet Determined"
                            }
                        } else if stations.contains("Ticket Info") {
                            stations = stations.replacingOccurrences(of: "Ticket Info", with: "")
                            if stations.isEmpty {
                                stations = "Not Yet Determined"
                            }
                        } else if stations.contains("Buy Tickets") {
                            stations = stations.replacingOccurrences(of: "Buy Tickets", with: "")
                            if stations.isEmpty {
                                stations = "Not Yet Determined"
                            }
                        }
                        
                       
                        if team == "WNT" && stations == "ussoccer.com"  || team == "MNT" && stations == "ussoccer.com"{
                            //Skip this game (the channel hasn't been confirmed yet)
                            continue
                        }
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
                       
                        // Save the game to the Firebase
                        gamesRef.child(gameKey).observeSingleEvent(of: .value, with: { (snapshot: DataSnapshot) in
                            
                            if let dict = snapshot.value as? [String: Any] {
                                self.currentGamesInFirebaseArray.append(dict)
                            } else {
                                // The game doesn't exist in Firebase yet
                                
                                // Schedule a notification
                                if let team = team, let dateFormated = dateFormated {
                                    ReminderService.shared.scheduleAllPushNotificationReminders(toGameKey: gameKey, gameTitle: title, team: team, timestamp: dateFormated)
                                }
                            }
                            dispatchGroup.leave()
                        })
                    }
                    
                    
                    // Checking incoming game titles against current games to ensure only new games are written to Firebase & CoreData
                    dispatchGroup.notify(queue: .main) {
                        //let titles = (self.currentGamesInFirebaseArray as NSArray).mutableArrayValue(forKey: "title").flatMap({return $0 as? String})
                        // Sync Firebase (add missing f)
                        for dict in self.updatedGamesFromAPIArray {
                            
                            let title = dict["title"] as! String
                            let date = dict["date"] as! String
                            //if !titles.contains(title) {
                                
                                let gameKey = SoccerGame.gameKey(title: title, date: date)
                                gamesRef.child(gameKey).updateChildValues(dict)
                            //}
                            
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
                
                // TODO: update the local games
                
                DispatchQueue.main.async {
                    
                    let currentGameSnapshots = snapshot.children.allObjects as! [DataSnapshot]
                    
                    // Check the local database and insert the new ones
                    let localGames = CoreDataService.shared.fetchGames()
                    var localGamesByKey = [String : SoccerGame]()
                    for game in localGames {
                        localGamesByKey[game.gameKey] = game
                    }
                    for currentGameSnapshot in currentGameSnapshots {
                        
                        if let dict = currentGameSnapshot.value as? [String: Any] {
                            
                            let gameKey = SoccerGame.gameKey(title: dict["title"] as? String ?? "", date: dict["date"] as? String ?? "")
                            if let game = localGamesByKey[gameKey] {
                                // Update the existing game
                                game.stations = dict["stations"] as? String
                                game.venue = dict["venue"] as? String
                                CoreDataService.shared.saveContext()
                            } else {
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
        
        if timeZoneString == "ET" {
            print("")
        }
        switch timeZoneString {
        case "ET":
            timeZoneString = "America/New_York"
        case "CT":
            timeZoneString = "America/Chicago"
        case "MT":
            timeZoneString = "America/Denver"
        case "PT":
            timeZoneString = "America/Los_Angeles"
        default:
            break
        }
        
        // Adjust for Daylight Savings Time
        guard let zone = TimeZone(identifier: timeZoneString) else {
            return "-0400"
        }
        formatter.dateFormat = "ZZZ"
        var components = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: dateFormated)
        components.timeZone = zone
        var calendar = Calendar(identifier: Calendar.current.identifier)
        calendar.timeZone = zone
        if let date = calendar.date(from: components) {
            let numberOfHoursFromGMT = zone.secondsFromGMT(for: date) / 3600
            if numberOfHoursFromGMT < 0 {
                return "-0\(-numberOfHoursFromGMT)00"
            } else {
                return "+0\(numberOfHoursFromGMT)00"
            }
        } else {
            return "-0400"
        }
        
    }
}
