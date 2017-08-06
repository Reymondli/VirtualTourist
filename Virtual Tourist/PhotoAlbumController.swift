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
    var stack = CoreDataStack(modelName: "Model")!
    
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
        // Hide "No Image" Label By Default
        noImageLabel.isHidden = true
        deleteMode = false
        
        // Display MapView Based on Pin Location
        displayPinOnMap(selectedPin: targetPin)
        
        // Load Photos to Each Cell
        // loadPhotos()
        
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
    
    // MARK: Load Photos From Flickr to Each Cell
    func loadPhotos() {
        print("Searching Photos From Flickr")
        newCollection.isEnabled = false
        FlickrClient.sharedInstance.getPagesFromLatLon(latitude: String(targetPin.latitude), longitude: String(targetPin.longitude)) { (imageFound, error) in
            guard error == nil else {
                print("Error Found During Flickr Image Search Processing: \(error!)")
                return
            }
            self.noImageLabel.isHidden = imageFound!
        }
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
            
        } else {
            // Disable Button While Searching for Images
            newCollection.isEnabled = false
            
            // Set FRC - Fetch Request Controller
            if let context = fetchedResultsController?.managedObjectContext {
                // Clear Existing Photos and Save
                for photo in fetchedResultsController!.fetchedObjects as! [Photo] {
                    context.delete(photo)
                }
                stack.save()
            }
            
            // Search For New Photos From Flickr
            loadPhotos()
        }
        
        // Save Changes into Core Data
        stack.save()
    }
    
    
}

// MARK: PhotoAlbumController: UICollectionViewDataSource
// collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) and
// collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
// Must be declared for controller to conform to UICollectionViewDataSource
extension PhotoAlbumController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let sectionCount = self.fetchedResultsController?.sections?.count ?? 0
        return sectionCount
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //
        let section = self.fetchedResultsController?.sections![section]
        print(section!.numberOfObjects)
        return section!.numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCollectionCellController
        
        // Set FRC
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        cell.photoImage.image = nil
        configActivityIndicator(activityIndicator: cell.activityIndicator, turnOn: true)
        print(photo.imageUrl!)
        
        // Load Image on Each Cell
        if let cellImageData = photo.imageData {
            // Get Saved Image Directly
            cell.photoImage.image = UIImage(data: cellImageData as Data)
            newCollection.isEnabled = true
        } else {
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
                        
                        // Save All Loaded Photos into Core Data
                        photo.imageData = imageData! as NSData
                        self.stack.save()
                        // Re-enable "New Collection" Button
                        self.newCollection.isEnabled = true
                    }
                }
            }
        }
        
        return cell
    }
}

// MARK: PhotoAlbumController: UICollectionViewDelegate
extension PhotoAlbumController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
        deleteMode = (selectIndex.count > 0)
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
