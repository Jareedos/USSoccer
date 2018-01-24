//
//  Person+CoreDataProperties.swift
//  
//
//  Created by Jared Sobol on 1/18/18.
//
//

import Foundation
import CoreData


extension Person {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Person> {
        return NSFetchRequest<Person>(entityName: "Person")
    }

    @NSManaged public var userID: String?
    @NSManaged public var firstTimeInApp: Bool
    @NSManaged public var firstTimeClickingBell: Bool
    @NSManaged public var firstTimeClickingSetting: Bool
    @NSManaged public var firstTimeClickingInfo: Bool
    @NSManaged public var firstTimeSeeingSlideDown: Bool
    @NSManaged public var firstTimeTogglingNotificationSettings: Bool
    @NSManaged public var firstTimeClickingteam: Bool

}
