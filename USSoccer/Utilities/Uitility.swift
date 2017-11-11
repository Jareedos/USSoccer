//
//  Uitility.swift
//  USSoccer
//
//  Created by Jared Sobol on 10/4/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import Foundation
import UIKit

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
