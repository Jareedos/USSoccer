//
//  OneSignalExtension.swift
//  USSoccer
//
//  Created by Jared Sobol on 1/27/18.
//  Copyright © 2018 Appmaker. All rights reserved.
//

import Foundation
import OneSignal
import CoreData
import FirebaseAuth
import FirebaseDatabase

extension OneSignal {
    
    /*
     Game Notifications
     - scheduled locally
     
     Team Notificaitons
     - scheduled from the app to OneSignal upon creating the game (putting the game to Firebase)
       - there will be as many notifications scheduled as there are reminder options
     
     How to prevent doubbling of notifications?
     - Everytime the team notificaion is set to ON, all local notifications of games of that team are cancelled
     - When it's ticked off again, the local notifications for the games that are supposed to be followed are schedled again
     */
    
    static let timeIntervals : [TimeInterval] = [
        2 * 24 * 3600,  // two days
        24 * 3600, // one day
        2 * 3600, // two hours
        3600, // one hour
        1800, // half an hour
    ]
    
    static func updateSubsription(subscription: Bool, team: String, timeIntervalToggles : [Bool]) {
        
        for (i, toggle) in timeIntervalToggles.enumerated() {
            let timeInterval = timeIntervals[i]
            let key = "\(team)\(timeInterval)"
            if subscription && toggle {
                sendTag(key, value: "true")
            } else {
                deleteTag(key)
            }
        }
    }
    
    // FIXME: remove this (only for debug purposes)
    static var notificationSentToTeams = Set<String>()
    
    static func scheduleAllPushNotificationReminders(toGameTitle gameTitle: String, team: String, timestamp: Date) {
        
        // FIXME: remove this (only for debug purposes)
        // To fake it you can use this timestamp variable
        let timestamp = Date().addingTimeInterval(24 * 3600)
        
        for timeInterval in timeIntervals {
            // The key here is the team + time interval in seconds that the Reminder should be fired at
            schedulePushNotification(toGameTitle: gameTitle, team: "\(team)\(timeInterval)", timestamp: timestamp.addingTimeInterval(-timeInterval))
        }
    }
    
    static func schedulePushNotification(toGameTitle gameTitle: String, team: String, timestamp: Date) {
        
        // FIXME: remove this (only for debug purposes)
        if notificationSentToTeams.contains(team) == true {
            return
        }
        notificationSentToTeams.insert(team)
        
        let params : [String : Any] = [
            //"included_segments" : "All Users",
            
            "filters" : [[
             "field": "tag", "key": team, "relation": "exists"
            ]],
                      "contents": ["en": "\(gameTitle) starts in an hour"],
                      //"send_after" : Date().addingTimeInterval(60).description, // Debug - sending the notification one minute from now
                      "send_after" : timestamp.description // The correct schedule time
        ]
        
        postServerNotification(params: params, onSuccess: { result in
            if let result = result {
                print(result)
            }
        }) { (error: Error?) in
            if let error = error {
                print(error)
            }
        }
    }
    
    static func postServerNotification(params: [String: Any], onSuccess: @escaping (_ result: [String: AnyHashable]?)->Void, onFailure: @escaping (_ error: Error?)->Void) {
        
        let request = standardServerRequest(path: "notifications", method: "POST", parameters: params)
        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                onSuccess(json as? [String: AnyHashable])
            } else {
                onFailure(error)
            }
        }
        task.resume()
    }
    
    static func standardServerRequest(path: String, method: String, parameters: [String : Any]) -> URLRequest {
        
        let url = URL(string: "https://onesignal.com/api/v1/" + path)!
        var request = URLRequest(url: url)
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Basic YzA5MTY2YWUtNDY0YS00MWVkLWI4YWEtMWQyYzFkMTAyOTJh", forHTTPHeaderField: "Authorization")
        request.httpMethod = method
        var combinedParams = parameters
        combinedParams["app_id"] = "28bbbff3-5e9e-468c-b99d-beb9d034f404"
        request.httpBody = try? JSONSerialization.data(withJSONObject: combinedParams, options: .prettyPrinted)
       
        return request
    }
    
    
    static func promptPushNotificationAlert() {
        
        guard let user = Auth.auth().currentUser else { return }
        
        // Recommend moving the below line to prompt for push after informing the user about
        //   how your app will use them.
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            
            if accepted {
                
                OneSignal.setSubscription(true)
                
                let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
//                let hasPrompted = status.permissionStatus.hasPrompted
//                let userStatus = status.permissionStatus.status
//                let isSubscribed = status.subscriptionStatus.subscribed
//                let userSubscriptionSetting = status.subscriptionStatus.userSubscriptionSetting

                // This is your device's identification within OneSignal
                guard let userID = status.subscriptionStatus.userId else { return }
                if let person = CoreDataService.shared.fetchPerson(), person.userID != userID {
                    //                           let pushToken = status.subscriptionStatus.pushToken
                    let userRef = Database.database().reference().child("users").child(user.uid)
                    // Set the one signal id
                    
                    userRef.child("oneSignalIds").child(userID).setValue(true)
                    
                    
                    // Save the push notification settings
                    let dict: [String: Bool] = ["TwoDayNotification": false, "OneDayNotification": false, "TwoHourNotification": true, "OneHourNotification": false, "HalfHourNotification": false]
                    userRef.child("notificationSettings").setValue(dict)
                    
                    // Set the following of the teams
                    let teams = CoreDataService.shared.fetchTeams()
                    for team in teams {
                        if let key = team.firebaseKey() {
                            let teamFollowingRef = followingRef.child(key).child(user.uid)
                            if team.notifications {
                                teamFollowingRef.setValue(true)
                            } else {
                                teamFollowingRef.removeValue()
                            }
                        }
                    }
                }
            }
        })
    }
    
}
