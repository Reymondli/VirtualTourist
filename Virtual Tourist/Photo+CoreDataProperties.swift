//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by ziming li on 2017-07-27.
//  Copyright © 2017 ziming li. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var image: NSData?
    @NSManaged public var url: String?
    @NSManaged public var pin: Pin?

}
