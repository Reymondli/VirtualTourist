//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by ziming li on 2017-07-26.
//  Copyright © 2017 ziming li. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    // MARK: Return Maximum/Minimum Latitude and Longitude
    func bboxString(latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    // MARK: Initialize Request
    func initialRequest(_ methodParameters: [String: AnyObject], completionHandlerForRequest: @escaping (_ result: [String:AnyObject]?, _ error: String?) -> Void) {
        
        // MARK: Create session and request
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        let task = session.dataTask(with: request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request")
                // Connection Error - Error
                completionHandlerForRequest(nil, "Connection Failure")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                completionHandlerForRequest(nil, "Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                completionHandlerForRequest(nil, "No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                completionHandlerForRequest(nil, "Could not parse the data as JSON: '\(data)'")
                return
            }
            
            completionHandlerForRequest(parsedResult, nil)
        }
        
        task.resume()
    }
    
    // MARK: Helper for Creating a URL from Parameters
    private func flickrURLFromParameters(_ parameters: [String: AnyObject]) -> URL {
 
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
}
