//
//  ForeignKeys+CoreDataProperties.swift
//  
//
//  Created by Andrei Homentcovschi on 1/30/19.
//
//

import Foundation
import CoreData


extension ForeignKeys {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ForeignKeys> {
        return NSFetchRequest<ForeignKeys>(entityName: "ForeignKeys")
    }

    @NSManaged public var channelId: Int16
    @NSManaged public var key: String?
    @NSManaged public var friend: Friends?

}
