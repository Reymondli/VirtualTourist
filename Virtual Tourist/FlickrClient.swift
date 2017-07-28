//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by ziming li on 2017-07-26.
//  Copyright © 2017 ziming li. All rights reserved.
//

import Foundation

class FlickrClient: NSObject {
    // MARK: Property
    var session = URLSession.shared
    var lat: String? = ""
    var lon: String? = ""
    
    // MARK: Shared Instance
    static var sharedInstance = FlickrClient()
    
    // MARK: Return Maximum/Minimum Latitude and Longitude
    private func bboxString(lat: String, lon: String) -> String {
        // ensure bbox is bounded by minimum and maximums
        if let latitude = Double(lat), let longitude = Double(lon) {
            let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }
    
    // MARK: Get Photos from Target Location (Geocode)
    func getPhotoFromLatLon (latitude: String, longitude: String, completionHandlerForGet: @escaping (_ error: String?)-> Void) {
        
        // MARK: Set the Parameters
        
    }
    
}
