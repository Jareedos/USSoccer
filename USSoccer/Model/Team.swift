
//
//  File.swift
//  USSoccer
//
//  Created by Jared Sobol on 11/25/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import Foundation

extension Team {
    
    func firebaseKey() -> String? {
        return stringTrimmer(stringToTrim: title)
    }
    
}
