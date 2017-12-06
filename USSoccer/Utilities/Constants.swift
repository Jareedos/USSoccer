//
//  Constants.swift
//  USSoccer
//
//  Created by Jared Sobol on 10/6/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import Foundation
import FirebaseDatabase


enum AuthErrorCodesFirebase: Int {
    case error_Invalid_Email = 17008,
    error_Email_Already_In_Use = 17007,
    error_Weak_Password = 17026
}

let ref = Database.database().reference()
let gamesRef = ref.child("Games")
let notificationsRef = ref.child("Notifications")

