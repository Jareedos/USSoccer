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
    
    override func viewDidAppear(_ animated: Bool) {
        startSpinning()

         if ConnectionCheck.isConnectedToNetwork() {
        // call Api and Parse it
            ApiCaller.shared.ApiCall {
                
                DispatchQueue.main.async {
                    self.finishLoading()
                }
            }
         } else {
            finishLoading()
         }
        /*
        gamesRef.observe(.value, with: { snapshot in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                let game = SoccerGame(snapShot: child)
                // Sorting Games into a Dictionary to use on HomeVC
                let teamsTitles = game.title.components(separatedBy: "vs")
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
        })*/
    }
    
    func finishLoading() {
        
        let soccerGamesCoreData = CoreDataService.shared.fetchGames()
        print(soccerGamesCoreData)
        for game in soccerGamesCoreData {
            let teamsTitles = game.title!.components(separatedBy: "vs")
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
        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let toDoItemToPass = sortedGames
        if let navc = segue.destination as? UINavigationController,
            let detailViewController = navc.viewControllers.first as? HomeVC {
            
            detailViewController.sortedGames = toDoItemToPass
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
