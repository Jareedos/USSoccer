//
//  NotificationMenuView.swift
//  USSoccer
//
//  Created by Jared Sobol on 12/4/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit
import Firebase

class NotificationMenuView: UIView, UITableViewDataSource, UITableViewDelegate {
    var twoDayBool = false
    var oneDayBool = false
    var twoHourBool = false
    var oneHourBool = false
    var halfHourBool = false
    
    var teamsArray = ["ALL TEAMS", "MNT", "WNT", "U-23 MNT", "U-23 WNT", "U-20 MNT", "U-20 WNT", "U-19 MNT", "U-19 WNT", "U-18 MNT", "U-18 WNT", "U-17 MNT", "U-17 WNT", "U-16 MNT", "U-16 WNT","U-15 MNT", "U-15 WNT"]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teamsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TeamTVC", for: indexPath) as? TeamsTVC else {
            fatalError("The Cell Failed to Deque")
        }
        cell.teamTitle.text = teamsArray[indexPath.row]
        cell.notificationIconBtn.image = #imageLiteral(resourceName: "musical-bell-outline (1)")
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ConnectionCheck.isConnectedToNetwork() {
            
        } else {
             messageAlert(title: "No Internet Connection", message: "Internet Connection is Required to update Team Notifications", from: nil)
        }
    }
    
    @IBAction func twoDaySwitch(_ sender: UISwitch) {
        if ConnectionCheck.isConnectedToNetwork() {
            twoDayBool = !twoDayBool
            notificationsRef.updateChildValues(["TwoDayNotification": twoDayBool])
        } else {
            messageAlert(title: "No Internet Connection", message: "Internet Connection is Required to update Team Notifications", from: nil)
        }

    }
    
    @IBAction func oneDaySwitch(_ sender: UISwitch) {
        if ConnectionCheck.isConnectedToNetwork() {
            oneDayBool = !oneDayBool
            
            notificationsRef.updateChildValues(["OneDayNotification": oneDayBool])
        } else {
            messageAlert(title: "No Internet Connection", message: "Internet Connection is Required to update Team Notifications", from: nil)
        }
    }
    
    @IBAction func twoHourSwitch(_ sender: UISwitch) {
        if ConnectionCheck.isConnectedToNetwork() {
            twoHourBool = !twoHourBool
            
            notificationsRef.updateChildValues(["TwoHourNotification": twoHourBool])
        } else {
            messageAlert(title: "No Internet Connection", message: "Internet Connection is Required to update Team Notifications", from: nil)
        }
    }
    
    @IBAction func oneHourSwitch(_ sender: UISwitch) {
        if ConnectionCheck.isConnectedToNetwork() {
            oneHourBool = !oneHourBool
            
            notificationsRef.updateChildValues(["OneHourNotification": oneHourBool])
        } else {
            messageAlert(title: "No Internet Connection", message: "Internet Connection is Required to update Team Notifications", from: nil)
        }
    }
    @IBAction func halfHourSwitch(_ sender: UISwitch) {
        if ConnectionCheck.isConnectedToNetwork() {
            halfHourBool = !halfHourBool
            
            notificationsRef.updateChildValues(["HalfHourNotification": halfHourBool])
        } else {
            messageAlert(title: "No Internet Connection", message: "Internet Connection is Required to update Team Notifications", from: nil)
        }
    }
    
}
