//
//  HomeVC.swift
//  USSoccer
//
//  Created by Jared Sobol on 11/11/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class HomeVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var teamPicker: UIPickerView!
    let pickerTeamsArray = ["U-23 MNT", "MNT", "ALL TEAMS", "WNT", "U-23 WNT"]
    var rotationAngle: CGFloat!
    let customHeight: CGFloat = 100
    let customWidth: CGFloat = 80
    var soccerGames = [SoccerGame]()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        rotationAngle = -150 * (.pi/100)
        teamPicker.delegate = self
        teamPicker.dataSource = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        
        
//        teamPicker.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        let topConstraintTable = NSLayoutConstraint(item: tableView, attribute: .topMargin, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraintTable = NSLayoutConstraint(item: tableView, attribute: .bottomMargin, relatedBy: .equal, toItem: teamPicker, attribute: .top, multiplier: 1, constant: 0)
        let trailingConstraintTable = NSLayoutConstraint(item: tableView, attribute: .trailingMargin, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        let leadingConstraintTable = NSLayoutConstraint(item: tableView, attribute: .leadingMargin, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
//        let topConstraintPicker = NSLayoutConstraint(item: teamPicker, attribute: .topMargin, relatedBy: .equal, toItem: tableView, attribute: .bottom, multiplier: 1, constant: 0)
//        let bottomConstraintPicker = NSLayoutConstraint(item: teamPicker, attribute: .bottomMargin, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 5)
        NSLayoutConstraint.activate([topConstraintTable,bottomConstraintTable,trailingConstraintTable,leadingConstraintTable])
        
//        let y = teamPicker.frame.origin.y
//        tableView.frame = CGRect(x: view.frame.width, y: view.frame.height - 90 , width: view.frame.width, height: view.frame.height)
//        let navBarHeight: CGFloat =
        teamPicker.transform = CGAffineTransform(rotationAngle: rotationAngle)
        teamPicker.frame = CGRect(x: -100, y: view.frame.height - 73, width: view.frame.width + 200, height: 68)
//        tableView = UITableView(frame: CGRect(x: 0, y: barHeight, width: displayWidth, height: displayHeight - barHeight))
        print(teamPicker.frame.origin)
        print(view.frame.width)
        print(teamPicker.frame)
        teamPicker.selectRow(2, inComponent: 0, animated: true)
        gamesRef.observe(.value, with: { snapshot in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let game = SoccerGame(snapShot: child)
                self.soccerGames.append(game)
                
                let formatter = DateFormatter()
                // November 14, 2017
                // 3:30 PM ET
                
                if game.timestamp == nil {
                    let timeWithoutTimeZoneString = (game.time as NSString).substring(to: game.time.count - 2)
                
                    let dateAndTimeStringWithProperTimeZone = game.date + " " + timeWithoutTimeZoneString + self.timezoneFromTimeString(timeString: game.time)
                    // Date parsing, Time parsing
                    formatter.dateFormat = "MMMM dd, yyyy h:mm a ZZZ"
                    let date = formatter.date(from: dateAndTimeStringWithProperTimeZone)
                    print(date)
                    gamesRef.child(child.key).child("timestamp").setValue(date?.timeIntervalSince1970)
                }
            }
            self.tableView.reloadData()
        })
    }
    
    func timezoneFromTimeString(timeString: String) -> String {
        // -0500
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
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return soccerGames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GamesTVCell", for: indexPath) as? GamesTVCell else {
            fatalError("The Cell Failed to Deque")
        }
        cell.gameDateLbl.text = "NOV 14, 2017"
        cell.gameTimeLbl.text = "3:30PM ET"
        let usSoccerTitle = soccerGames[indexPath.row].title.components(separatedBy: " ")
        if usSoccerTitle[1] != "vs" {
            cell.gameTitleLbl.text = "\(usSoccerTitle[0].uppercased())"
            cell.vsLbl.text = "\(usSoccerTitle[2].uppercased())"
            cell.opponentLbl.text = "\(usSoccerTitle[3].uppercased())"
        } else {
            cell.gameDateLbl.text = "\(usSoccerTitle[0].uppercased())"
            cell.vsLbl.text = "\(usSoccerTitle[1].uppercased())"
            cell.opponentLbl.text = "\(usSoccerTitle[2].uppercased())"
            
        }
        let gameDate = soccerGames[indexPath.row].date.components(separatedBy: " ")
        let formatedMonth = gameDate[0].prefix(3)
        cell.gameDateLbl.text = "\(formatedMonth.uppercased()) \(gameDate[1]) \(gameDate[2])"
       // cell.gameTimeLbl.text = soccerGames[indexPath.row].time
        return cell
    }
}

extension HomeVC: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerTeamsArray.count
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return customHeight
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: customWidth, height: customHeight))
        let nameLabel = UILabel(frame: CGRect(x: 0, y: 0, width: customWidth, height: customHeight))
        nameLabel.text = pickerTeamsArray[row]
        nameLabel.textAlignment = .center
        nameLabel.textColor = UIColor(red:0.00, green:0.25, blue:0.53, alpha:1.0)
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        view.addSubview(nameLabel)
        view.transform = CGAffineTransform(rotationAngle: (150 * (.pi/100)))
        return view
    }
}

