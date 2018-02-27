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
    
    // FIXME: remove this (only for debug purposes)
    //static var notificationSentToTeams = Set<String>()
    
    static func schedulePushNotification(title: String, text: String, tags: [String], timestamp: Date, data: [String: Any]? = nil) {
        
        // FIXME: remove this (only for debug purposes)
        /*
        if notificationSentToTeams.contains(tag) == true {
            return
        }
        notificationSentToTeams.insert(tag)*/
        
        let orOperator = ["operator": "OR"]
        
        var filters = [[String : Any]]()
        for tag in tags {
            filters.append([
                "field": "tag", "key": tag, "relation": "exists"
            ])
            filters.append(orOperator)
        }
        // Remove the last OR operator
        filters.removeLast()
        
        
//        print("sending to tag \(tag)")
        
        var params : [String : Any] = [
            //"included_segments" : "All Users",
            
            "filters" : filters,
                      "contents": ["en": text],
                      "headings": ["en": title],
                      //"subtitle": ["en": subtitle],
                      //"send_after" : Date().addingTimeInterval(60).description, // Debug - sending the notification one minute from now
                      "send_after" : timestamp.description // The correct schedule time
        ]
        params["data"] = data
        
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
        
        OneSignal.add(NotificationService.shared)
        
        // Recommend moving the below line to prompt for push after informing the user about
        //   how your app will use them.
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            
            let userRef = Database.database().reference().child("users").child(user.uid)
            
            //if accepted {
                
                OneSignal.setSubscription(true)
            
//                let hasPrompted = status.permissionStatus.hasPrompted
//                let userStatus = status.permissionStatus.status
//                let isSubscribed = status.subscriptionStatus.subscribed
//                let userSubscriptionSetting = status.subscriptionStatus.userSubscriptionSetting

                // This is your device's identification within OneSignal
            
            //}
            
            
            
            // Save the default push notification settings
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
        })
    }
    
}
