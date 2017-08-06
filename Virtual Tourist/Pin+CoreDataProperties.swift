//
//  Pin+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by ziming li on 2017-07-30.
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
    @NSManaged public var photo: Photo?

}
