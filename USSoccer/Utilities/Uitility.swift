//
//  Uitility.swift
//  USSoccer
//
//  Created by Jared Sobol on 10/4/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import Foundation
import UIKit


/*
 1) Some data in Firebase
 2) Pull it and create your local database (map the properties and relationships)
 */

// func takes optional strings and removes whitespaces and newlinnes from strings
func stringTrimmer(stringToTrim string: String?) -> String? {
    let trimmedString = string?.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedString
}

// func creates alerts with no action other than ok
func loginAuthAlertMaker(alertTitle: String, alertMessage: String) -> UIAlertController {
    let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
    alert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: nil))
    return alert
}

// func takes strings and unwrapps them
func trimmedAndUnwrappedUserPass(email: String?, password: String?) -> (String,String) {
    //look in Utility file for stringTrimmer Func
    let trimmedEmail = stringTrimmer(stringToTrim: email)
    let trimmedPassword = stringTrimmer(stringToTrim: password)
    guard let unwrappedTrimmedEmail = trimmedEmail else {return ("","")}
    guard let unwrappedTrimmedPassword = trimmedPassword else {return ("","")}
    return (unwrappedTrimmedEmail, unwrappedTrimmedPassword)
}

// send user a message
func messageAlert(title: String, message: String?, from: UIViewController?) {
    
    // Create the Alert Controller
    let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
    // add the button actions - Left to right
    //    OK Button
    alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
    
    // Present the Alert
    
    (from ?? UIApplication.topViewController()!).present(alertController, animated: true, completion: nil)
}

extension UIApplication {
    
    static func topViewController(base: UIViewController? = UIApplication.shared.delegate?.window??.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        
        return base
    }
}
