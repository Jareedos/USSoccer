//
//  NotificationMenuView.swift
//  USSoccer
//
//  Created by Jared Sobol on 12/4/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit

class NotificationMenuView: UIView, UITableViewDataSource, UITableViewDelegate {
    
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
        
    }
    

}
