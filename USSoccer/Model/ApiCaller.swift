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

class ApiCaller{
    static let shared = ApiCaller()
    private init () {}
    var currentGameArray = [String]()
    
    func ApiCall() {
        Alamofire.request("https://www.parsehub.com/api/v2/projects/tZQ5VDy6j2JB/last_ready_run/data?api_key=trmNdK43wwBZ").responseJSON { response in
       
            if let jsonData = response.result.value as? Dictionary<String, AnyObject> {
//                print("JSON: \(jsonData)") // serialized json response
//                self.parseJson(json: jsonData)
                let data = jsonData["Data"] as? [[String: AnyObject]]
                let arrayLength = data?.count
                for index in 0..<arrayLength! {
                    var currentArray = data![index] as? [String: Any]
//                    print("THIS IS A GAME")
                    let title = currentArray!["Title"]
//                    print(title)
                    let venue = currentArray!["Venue"]
//                    print(venue)
                    let time = currentArray!["Time"]
//                    print(time)
                    let date = currentArray!["Date"]
//                    print(date)
                    let stations = currentArray!["Stations"] ?? "ussoccer.com"
//                    print(stations)
//                    print("^^^^^^^^^^^^^^^^^^^^^")
//                    print("\n")
                    let formatter = DateFormatter()
                    var castedTime = time as! String
                    if !castedTime.contains(":") {
                        castedTime.insert(contentsOf: [":", "0", "0"], at: castedTime.index(castedTime.startIndex, offsetBy: 1))
                    }
                    let castedDate = date as! String
                        //let timeWithoutTimeZoneString = (castedTime).substring(to: castedTime.index(castedTime.endIndex, offsetBy: -2))
                        let timeWithoutTimeZoneString = castedTime[..<castedTime.index(castedTime.endIndex, offsetBy: -2)]
                        let dateAndTimeStringWithProperTimeZone = castedDate + " " + timeWithoutTimeZoneString + self.timezoneFromTimeString(timeString: castedTime)
                        
                        // Date parsing, Time parsing
                        formatter.dateFormat = "MMMM dd, yyyy h:mm a ZZZ"
                        let dateFormated = formatter.date(from: dateAndTimeStringWithProperTimeZone)
                        assert(dateFormated != nil)
                        let dispatchGroup = DispatchGroup()
                        dispatchGroup.enter()
                    gamesRef.observe(.value, with: { snapshot in
                        for child in snapshot.children {
                            let game = SoccerGame(snapShot: (child as? DataSnapshot)!)
                            self.currentGameArray.append(game.title)
                            
                        }
                        dispatchGroup.leave()
                    })
                    // Checking incoming game titles against current Games to ensure only new games are written to firebase
                    dispatchGroup.notify(queue: .main) {
                        if !self.currentGameArray.contains(title as! String) {
                            let dict: [String: Any] = ["title": title as Any, "venue": venue as Any, "time": time as Any, "date": date as Any, "stations": stations, "timestamp": dateFormated?.timeIntervalSince1970 as Any]
                            gamesRef.childByAutoId().setValue(dict)
                        }
                    }
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

    func writeGameToFirebase(){
        
    }
    func parseJson(json: Any){
        
    }
}
