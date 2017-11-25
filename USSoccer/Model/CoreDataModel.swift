//
//  CoreDataModel.swift
//  USSoccer
//
//  Created by Jared Sobol on 11/25/17.
//  Copyright © 2017 Appmaker. All rights reserved.
//

import UIKit
import CoreData

class CoreDataService {
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    var managedContext : NSManagedObjectContext?
    
    static let shared = CoreDataService()
    private init() {
        managedContext = appDelegate?.persistentContainer.viewContext
    }
    
    func fetchTeams() -> [Team] {
        var teams = [Team]()
        let fetchTeams = NSFetchRequest<Team>(entityName: "Team")
        
        do {
            teams = (try managedContext?.fetch(fetchTeams))!
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return teams
    }
    
    func saveTeam(title: String) {
        let entity = NSEntityDescription.entity(forEntityName: "Team", in: managedContext!)!
        let team = Team(entity: entity, insertInto: managedContext)
        team.setValue(title, forKey: "title")
        team.setValue(false, forKey: "notifications")
        team.setValue(false, forKey: "twoDay")
        team.setValue(false, forKey: "oneDay")
        team.setValue(false, forKey: "twoHour")
        team.setValue(false, forKey: "oneHour")
        team.setValue(false, forKey: "thirtyMinutes")
        
        saveContext()
    }
    
    func saveContext() {
        do {
            try managedContext?.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    static func updateTeam() {
        
    }
    
    
}
