//
//  NotificationMenuView.swift
//  USSoccer
//
//  Created by Jared Sobol on 12/4/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class NotificationMenuView: UIView, UITableViewDataSource, UITableViewDelegate {
    var currentUser = Auth.auth().currentUser
//    let isAnonymous = user!.isAnonymous  // true
//    let uid = user!.uid
//    let usersRef = ref.child(user.uid
    var twoDayBool = false
    var oneDayBool = false
    var twoHourBool = false
    var oneHourBool = false
    var halfHourBool = false
    
    var teamsArray = ["ALL TEAMS", "MNT", "WNT", "U-23 MNT", "U-23 WNT", "U-20 MNT", "U-20 WNT", "U-19 MNT", "U-19 WNT", "U-18 MNT", "U-18 WNT", "U-17 MNT", "U-17 WNT", "U-16 MNT", "U-16 WNT","U-15 MNT", "U-15 WNT"]
    var selectedTeams = [String : Bool]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teamsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TeamTVC", for: indexPath) as? TeamsTVC else {
            fatalError("The Cell Failed to Deque")
        }
        let teamTitle = teamsArray[indexPath.row]
        cell.teamTitle.text = teamTitle
        
        
        if let isSelected = selectedTeams[teamTitle] {
            cell.configure(selected: isSelected)
        } else {
            
            followingRef.child(teamsArray[indexPath.row]).observeSingleEvent(of: .value) { (snapshot) in
                let value = snapshot.value as? NSDictionary
                if value == nil {
                    cell.configure(selected: false)
                    self.selectedTeams[teamTitle] = false
                } else {
                    if let userFollowing = value![self.currentUser!.uid] {
                        if userFollowing as! Bool {
                            cell.configure(selected: true)
                            self.selectedTeams[teamTitle] = true
                        } else {
                            cell.configure(selected: false)
                            self.selectedTeams[teamTitle] = false
                        }
                    } else {
                        cell.configure(selected: false)
                        self.selectedTeams[teamTitle] = false
                    }
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ConnectionCheck.isConnectedToNetwork() {
            
            let teamTitle = teamsArray[indexPath.row]
            let followingTeamRef = followingRef.child(teamTitle).child(currentUser!.uid)
            
            var isSelected = selectedTeams[teamTitle] ?? false
            // Flip
            isSelected = !isSelected
            selectedTeams[teamTitle] = isSelected
            if isSelected {
                followingTeamRef.setValue(true)
            } else {
                followingTeamRef.removeValue()
            }
            
            tableView.reloadData()
            
        } else {
            messageAlert(title: "No Internet Connection", message: "Internet Connection is Required to update Team Notifications", from: nil)
        }
    }
    
    @IBAction func twoDaySwitch(_ sender: UISwitch) {
        if ConnectionCheck.isConnectedToNetwork() {
            twoDayBool = sender.isOn
            ref.child("users").child((currentUser?.uid)!).child("notificationSettings").updateChildValues(["TwoDayNotification": twoDayBool])
            
//            notificationsRef.updateChildValues(["TwoDayNotification": twoDayBool])
        } else {
            messageAlert(title: "No Internet Connection", message: "Internet Connection is Required to update Team Notifications", from: nil)
        }

    }
    
    @IBAction func oneDaySwitch(_ sender: UISwitch) {
        if ConnectionCheck.isConnectedToNetwork() {
            oneDayBool = sender.isOn
            ref.child("users").child((currentUser?.uid)!).child("notificationSettings").updateChildValues(["OneDayNotification": oneDayBool])
        } else {
            messageAlert(title: "No Internet Connection", message: "Internet Connection is Required to update Team Notifications", from: nil)
        }
    }
    
    @IBAction func twoHourSwitch(_ sender: UISwitch) {
        if ConnectionCheck.isConnectedToNetwork() {
            twoHourBool = sender.isOn
            ref.child("users").child((currentUser?.uid)!).child("notificationSettings").updateChildValues(["TwoHourNotification": twoHourBool])
        } else {
            messageAlert(title: "No Internet Connection", message: "Internet Connection is Required to update Team Notifications", from: nil)
        }
    }
    
    @IBAction func oneHourSwitch(_ sender: UISwitch) {
        if ConnectionCheck.isConnectedToNetwork() {
            oneHourBool = sender.isOn
            ref.child("users").child((currentUser?.uid)!).child("notificationSettings").updateChildValues(["OneHourNotification": oneHourBool])
        } else {
            messageAlert(title: "No Internet Connection", message: "Internet Connection is Required to update Team Notifications", from: nil)
        }
    }
    @IBAction func halfHourSwitch(_ sender: UISwitch) {
        if ConnectionCheck.isConnectedToNetwork() {
            halfHourBool = sender.isOn
            ref.child("users").child((currentUser?.uid)!).child("notificationSettings").updateChildValues(["HalfHourNotification": halfHourBool])
        } else {
            messageAlert(title: "No Internet Connection", message: "Internet Connection is Required to update Team Notifications", from: nil)
        }
    }
    
}
