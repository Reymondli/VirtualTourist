//
//  PhotoAlbumController.swift
//  Virtual Tourist
//
//  Created by ziming li on 2017-08-02.
//  Copyright © 2017 ziming li. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumController: UIViewController {
    
    // MARK: Set UI
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollection: UICollectionView!
    @IBOutlet weak var newCollection: UIButton!
    @IBOutlet weak var noImageLabel: UILabel!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    // MARK: Properties
    var targetPin: Pin!
    // var stack = CoreDataStack(modelName: "Model")!
    
    var stack: CoreDataStack {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.stack
    }
    
    // MARK: Index Path List For Each Operation
    var selectIndex = [IndexPath]()
    var insertedIndexPath: [IndexPath]!
    var deletedIndexPath: [IndexPath]!
    var updatedIndexPath: [IndexPath]!
    
    // deleteMode is a Boolean indicates whether user is in delete mode or not
    // It is used to assign related method and UIButton's title
    var deleteMode: Bool! {
        didSet {
            if deleteMode {
                // "New Collection" Button Becomes "Remove Selected Photos" Button
                newCollection.setTitle("Remove Selected Photos", for: .normal)
            } else {
                newCollection.setTitle("New Collection", for: .normal)
            }
        }
    }
    
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            photoCollection.reloadData()
        }
    }
    
    // MARK: Initializers
    // Do not worry about this initializer. It has to be implemented
    // because of the way Swift interfaces with an Objective C
    // protocol called NSArchiving. It's not relevant.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    // MARK: Life Cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Display MapView Based on Pin Location
        displayPinOnMap(selectedPin: targetPin)
        
        // Load Photos from CoreData to Each Cell
        setFetchRequest()
        
        // Hide "No Image" Label By Default
        noImageLabel.isHidden = true
        deleteMode = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCellSize()
        // check if coredata has photos
        if targetPin.photo!.count > 0 {
            // no need to fetch fresh new photos
            print("photos from core data \(targetPin.photo!.count)")
        }
        else {
            // else fetch it from flickr
            loadPhotos()
        }
    }
    
    func setCellSize() {
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        let dimension2 = (view.frame.size.height - (2 * space)) / 6.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension2)
    }
    
    // MARK: Display Selected Pin Location on Map View, almost same as the preview method on OnTheMap
    func displayPinOnMap(selectedPin: Pin) {
        // Set Annotation
        let coordinate = CLLocationCoordinate2DMake(selectedPin.latitude, selectedPin.longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        // Set Region
        let region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(0.01, 0.01))
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: Load Photos From Flickr Based on Geo-code
    func loadPhotos() {
        print("Searching Photos From Flickr")
        newCollection.isEnabled = false
        FlickrClient.sharedInstance.getPagesFromLatLon(latitude: targetPin.latitude, longitude: targetPin.longitude) { (imageFound, error) in
            guard error == nil else {
                print("Error Found During Flickr Image Search Processing: \(error!)")
                return
            }
            if imageFound! {
                self.noImageLabel.isHidden = true
            }
            
        }
        print("Finish Loading")
    }
    
    // MARK: Activity Indicator Configuration
    func configActivityIndicator(activityIndicator: UIActivityIndicatorView,turnOn: Bool) {
        if turnOn {
            // Show Indicator and Start Animation
            activityIndicator.isHidden = !turnOn
            activityIndicator.startAnimating()
        } else {
            // Stop Animation and Hide Indicator
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = !turnOn
        }
    }
    
    // MARK: New Collection/Remove Photo Button Pressed
    
    @IBAction func bottomButtonPressed(_ sender: Any) {
        if deleteMode {
            // Delete Photos and Update Core Data
            if let context = fetchedResultsController?.managedObjectContext, selectIndex.count > 0 {
                
                for index in selectIndex {
                    let selectPhoto = fetchedResultsController!.object(at: index) as! Photo
                    context.delete(selectPhoto)
                }
                // Once Deletion Complete, Change the title back to ""
                newCollection.setTitle("New Collection", for: .normal)
            }
            
        } else {
            // Disable Button While Searching for Images
            newCollection.isEnabled = false
            
            // Set FRC - Fetch Request Controller
            if let context = fetchedResultsController?.managedObjectContext {
                // Clear Existing Photos and Save
                for photo in fetchedResultsController!.fetchedObjects as! [Photo] {
                    context.delete(photo)
                }
                self.stack.save()
            }
            
            // Search For New Photos From Flickr
            loadPhotos()
        }
        
        // Save Changes into Core Data
        self.stack.save()
    }
    
    
    func setFetchRequest() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        
        // MARK: An NSSortDescriptor object describes a basis for ordering objects
        let descriptor = [NSSortDescriptor(key: "imageUrl", ascending: true)]
        fetchRequest.sortDescriptors = descriptor
        
        let ffpredicate = NSPredicate(format: "targetPin = %@", argumentArray: [targetPin!])
        fetchRequest.predicate = ffpredicate
        
        // MARK:  use a fetched results controller to efficiently manage the results returned from a Core Data fetch request to provide data for a UITableView object.
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    
}
extension PhotoAlbumController {
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController!)")
            }
        }
    }

}
// MARK: PhotoAlbumController: UICollectionViewDelegate
extension PhotoAlbumController: UICollectionViewDelegate {
    
    // MARK: collectionView - didSelectItemAt
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Accessing collectionView - didSelectItemAt")
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionCellController
        
        // Check whether the target cell/Photo has been selected for the first time or second time
        // index exist if the cell has been selected before
        if let index = selectIndex.index(of: indexPath) {
            // Photo Deselected - Index Removed From Selection Index List
            // Set Transparency to None
            cell.alpha = 1.0
            selectIndex.remove(at: index)
        } else {
            // It is the first time the this cell is selected, add the path into Selection Index List
            // Photo Selected
            // Set Transparency for Selected Photo Cell
            cell.alpha = 0.5
            selectIndex.append(indexPath)
        }
        
        // If selectIndex count is more than 0, Enable Delete Mode
        deleteMode = selectIndex.count > 0 ? true : false
        print("Finishing collectionView - didSelectItemAt")
    }
}

// MARK: PhotoAlbumController: UICollectionViewDataSource
// collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) and
// collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
// Must be declared for controller to conform to UICollectionViewDataSource
extension PhotoAlbumController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let sections = self.fetchedResultsController?.sections?.count ?? 0
        print("Returning Sections: \(sections)")
        return sections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //
        let sectionInfo = self.fetchedResultsController?.sections![section]
        print("Returning Section.numberOfObjects: \(sectionInfo!.numberOfObjects)")
        return sectionInfo!.numberOfObjects
    }
    
    // MARK: collectionView - cellForItemAt
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("Accessing collectionView - cellForItemAt Method")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photocell", for: indexPath) as! PhotoCollectionCellController
        // Set FRC
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        cell.photoImage.image = nil
        print("Activity Indicator Starting...")
        configActivityIndicator(activityIndicator: cell.activityIndicator, turnOn: true)
        print(photo.imageUrl!)
        
        // Load Image on Each Cell
        if let cellImageData = photo.imageData {
            // Get Saved Image Directly
            print("Im in collectionView function!!!!!")
            cell.photoImage.image = UIImage(data: cellImageData as Data)
            newCollection.isEnabled = true
        } else {
            print("Im in collectionView function!!!!!")
            // If No Saved Image Loaded Before, Get Image From URL and Save it
            if let cellImageUrl = photo.imageUrl {
                FlickrClient.sharedInstance.getImageFromUrl(cellImageUrl) { (imageData, error) in
                    guard error == nil else {
                        print("Error Appears when Getting Image Using URL")
                        return
                    }
                    // Dealing with UI on Main Queue
                    DispatchQueue.main.async {
                        cell.photoImage.image = UIImage(data: imageData!)
                        self.configActivityIndicator(activityIndicator: cell.activityIndicator, turnOn: false)
                        print("Activity Indicator Stoping...")
                        
                        // Save All Loaded Photos into Core Data
                        photo.imageData = imageData! as NSData
                        self.stack.save()
                        // Re-enable "New Collection" Button
                        self.newCollection.isEnabled = true
                    }
                }
            }
        }
        print("Finishing collectionView - cellForItemAt Method")
        return cell
    }
}


// MARK: PhotoAlbumController: NSFetchedResultsControllerDelegate
extension PhotoAlbumController: NSFetchedResultsControllerDelegate {
    
    // Create Each Index Path List when Content is about to Change
    /* Notifies the receiver that the fetched results controller is about to start processing of one or more changes due to an add, remove, move, or update. */
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPath = [IndexPath]()
        deletedIndexPath = [IndexPath]()
        updatedIndexPath = [IndexPath]()
    }
    
    // Notifies the receiver of the addition or removal of a section.
    /* The fetched results controller reports changes to its section before changes to the fetched result objects. */
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        print("Section Updated")
        let set = IndexSet(integer: sectionIndex)
        
        switch (type) {
        case .insert:
            self.photoCollection.insertSections(set)
            
        case .delete:
            self.photoCollection.deleteSections(set)
            
        default:
            return
        }
    }
    
    /* Notifies the receiver that a fetched object has been changed due to an add, remove, move, or update. */
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch (type) {
            
        case .insert:
            print("Inserting an item")
            insertedIndexPath.append(newIndexPath!)
            break
        case .delete:
            print("Deleting an item")
            deletedIndexPath.append(indexPath!)
            break
        case .update:
            print("Updating an item.")
            updatedIndexPath.append(indexPath!)
            updatedIndexPath.append(newIndexPath!)
            break
        case .move:
            print("Moving an item.")
            break
        }
    }
    
    /* Notifies the receiver that the fetched results controller has completed processing of one or more changes due to an add, remove, move, or update. */
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.photoCollection.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPath {
                print("insertItem in controllerDidChangeContent")
                self.photoCollection.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPath {
                print("deleteItem in controllerDidChangeContent")
                self.photoCollection.deleteItems(at: [indexPath])
            }
            
        }, completion: { (success) -> Void in
            
            if (success) {
                print("success")
                self.insertedIndexPath = [IndexPath]()
                self.deletedIndexPath = [IndexPath]()
            }
        })
    }
}
