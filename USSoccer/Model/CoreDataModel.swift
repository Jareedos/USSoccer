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
    
    func fetchGames() -> [SoccerGame] {
        var games = [SoccerGame]()
        let fetchGames = NSFetchRequest<SoccerGame>(entityName: "Game")
        do {
            games = (try managedContext?.fetch(fetchGames))!
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return games
    }
    func fetchPerson() -> Person {
        var currentPerson = [Person]()
        let fetchPerson = NSFetchRequest<Person>(entityName: "Person")
        do {
            currentPerson = (try managedContext?.fetch(fetchPerson))!
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return currentPerson[0]
    }
    
    func saveTeam(title: String) {
        let entity = NSEntityDescription.entity(forEntityName: "Team", in: managedContext!)!
        let team = Team(entity: entity, insertInto: managedContext)
        team.setValue(title, forKey: "title")
        team.setValue(false, forKey: "notifications")
        team.setValue(false, forKey: "twoDay")
        team.setValue(false, forKey: "oneDay")
        team.setValue(true, forKey: "twoHour")
        team.setValue(false, forKey: "oneHour")
        team.setValue(false, forKey: "thirtyMinutes")
        
        saveContext()
    }
    
    func saveGame(game: SoccerGame, timeStamp: Double) {
//        let entity = NSEntityDescription.entity(forEntityName: "Game", in: managedContext!)!
//        //let game = SoccerGame(title: title, date: date, time: time, venue: venue, stations: stations)
//        let game = SoccerGame(entity: entity, insertInto: managedContext)
//        game.setValue(title, forKey: "title")
//        game.setValue(venue, forKey: "venue")
//        game.setValue(time, forKey: "string")
//        game.setValue(false, forKey: "notification")
//        game.setValue(date, forKey: "date")
//        game.setValue(timeStamp, forKey: "timeStamp")
//        
        saveContext()
    }
    
    func savePerson(userID: String){
        let entity = NSEntityDescription.entity(forEntityName: "Person", in: managedContext!)!
        let person = Person(entity: entity, insertInto: managedContext)
        person.setValue(userID, forKey: "userID")
        saveContext()
    }
    
    func saveContext() {
        do {
            try managedContext?.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    static func updateGame() {
        
    }
    
    
}
