//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by ziming li on 2017-07-30.
//  Copyright © 2017 ziming li. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    
    // MARK: Initializer
    convenience init(imageData: NSData?, imageUrl: String?, context: NSManagedObjectContext) {
        // An EntityDescription is an object that has access to all
        // the information you provided in the Entity part of the model
        // you need it to create an instance of this class.
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.imageData = imageData
            self.imageUrl = imageUrl
        } else {
            fatalError("Unable to find Entity name!")
        }
    }

}
