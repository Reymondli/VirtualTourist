//
//  TravelLocationViewController.swift
//  Virtual Tourist
//
//  Created by ziming li on 2017-07-26.
//  Copyright © 2017 ziming li. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationViewController: UIViewController {
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteLabel: UILabel!
    
    // MARK: Property
    var stack = CoreDataStack(modelName: "Model")!
    
    var editPressed = false
    
    // MARK: Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        deleteLabel.isHidden = true
        
        // Retrieve and Load Annotation on Map
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        if let pins = try? stack.context.fetch(fetchRequest) as! [Pin] {
            let annotations = pins.map({$0.createAnnotation()})
            mapView.addAnnotations(annotations)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Restore Map Settings
        if let dict = UserDefaults.standard.dictionary(forKey: "mapRegion01"),
            let myRegion = MKCoordinateRegion(decode: dict as [String : AnyObject]) {
            mapView.setRegion(myRegion, animated: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Save the Last Map Settings before Disappearing
        UserDefaults.standard.set(mapView.region.encode, forKey: "mapRegion01")
    }
    
    // MARK: Edit Button Pressed
    @IBAction func editButton(_ sender: Any) {
        deleteLabel.isHidden = editPressed
        editPressed = !editPressed
        print("Pressed: \(editPressed)")
        // editPressed Boolean is Used for mapView Selection method at bottom
    }
    
    @IBAction func addPin(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.began {
            
            // Get Target Location
            let location = sender.location(in: mapView)
            // Get CLLocationCoordinate2D to set coordinate
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            // Add Newly Created Pin to Core Data
            stack.performBackgroundBatchOperation{ (Batch) in
                _ = Pin(latitude: coordinate.latitude, longitude: coordinate.longitude, context: Batch)
            }
            // Add Annotation to Map
            mapView.addAnnotation(annotation)
            print("Pin Created!")
        }
    }
}

extension TravelLocationViewController: MKMapViewDelegate {
    // MARK: Returns the view associated with the specified annotation object.
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        print("pinView Returned!")
        return pinView
    }
    
    // MARK: Tells the delegate that one of its annotation views was selected.
    // You can use this method to track changes in the selection state of annotation views.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("Pin Selected!")
        guard let annotation = view.annotation else {
            print("Invalid PinView")
            return
        }
        
        // Clear Selection
        mapView.deselectAnnotation(annotation, animated: true)
        
        // Get Geocode Info of Selected Pin
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        let coordinate = annotation.coordinate
        let fpredicate = NSPredicate(format: "latitude > %lf AND latitude < %lf AND longitude > %lf AND longitude < %lf", coordinate.latitude - 0.01, coordinate.latitude + 0.01, coordinate.longitude - 0.01, coordinate.longitude + 0.01)
        fetchRequest.predicate = fpredicate
        
        if let pins = try? stack.context.fetch(fetchRequest) as! [NSManagedObject] {
            if let pin = pins.first {
                if editPressed == true {
                    print("Tap on Pin to Delete")
                    // editButton Pressed - Tap on Pin to Delete
                    // Remove Pin from Core Data
                    stack.context.delete(pin)
                    stack.save()
                    // Remove Pin from MapView
                    mapView.removeAnnotation(annotation)
                    print("Pin Deleted")
                } else {
                    print("Tap on Pin for Photos")
                    // Pin Selected - Tap on Pin to Open Photo Album Controller
                    let albumController = storyboard?.instantiateViewController(withIdentifier: "photoAlbumController") as! PhotoAlbumController
                    // Pass Target Pin to Photo Album Controller
                    albumController.targetPin = pin as? Pin
                    navigationController?.pushViewController(albumController, animated: true)
                }
            }
        }
    }
}

// Modify the Structure that defines which portion of the map to display.
extension MKCoordinateRegion {
    
    var encode:[String: AnyObject] {
        let centerDictionary = ["latitude": self.center.latitude,
                                "longitude": self.center.longitude]
        let spanDictionary = ["latitudeDelta": self.span.latitudeDelta,
                              "longitudeDelta": self.span.longitudeDelta]
        return ["center": centerDictionary as AnyObject,
                "span": spanDictionary as AnyObject]
    }
    
    init?(decode: [String: AnyObject]) {
        
        guard let center = decode["center"] as? [String: AnyObject],
            let latitude = center["latitude"] as? Double,
            let longitude = center["longitude"] as? Double,
            let span = decode["span"] as? [String: AnyObject],
            let latitudeDelta = span["latitudeDelta"] as? Double,
            let longitudeDelta = span["longitudeDelta"] as? Double
            else { return nil }
        
        self.center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
    }
}

