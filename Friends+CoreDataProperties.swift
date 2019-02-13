//
//  Friends+CoreDataProperties.swift
//  
//
//  Created by Andrei Homentcovschi on 1/30/19.
//
//

import Foundation
import CoreData


extension Friends {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Friends> {
        return NSFetchRequest<Friends>(entityName: "Friends")
    }

    @NSManaged public var username: String?
    @NSManaged public var foreignKey: NSSet?

}

// MARK: Generated accessors for foreignKey
extension Friends {

    @objc(addForeignKeyObject:)
    @NSManaged public func addToForeignKey(_ value: ForeignKeys)

    @objc(removeForeignKeyObject:)
    @NSManaged public func removeFromForeignKey(_ value: ForeignKeys)

    @objc(addForeignKey:)
    @NSManaged public func addToForeignKey(_ values: NSSet)

    @objc(removeForeignKey:)
    @NSManaged public func removeFromForeignKey(_ values: NSSet)

}
