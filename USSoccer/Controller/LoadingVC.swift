//
//  LoadingVC.swift
//  USSoccer
//
//  Created by Jared Sobol on 11/11/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit
import FirebaseDatabase

class LoadingVC: UIViewController {
    
    @IBOutlet weak var soccerBallImage: UIImageView!
    var sortedGames = [String: [SoccerGame]]()
    let appenderArray = [SoccerGame]()
    
    
    var pickerTeamsArray = ["U-15 MNT", "U-16 MNT", "U-17 MNT", "U-18 MNT", "U-19 MNT", "U-20 MNT", "U-23 MNT", "MNT", "ALL TEAMS", "WNT", "U-23 WNT", "U-20 WNT", "U-19 WNT", "U-18 WNT", "U-17 WNT", "U-16 WNT", "U-15 WNT"]
    
    override func viewDidAppear(_ animated: Bool) {
        startSpinning()

         //if ConnectionCheck.isConnectedToNetwork() {
        // call Api and Parse it
            ApiCaller.shared.ApiCall {
                if ApiCaller.shared.isLoadingData {
                    ApiCaller.shared.isLoadingData = false
                    DispatchQueue.main.async {
                        self.finishLoading()
                    }
                }
            }
         /*} else {
            finishLoading()
         }*/
    }
    
    func finishLoading() {
        var allGames = CoreDataService.shared.fetchGames()
        
        
        // Creating a set for all the Teams Titles that have games schedualed
        var existingKeys : Set<String> = ["MNT", "ALL TEAMS", "WNT"]
        allGames = allGames.sorted(by: {
            $0.order() < $1.order()
        })
        
        for game in allGames {
            let index = allGames.index(of: game)!
            
            if game.title == "No Upcoming Games" {
                allGames.remove(at: index)
                continue
            }
            if game.title == "Internet Access Required!" {
                allGames.remove(at: index)
                continue
            }
            
            let dateFormated = Date()
            //#FixMe check this below
            // adding more time too wait before the game is deleted
            let dayInSeconds: TimeInterval = 24.0 * 3600.0
            if let timestamp = game.timestamp, timestamp.timeIntervalSince1970 < (dateFormated.timeIntervalSince1970 - (dayInSeconds * 2.0)) {
                //this is my solution, I think it will only remove the game if the array is not empty
                // it didn't work still failing on line 162 for some reason.
                allGames.remove(at: index)
                gamesRef.child("\(game.title!)\(game.date!)").removeValue()
                CoreDataService.shared.delete(object: game)
                continue
            }
            
            existingKeys.insert(game.usTeam)
        }
        
        
        sortedGames["ALL TEAMS"] = allGames
        
        // Remove the missing ones
        var updatedPickerTeamsArray = [String]()
        for team in pickerTeamsArray {
            if existingKeys.contains(team) {
                updatedPickerTeamsArray.append(team)
            }
        }
        pickerTeamsArray = updatedPickerTeamsArray
        
        
        for game in allGames {
            let changedTitle = game.title!.replacingOccurrences(of: "VS", with: "vs")
            let teamsTitles = changedTitle.components(separatedBy: "vs")
            let trimmedTitle = stringTrimmer(stringToTrim: teamsTitles[0].uppercased())
            
            if var appenderArray = self.sortedGames[trimmedTitle!] {
                appenderArray.append(game)
                self.sortedGames[trimmedTitle!] = appenderArray
            } else {
                self.sortedGames[trimmedTitle!] = [game]
            }
        }
        sleep(1)
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "loadingToHome", sender: nil)
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let toDoItemToPass = sortedGames
        if let navc = segue.destination as? UINavigationController,
            let detailViewController = navc.viewControllers.first as? HomeVC {
            detailViewController.sortedGames = toDoItemToPass
            detailViewController.pickerTeamsArray = pickerTeamsArray
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
                
                NavigationService.shared.handleAllPendingNotificationsData()
            })
        }
        
    }
    
    func startSpinning() {
        soccerBallImage.startRotating()
    }
    
    func stopSpinning() {
        soccerBallImage.stopRotating()
    }

}

extension UIView {
    func startRotating(duration: Double = 2) {
        let kAnimationKey = "rotation"
        
        if self.layer.animation(forKey: kAnimationKey) == nil {
            let animate = CABasicAnimation(keyPath: "transform.rotation")
            animate.duration = duration
            animate.repeatCount = Float.infinity
            animate.fromValue = 0.0
            animate.toValue = Float(.pi * 2.0)
            self.layer.add(animate, forKey: kAnimationKey)
        }
    }
    func stopRotating() {
        let kAnimationKey = "rotation"
        
        if self.layer.animation(forKey: kAnimationKey) != nil {
            self.layer.removeAnimation(forKey: kAnimationKey)
        }
    }
}
