//
//  PhotoCollectionViewController.swift
//  Virtual Tourist
//
//  Created by ziming li on 2017-08-09.
//  Copyright © 2017 ziming li. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoCollectionViewController: UIViewController {
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var labelView: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    // MARK: Properties
    var pin: Pin!
    var stack: CoreDataStack {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.stack
    }
    var canDelete: Bool! {
        didSet {
            if canDelete {
                // "New Collection" Button Becomes "Remove Selected Photos" Button
                deleteButton.setTitle("Remove Selected Photos", for: .normal)
            } else {
                deleteButton.setTitle("New Collection", for: .normal)
            }
        }
    }
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            collectionView.reloadData()
        }
    }
    
    // MARK: CoreData Fetch Properties - IndexPath Lists For Each Operation
    var insertedIndexPathLists: [IndexPath]!
    var deletedIndexPathLists: [IndexPath]!
    var updatedIndexPathLists: [IndexPath]!
    var selectedIndexPathLists = [IndexPath]()
    
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
        // Step 0: Initialize canDelete and labelView
        canDelete = false
        labelView.isHidden = true
        
        // Step 1: Display MapView
        mapViewHelper(targetPin: pin)
        
        // Step 2: Setup Flow Layout
        flowLayoutHelper()
        
        // Step 3: Setup Fetched Results Controller
        fetchRequestHelper()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Loading any existing photo where applicable
        // or Get New Photos from Flickr for Newly Created Pin
        if pin.photo!.count == 0 {
            getNewFlickrPhotos()
        }
    }
    
    // MARK: Delete Button Pressed
    @IBAction func deleteButtonPressed(_ sender: Any) {
        if canDelete {
            // Delete Selected Photos
            if let context = fetchedResultsController?.managedObjectContext, selectedIndexPathLists.count > 0 {
                for selectedIndexPath in selectedIndexPathLists {
                    let selectedPhoto = fetchedResultsController?.object(at: selectedIndexPath) as! Photo
                    context.delete(selectedPhoto)
                }
                // Clear selectedIndexPathLists and Disable canDelete
                canDelete = false
                selectedIndexPathLists = [IndexPath]()
            }
        } else {
            // Step 1: Clear Any Existing Photo Urls and/or Data, then updates the Core Data
            if let context = fetchedResultsController?.managedObjectContext {
                for photo in fetchedResultsController!.fetchedObjects as! [Photo] {
                    context.delete(photo)
                }
                self.stack.save()
            }
            // Step 2: Get New Collections
            getNewFlickrPhotos()
        }
        self.stack.save()
    }
}

// MARK: Helper Functions
extension PhotoCollectionViewController {
    // flowLayoutHelper
    func flowLayoutHelper() {
        // this method set up flow layout
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        let dimension2 = (view.frame.size.height - (2 * space)) / 6.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension2)
    }
    
    // mapViewHelper
    // Note: Might have "WARNING: Output of vertex shader 'v_gradient' not read by fragment shader"
    // Based on Xcode Version Due to Beta Version Xcode and Library Kit
    func mapViewHelper(targetPin: Pin) {
        // this method set up map view centered on target location
        // Set Annotation
        let coordinate = CLLocationCoordinate2DMake(targetPin.latitude, targetPin.longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        // Set Region
        let region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(0.01, 0.01))
        mapView.setRegion(region, animated: true)
    }
    
    // existingPhotoFinder
    func existingPhotoFinder() {
        if pin.photo!.count > 0 {
            // Do nothing as we already have some photos loaded before
        } else {
            // Find new photos, get imageUrl and save to CoreData
            getNewFlickrPhotos()
        }
    }
    
    // fetchRequestHelper
    func fetchRequestHelper() {
        // Set fetchRequest
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let sortDescriptorList = [NSSortDescriptor(key: "imageUrl", ascending: true)]
        fetchRequest.sortDescriptors = sortDescriptorList
        
        // Set Predicate
        let predicate = NSPredicate(format: "pin = %@", argumentArray: [pin!])
        fetchRequest.predicate = predicate
        
        // Set fetchResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    // executeSearch
    func executeSearch() {
        print("executeSearch")
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController!)")
            }
        }
    }
    
    // getNewFlickrPhotos
    func getNewFlickrPhotos() {
        print("looking for new photos on Flickr...")
        deleteButton.isEnabled = false
        FlickrClient.sharedInstance.getPagesFromLatLon(latitude: pin.latitude, longitude: pin.longitude){ (imageFound, error) in
            if imageFound == false {
                // No Image for this Pin (Location), Notify User
                self.labelView.isHidden = false
            }
        }
    }
}

// MARK: UICollectionViewDataSource
extension PhotoCollectionViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        let sections = self.fetchedResultsController?.sections?.count ?? 0
        return sections
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("numberOfItemsInSection")
        let sectionInfo = self.fetchedResultsController?.sections![section]
        print("Returning Section.numberOfObjects: \(sectionInfo!.numberOfObjects)")
        return sectionInfo!.numberOfObjects
    }
    
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("cellForItemAt")
        // Initialize Cell Image and Activity Indicator
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photocell", for: indexPath) as! PhotoCollectionCell
        // Setup Placeholder UIImage and Activity Indicator
        cell.imageView.image = UIImage(color: .gray)
        cell.turnOnActivityIndicator(turnOn: true)
        
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        if let imageData = photo.imageData {
            // Load Photo from Core Data if Available
            cell.imageView.image = UIImage(data: imageData as Data)
            deleteButton.isEnabled = true
            cell.turnOnActivityIndicator(turnOn: false)
        } else {
            // If no photo in Core Data yet, search photo using Flickr Methods
            if let imageUrl = photo.imageUrl {
                // Is imageUrl available already?
                // If so, simply get photos from imageUrl
                FlickrClient.sharedInstance.getImageFromUrl(imageUrl){ (data, error) in
                    if error == nil {
                        // Always Dealing with UI on Main Thread
                        DispatchQueue.main.async {
                            cell.imageView.image = UIImage(data: data!)
                            cell.turnOnActivityIndicator(turnOn: false)
                            photo.imageData = data! as NSData
                            self.stack.save()
                            self.deleteButton.isEnabled = true
                        }
                    }
                }
            }
        }
        return cell
    }
}

// MARK: UICollectionViewDelegate
extension PhotoCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("didDeselectItemAt")
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionCell
        
        // Has this cell been selected before?
        if let index = selectedIndexPathLists.index(of: indexPath) {
            // Selected before, now user wants to deselect
            print("cell deselected")
            selectedIndexPathLists.remove(at: index)
            cell.alpha = 1.0
        } else {
            // Never selected before, now user wants to select
            print("cell selected")
            selectedIndexPathLists.append(indexPath)
            cell.alpha = 0.5
        }
        
        canDelete = (selectedIndexPathLists.count > 0)
        // print("canDelete: \(canDelete)")
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension PhotoCollectionViewController: NSFetchedResultsControllerDelegate {
    
    // Create Each Index Path List when Content is about to Change
    /* Notifies the receiver that the fetched results controller is about to 
     start processing of one or more changes due to an add, remove, move, or update. */
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPathLists = [IndexPath]()
        deletedIndexPathLists = [IndexPath]()
        updatedIndexPathLists = [IndexPath]()
    }
    
    // Notifies the receiver of the addition or removal of a section.
    /* The fetched results controller reports changes to its section before changes to the fetched result objects. */
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        print("Did change section")
        let indexSet = NSIndexSet(index: sectionIndex) as IndexSet
        switch (type){
        case .insert:
            self.collectionView.insertSections(indexSet)
        case .delete:
            self.collectionView.deleteSections(indexSet)
        default:
            return
        }
    }
    
    /* Notifies the receiver that a fetched object has been changed due to an add, remove, move, or update. */
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            print("Inserting an item")
            insertedIndexPathLists.append(newIndexPath!)
            break
        case .delete:
            print("Deleting an item")
            deletedIndexPathLists.append(indexPath!)
            break
        case .update:
            print("Updating an item")
            updatedIndexPathLists.append(indexPath!)
            updatedIndexPathLists.append(newIndexPath!)
            break
        case .move:
            print("Moving an item.")
            break
        }
    }
    
    /* Notifies the receiver that the fetched results controller has completed processing of one or more changes due to an add, remove, move, or update. */
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPathLists {
                print("insertItem in controllerDidChangeContent")
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPathLists {
                print("deleteItem in controllerDidChangeContent")
                self.collectionView.deleteItems(at: [indexPath])
            }
            
        }, completion: { (success) -> Void in
            
            if (success) {
                print("success")
                self.insertedIndexPathLists = [IndexPath]()
                self.deletedIndexPathLists = [IndexPath]()
            }
            
        })
    }
}

// MARK: UIImage Modification for defining Placeholder Color in Cell's imageView
public extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
