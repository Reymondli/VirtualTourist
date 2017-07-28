//
//  Pin+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by ziming li on 2017-07-27.
//  Copyright © 2017 ziming li. All rights reserved.
//

import Foundation
import CoreData


extension Pin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var pages: Int16
    @NSManaged public var photo: Photo?

}
