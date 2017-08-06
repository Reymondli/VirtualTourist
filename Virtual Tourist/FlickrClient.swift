//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by ziming li on 2017-07-26.
//  Copyright © 2017 ziming li. All rights reserved.
//

import Foundation
import CoreData

class FlickrClient: NSObject {
    // MARK: Property
    let session = URLSession.shared
    
    // MARK: Shared Instance
    static var sharedInstance = FlickrClient()
    
    // MARK: CoreDataStack
    var stack = CoreDataStack(modelName: "Model")!
    
    // MARK: Get Total Pages of Photos from Target Location (Based on Geocode)
    func getPagesFromLatLon(latitude: String, longitude: String, completionHandlerForGetPages: @escaping (_ imageFound: Bool?, _ error: String?)-> Void) {
        
        // MARK: Set the Parameters
        let parameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(lat: latitude, lon: longitude),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        initialRequest(parameters as [String : AnyObject]) { (result, error) in
            
            // Was there an error
            guard error == nil else {
                completionHandlerForGetPages(false, error)
                return
            }
            
            guard let parsedResult = result else {
                completionHandlerForGetPages(false, "Failed to Get Data From Flickr")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                completionHandlerForGetPages(false, "Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                completionHandlerForGetPages(false, "Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else {
                completionHandlerForGetPages(false, "Cannot find key '\(Constants.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            
            if totalPages == 0 {
                completionHandlerForGetPages(false, nil)
            } else {
                let randomPage = self.getRandomPage(totalPages)
                self.getImageUrl(latitude: latitude, longitude: longitude, withPageNumber: randomPage, methodParameters: parameters as [String : AnyObject], completionHandlerForGetImageUrl: completionHandlerForGetPages)
            }
            
        }
        
    }
    
    // MARK: Get Random Page (Based on getPagesFromLatLon)
    func getRandomPage(_ totalPages: Int) -> Int {
        let pageLimit = min(totalPages, 40)
        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
        return randomPage
    }
    
    // MARK: Get Image URL from Target Location (Based on Geocode) and Target Page Number (Based on Random Page)
    func getImageUrl(latitude: String, longitude: String, withPageNumber: Int, methodParameters: [String: AnyObject], completionHandlerForGetImageUrl: @escaping (_ imageFound: Bool?, _ error: String?)-> Void){
        // MARK: Set the Parameters
        var parametersWithPage = methodParameters
        parametersWithPage[Constants.FlickrParameterKeys.Page] = withPageNumber as AnyObject?
        initialRequest(parametersWithPage as [String : AnyObject]) { (result, error) in
           
            // Was there an error
            guard error == nil else {
                completionHandlerForGetImageUrl(false, error)
                return
            }
            
            guard let parsedResult = result else {
                completionHandlerForGetImageUrl(false, "Failed to Get Data From Flickr")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                completionHandlerForGetImageUrl(false, "Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject], let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                completionHandlerForGetImageUrl(false, "Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' or '\(Constants.FlickrResponseKeys.Photo)' in \(parsedResult)")
                return
            }
            
            if photosArray.count == 0 {
                completionHandlerForGetImageUrl(false, nil)
            } else {
                
                // MARK: Batch Process, Batch = workerContext
                self.stack.performBackgroundBatchOperation{ (Batch) in
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
                    let predicate = NSPredicate(format: "latitude = %@ && longitude = %@", argumentArray: [latitude, longitude])
                    fetchRequest.predicate = predicate
                    
                    // Get the Pin object in background context to form relationship between Photo and Pin objects
                    
                    if let pins = try? Batch.fetch(fetchRequest) as! [Pin] {
                        if let pin = pins.first {
                            for photoDictionary in photosArray {
                                
                                // Create photo objects for each image in the flickr result
                                // Save the image url and link the photos to the pin
                                
                                guard let imageURLString = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else {
                                    completionHandlerForGetImageUrl(nil, "Unknown error, Flickr API")
                                    return
                                }
                                let photo = Photo(imageData: nil, imageUrl: imageURLString, context: Batch)
                                photo.pin = pin
                                completionHandlerForGetImageUrl(true, nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Return Image Data from Image URL
    func getImageFromUrl(_ imageURL: String, completionHandlerForGetImage: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        
        let url = URL(string: imageURL)
        let request = URLRequest(url: url!)
        let task = session.dataTask(with: request){(data, response, error) in
            
            if error == nil {
                print("getImageFromUrl - Success")
                completionHandlerForGetImage(data, nil)
            } else {
                print("getImageFromUrl - Error")
                completionHandlerForGetImage(nil, error)
            }
        }
        
        task.resume()
    }
    
}
