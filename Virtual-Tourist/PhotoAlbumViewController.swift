//*********************************************************
// PhotoAlbumViewController.swift
// Virtual Tourist
//
// Created by Matthew Mueller on 5/5/17.
// Copyright © 2017 Matthew Mueller. All rights reserved.
//*********************************************************

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, Persistable, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
	//******************************************************
	// MARK: - IB Outlets
	//******************************************************
	
	@IBOutlet weak private var mapView: MKMapView!
	@IBOutlet weak private var albumCollectionView: UICollectionView!
	@IBOutlet weak private var performAlbumEditButton: UIButton!
	@IBOutlet weak private var newAlbumActivityIndicator: UIActivityIndicatorView!
	@IBOutlet weak private var noPhotosLabel: UILabel!
	@IBOutlet weak private var flowLayout: UICollectionViewFlowLayout!
	
	
	//******************************************************
	// MARK: - Public Properties
	//******************************************************
	
	weak var modelController: ModelController!
	var selectedPin: Pin!
	var photoResultsController: NSFetchedResultsController<Photo>! {
		didSet {
			photoResultsController.delegate = self
			
			do {
				try photoResultsController.performFetch()
			} catch {
				print(error)
			}
		}
	}


	//******************************************************
	// MARK: - Private Properties
	//******************************************************
	
	private var insertedIndexPaths = [IndexPath]()
	private var deletedIndexPaths = [IndexPath]()
	private var updatedIndexPaths = [IndexPath]()
	private var loadingPhotos = [Photo:PhotoDisplayState]()
	
	
	//******************************************************
	// MARK: - Life Cycle
	//******************************************************
	
	override func viewDidLoad() {
		super.viewDidLoad()

		albumCollectionView.allowsMultipleSelection = true
		photoResultsController = modelController.getPhotosFor(pin: selectedPin)
		
		if !selectedPin.hasPhotos {
			newAlbum()
		}
		
		mapView.addAnnotation(selectedPin)
		let region = MKCoordinateRegion(center: selectedPin.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006))
		mapView.region = region
	}
	
	override func viewWillAppear(_ animated: Bool) {
		configureUI()
		reflowCollectionCells()
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		coordinator.animate(alongsideTransition: { _ in
			self.reflowCollectionCells()
		}, completion: nil)
	}
	
	func reflowCollectionCells() {
		let space:CGFloat = 3.0
		let photosPerRow: CGFloat =  traitCollection.horizontalSizeClass == .compact ? 3 : 5
		
		let dimension = (view.frame.size.width - ((photosPerRow - 1) * space)) / photosPerRow
		flowLayout.minimumInteritemSpacing = space
		flowLayout.minimumLineSpacing = space
		flowLayout.itemSize = CGSize(width: dimension, height: dimension)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		modelController.cancelNetworkRequests()
	}

	
	//******************************************************
	// MARK: - IB Actions
	//******************************************************

	@IBAction func performAlbumEdit(_ sender: Any) {
		guard let selectedIndexes = albumCollectionView.indexPathsForSelectedItems else {
			return
		}
		
		performAlbumEditButton.isEnabled = false
		if selectedIndexes.count > 0 {
			let selectedPhotos = selectedIndexes.map { photoResultsController.object(at: $0) }
			removePhotos(selectedPhotos)
		} else {
			newAlbum()
		}
	}
	
	
	//******************************************************
	// MARK: - Helpers
	//******************************************************
	
	func configureUI() {
		noPhotosLabel.isHidden = selectedPin.hasPhotos
		let photosSelected = (albumCollectionView.indexPathsForSelectedItems?.count ?? 0) > 0
		let title = photosSelected ? "Remove Selected Pictures" : "New Collection"
		performAlbumEditButton.setTitle(title, for: .normal)
	}
	
	func newAlbum() {
		performAlbumEditButton.isEnabled = false
		newAlbumActivityIndicator.startAnimating()
		modelController.newAlbum(for: selectedPin) { [weak self] result in
			guard let strongSelf = self else { return }
			
			self?.newAlbumActivityIndicator.stopAnimating()
			strongSelf.performAlbumEditButton.isEnabled = true
			strongSelf.configureUI()
			if case .Failure(let error) = result {
				if !((error as NSError).domain == "NSURLErrorDomain" && (error as NSError).code == -999) {
					strongSelf.showErrorAlert(title: "Album Error", message: "\(error.localizedDescription)")
				}
			}
		}
	}
	
	func removePhotos(_ photos: [Photo]) {
		performAlbumEditButton.isEnabled = false
		modelController.removePhotos(photos) {
			self.performAlbumEditButton.isEnabled = true
			self.configureUI()
		}
	}
	
	func showErrorAlert(title: String, message: String) {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
		alertController.addAction(okAction)
		present(alertController, animated: true, completion: nil)
	}
	
	
	//******************************************************
	// MARK: - Collection View Data Source
	//******************************************************
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return photoResultsController.fetchedObjects?.count ?? 0
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let photo = photoResultsController.object(at: indexPath)
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
		
		if let image = photo.image {
			loadingPhotos[photo] = .loaded(image: image)
		} else {
			if let photoState = loadingPhotos[photo] {
				if case PhotoDisplayState.error = photoState {
					loadingPhotos[photo] = .error
				}
				
			} else {
				loadingPhotos[photo] = .loading
				modelController.loadData(of: photo) { [weak self] result in
					guard let strongSelf = self else { return }
					if case .Failure = result {
						strongSelf.loadingPhotos[photo] = .error
					}
				}
			}
		}

		cell.state = loadingPhotos[photo]!
		return cell
	}
	
	
	//******************************************************
	// MARK: - Collection View Delegate
	//******************************************************
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		configureUI()
	}
	
	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		configureUI()
	}
	
	
	//******************************************************
	// MARK: - FRC Delegate
	//******************************************************
	
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {	
		insertedIndexPaths = []
		deletedIndexPaths = []
		updatedIndexPaths = []
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
			case .insert: insertedIndexPaths.append(newIndexPath!)
			case .delete: deletedIndexPaths.append(indexPath!)
			case .update: updatedIndexPaths.append(indexPath!)
			default:	break
		}
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		albumCollectionView.performBatchUpdates({
			self.albumCollectionView.deleteItems(at: self.deletedIndexPaths)
			self.albumCollectionView.insertItems(at: self.insertedIndexPaths)
			self.albumCollectionView.reloadItems(at: self.updatedIndexPaths)
		}, completion: nil)
	}
}
