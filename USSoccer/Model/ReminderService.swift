//
//  ReminderService.swift
//  USSoccer
//
//  Created by Jared Sobol on 2/8/18.
//  Copyright © 2018 Appmaker. All rights reserved.
//

import Foundation
import OneSignal

class ReminderService {
    
    // TODO: we can represent all these toggles and such in a single nice class array
    // nice to have
    /*class ScheduleIntervalToggle {
        isOn
    }*/
    
    // MARK: - Singleton
    static let shared = ReminderService()
    private init() {}
    
    // MARK: - Properties
    
    var twoDayBool = false
    var oneDayBool = false
    var twoHourBool = true
    var oneHourBool = false
    var halfHourBool = false
    
    var intervalToggles : [Bool] {
        return [self.twoDayBool, self.oneDayBool, self.twoHourBool, self.oneHourBool, self.halfHourBool]
    }
    
    let timeIntervalDescriptions = [
        "two days",
        "one day",
        "two hours",
        "one hour",
        "half an hour"
    ]
    
    let timeIntervals : [TimeInterval] = [
        2 * 24 * 3600,  // two days
        24 * 3600, // one day
        2 * 3600, // two hours
        3600, // one hour
        1800, // half an hour
    ]
    
    // MARK: - Methods
    
    /**
     This method should be used when the user changes the subscription to a team notifications
     */
    func updateSubsription(selectedTeams: [String : Bool]) {
        var tags = [String : String]()
        
        for (_, element) in selectedTeams.enumerated() {
            let isSelected = element.value
            let team = element.key
            
            // Subscribing to tags of the selected time intervals
            for (i, toggle) in intervalToggles.enumerated() {
                let timeInterval = timeIntervals[i]
                let key = self.key(team: team, timeInterval: timeInterval)
                if isSelected && toggle {
                    tags[key] = "true"
                } else {
                    tags[key] = ""
                }
            }
            
            // We have to prevent duplicity notifications for games
            // We are cancelling either way, because in case we are scheduling again
            cancelAllScheduledLocalNotifications(ofTeam: team)
            
            if isSelected == false {
                // When the team notification is off, the local notification for each game is enough
                scheduleLocalNotificationsForAllSelectedGames(ofTeam: team)
            }
        }
        
        
        OneSignal.sendTags(tags, onSuccess: { (result) in
            
        }) { (error: Error?) in
            
        }
    }
    
    func key(team: String, timeInterval: TimeInterval) -> String {
        return "\(team)\(Int(timeInterval))"
    }
    
    
    /**
     Schedules all notifications for selelected games of a team, it also takes the time intervals into account.
     */
    func scheduleLocalNotificationsForAllSelectedGames(ofTeam team: String) {
        let games = CoreDataService.shared.fetchGames()
        for game in games {
            if let notification = game.notification, notification.boolValue {
                // Schedule
                scheduleAllLocalNotifications(forGame: game)
            }
        }// end loop through games
    }
    
    
    /**
     Cancels all scheduled local notifications for a given game
     */
    func cancelAllSchduledLocalNotifications(ofGame game: SoccerGame) {
        
        var identifiers = [String]()
        // Generate identifiers for all time intervals
        for timeInterval in timeIntervals {
            let identifier = self.key(team: game.usTeam, timeInterval: timeInterval)
            identifiers.append(identifier)
        }
        
        // Cancel these notifications (some of which may not exist)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    /**
     Cancels all scheduled ones
     */
    func cancelAllScheduledLocalNotifications(ofTeam team: String) {
        
        // Get all the scheduled local notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
            
            var identifiers = [String]()
            
            // Select those that contain the same team
            for request in requests {
                if (request.identifier as NSString).contains(team) {
                    // Same team
                    identifiers.append(request.identifier)
                }
            }
            
            // Cancel these notifications
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        } //
    }
    
    
    /**
     Schedules all local notifications for a given game
     */
    func scheduleAllLocalNotifications(forGame game: SoccerGame) {
        
        for (i, _) in timeIntervals.enumerated() {
            // If enabled
            if intervalToggles[i] {
                scheduleLocalNotification(forGame: game, timeIntervalIndex: i)
            }
        }// end loop through time intervals
    }
    
    /**
     Schedules a single local notification for a given game at a give time interval before the start of the game
     */
    func scheduleLocalNotification(forGame game: SoccerGame, timeIntervalIndex: Int) {
        guard let timestamp = game.timestamp, let title = game.title, let date = game.date else { return }
        
        // Schedule a local notification
        let content = UNMutableNotificationContent()
        content.title = notificationTitle()
        content.body = notificationText(forGameTitle: title, timeIntervalIndex: timeIntervalIndex)
        content.userInfo = [
            "action" : NotificationAction.openGame.rawValue,
            "gameKey" : SoccerGame.gameKey(title: title, date: date)
        ]
        //
        //let reminderTimestamp = timestamp.addingTimeInterval(-timeIntervals[timeIntervalIndex])
        // FIXME:
        let reminderTimestamp = Date().addingTimeInterval(60)
        
        let components = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: reminderTimestamp)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let identifier = self.key(team: game.title!, timeInterval: timeIntervals[timeIntervalIndex])
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error: Error?) in
            if let error = error {
                print(error)
            }
        })
    }
    
    /**
     This method is being used for scheduling all Team Push Notifications for a specific game.
     Any user that listens to this will receive a push notification at appropriate time.
     */
    func scheduleAllPushNotificationReminders(toGameKey gameKey: String, gameTitle: String, team: String, timestamp: Date) {
        
        // FIXME: remove this (only for debug purposes)
        // To fake it you can use this timestamp variable
        //let timestamp = Date().addingTimeInterval(24 * 3600)
        //let timestamp = Date().addingTimeInterval(60)
        
        for (i, timeInterval) in timeIntervals.enumerated() {
            
            // The key here is the team + time interval in seconds that the Reminder should be fired at
            let text = notificationText(forGameTitle: gameTitle, timeIntervalIndex: i)
            OneSignal.schedulePushNotification(title: notificationTitle(), text: text, tag: key(team: team, timeInterval: timeInterval), timestamp: timestamp.addingTimeInterval(-timeInterval), data: [
                "action" : NotificationAction.openGame.rawValue,
                "gameKey" : gameKey
                ])
            
            // FIXME: remove this (only for debug purposes)
            // To fake it you can use this timestamp variable
            //OneSignal.schedulePushNotification(title: notificationTitle(), text: text, tag: key(team: team, timeInterval: timeInterval), timestamp: timestamp)
        }
    }
    
    
    /**
     Merely formats the verbiage for the push notification title
     */
    func notificationTitle() -> String {
        return "Game Alert!"
    }
    
    /**
     Merely formats the verbiage for the push notification text
     */
    func notificationText(forGameTitle gameTitle: String, timeIntervalIndex: Int) -> String {
        return "\(gameTitle) kicks off in \(timeIntervalDescriptions[timeIntervalIndex]) \n\n Click here to see the details."
    }
    
    
    
}
