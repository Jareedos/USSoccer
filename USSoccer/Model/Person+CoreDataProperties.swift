//
//  Person+CoreDataProperties.swift
//  
//
//  Created by Jared Sobol on 12/6/17.
//
//

import Foundation
import CoreData


extension Person {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Person> {
        return NSFetchRequest<Person>(entityName: "Person")
    }

    @NSManaged public var userID: String?

}
