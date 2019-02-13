//
//  AccountRetrieval.swift
//  SecretSocial
//
//  Created by Andrei Homentcovschi on 1/28/19.
//  Copyright © 2019 Andrei Homentcovschi. All rights reserved.
//

import Foundation
import UIKit
import CoreData

func getUserUsername() -> String
{
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = appDelegate.persistentContainer.viewContext
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserInfo")
    request.returnsObjectsAsFaults = false
    do{
        let result = try context.fetch(request)
        if result.count > 0{
            for data in result as! [NSManagedObject]{
                return data.value(forKey: "username") as! String
            }
        }
    }
    catch{print("Failed")}
    return "";
}

func getFriendsRequestedByUser() -> [String]
{
    var requests: [String] = []
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = appDelegate.persistentContainer.viewContext
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "FriendsRequestedByUser")
    request.returnsObjectsAsFaults = false
    do{
        let result = try context.fetch(request)
        if result.count > 0{
            for data in result as! [NSManagedObject]{
                requests.append(data.value(forKey: "username") as! String)
            }
        }
    }
    catch{print("Failed")}
    return requests;
}

func getAESKey(channelId:Int16) -> String
{
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = appDelegate.persistentContainer.viewContext
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserKeys")
    request.returnsObjectsAsFaults = false
    do
    {
        let result = try context.fetch(request)
        if result.count > 0
        {
            for data in result as! [NSManagedObject]
            {
                let id = data.value(forKey: "channelId") as! Int
                // if the general group (friends)
                if(id == channelId)
                {
                    let key = data.value(forKey: "aesKey") as! String
                    return key;
                }
            }
        }
    }
    catch{print("Failed")}
    return ""
}

func getFriendsKey(username:String, channelId:Int16) -> String
{
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = appDelegate.persistentContainer.viewContext
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Friends")
    request.returnsObjectsAsFaults = false
    do
    {
        let result = try context.fetch(request)
        if result.count > 0
        {
            for friend in result as! [NSManagedObject]
            {
                let foreign_user = friend.value(forKey: "username") as! String
                // if username is in the friends list
                if(foreign_user == username){
                    let foreign_key_set = friend.value(forKeyPath: "foreignKey")
                    for foreign_key in foreign_key_set as! Set<ForeignKeys>{
                        let channel = foreign_key.value(forKey: "channelId") as! Int16
                        if channel == channelId{
                            // get the aes key from the foreign_key
                            return foreign_key.value(forKey: "key") as! String
                        }
                    }
                }
            }
        }
    }
    catch{print("Failed")}
    return ""
}

func getUserPrivateKey() -> String
{
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = appDelegate.persistentContainer.viewContext
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserInfo")
    request.returnsObjectsAsFaults = false
    do{
        let result = try context.fetch(request)
        if result.count > 0{
            for data in result as! [NSManagedObject]{
                return data.value(forKey: "privateKey") as! String
            }
        }
    }
    catch{print("Failed")}
    return "";
}

func getUserPublicKey() -> String
{
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = appDelegate.persistentContainer.viewContext
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "UserInfo")
    request.returnsObjectsAsFaults = false
    do{
        let result = try context.fetch(request)
        if result.count > 0{
            for data in result as! [NSManagedObject]{
                return data.value(forKey: "publicKey") as! String
            }
        }
    }
    catch{print("Failed")}
    return "";
}

func addToRequestsSent(user:String)
{
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = appDelegate.persistentContainer.viewContext
    
    let UserInfoEntity = NSEntityDescription.entity(forEntityName: "FriendsRequestedByUser", in: context)
    let newUserInfo = NSManagedObject(entity: UserInfoEntity!, insertInto: context)
    newUserInfo.setValue(user, forKey: "username")
    
    do {
        try context.save()
    } catch {
        print("Failed saving")
    }
}

func createFriend(username:String)
{
    // first check if friend already exists
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = appDelegate.persistentContainer.viewContext
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Friends")
    request.returnsObjectsAsFaults = false
    
    var friendExists = false
    do
    {
        let result = try context.fetch(request)
        if result.count > 0
        {
            for data in result as! [NSManagedObject]
            {
                let foreign_user = data.value(forKey: "username") as! String
                // check if friend exists
                if(foreign_user == username)
                {
                    friendExists = true
                }
            }
        }
    }
    catch{print("Failed")}
    
    // create friend if friend doesn't exist
    if friendExists == false {
        let FriendEntity = NSEntityDescription.entity(forEntityName: "Friends", in: context)
        let newFriend = NSManagedObject(entity: FriendEntity!, insertInto: context)
        newFriend.setValue(username, forKey: "username")
        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
    }
}

// friend must already exist
// returns whether the key was created or not
func createForeignKey(username:String, key:String, channelId:Int16) -> Bool
{
    // check if channelId already exists for username: yes -> replace key, no -> create channelId and key obj
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = appDelegate.persistentContainer.viewContext
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Friends")
    request.returnsObjectsAsFaults = false
    do
    {
        let result = try context.fetch(request)
        if result.count > 0
        {
            for friend in result as! [NSManagedObject]
            {
                let foreign_user = friend.value(forKey: "username") as! String
                // if username is in the friends list
                if(foreign_user == username){
                    let foreign_key_set = friend.value(forKeyPath: "foreignKey") // what is the type of this?
                    for foreign_key in foreign_key_set as! Set<ForeignKeys>{
                        let channel = foreign_key.value(forKey: "channelId") as! Int16
                        if channel == channelId{
                            // if channelId already exists, then replace the key value and return
                            foreign_key.setValue(key, forKey: "key")
                            do {
                                try context.save()
                            } catch {
                                print("Failed saving")
                            }
                            return true
                        }
                    }
                    // this part not reached if key with channelId already exists
                    // create new foreign key
                    let ForeignKeyEntity = NSEntityDescription.entity(forEntityName: "ForeignKeys", in: context)
                    let newForeignKey = NSManagedObject(entity: ForeignKeyEntity!, insertInto: context)
                    newForeignKey.setValue(Int16(channelId), forKey: "channelId")
                    newForeignKey.setValue(key, forKey: "key")
                    
                    // connect new foreign key with friend
                    let foreign_keys = friend.mutableSetValue(forKey: "foreignKey")
                    foreign_keys.add(newForeignKey)
                    
                    do {
                        try context.save()
                    } catch {
                        print("Failed saving")
                    }
                    
                    //  let foreign_keys = friend.mutableSetValue(forKey: #keyPath(Friends.foreignKey))
                    //  foreign_keys.add(newForeignKey)
                    
                    return true
                }
            }
        }
    }
    catch{print("Failed")}
    return false
}

func userInFriends(username:String) -> Bool
{
    var found = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = appDelegate.persistentContainer.viewContext
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Friends")
    request.returnsObjectsAsFaults = false
    do
    {
        let result = try context.fetch(request)
        if result.count > 0
        {
            for friend in result as! [NSManagedObject]
            {
                let foreign_user = friend.value(forKey: "username") as! String
                // if username is in the friends list
                if(foreign_user == username){
                   found = true
                }
            }
        }
    }
    catch{print("Failed")}
    return found
}

func userInFriendsRequestedByUser(username:String) -> Bool
{
    var found = false
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = appDelegate.persistentContainer.viewContext
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "FriendsRequestedByUser")
    request.returnsObjectsAsFaults = false
    do
    {
        let result = try context.fetch(request)
        if result.count > 0
        {
            for friend in result as! [NSManagedObject]
            {
                let foreign_user = friend.value(forKey: "username") as! String
                // if username is in the friends list
                if(foreign_user == username){
                    found = true
                }
            }
        }
    }
    catch{print("Failed")}
    return found
}

func removeFromFriendsRequested(username: String)
{
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = appDelegate.persistentContainer.viewContext
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "FriendsRequestedByUser")
    request.returnsObjectsAsFaults = false
    do
    {
        let result = try context.fetch(request)
        if result.count > 0
        {
            for usr in result as! [NSManagedObject]
            {
                let foreign_user = usr.value(forKey: "username") as! String
                // if username is in the friends list
                if(foreign_user == username){
                    context.delete(usr)
                }
            }
        }
    }
    catch{print("Failed")}
}
