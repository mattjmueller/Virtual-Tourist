//*********************************************************
// ModelController.swift
// Virtual Tourist
//
// Created by Fernando Rodríguez Romero on 21/02/16.
// Copyright © 2016 udacity.com. All rights reserved.
//*********************************************************

import CoreData

import UIKit
import CoreLocation
import CoreData

protocol Persistable: class {
	weak var modelController: ModelController! { get set }
}

protocol ModelController: class {
	func getAllPins() -> NSFetchedResultsController<Pin>
	func addPin(at coordinate: CLLocationCoordinate2D)
	func removePin(_ pin: Pin)
	func newAlbum(for pin: Pin, completionHandler: @escaping (Result<Void>) -> Void)
	func getPhotosFor(pin: Pin) -> NSFetchedResultsController<Photo>
	func loadData(of photo: Photo, completionHandler: @escaping (Result<Void>) -> Void)
	func removePhotos(_ photos: [Photo], completionHandler: (() -> Void)?)
	func cancelNetworkRequests()
	
	init(photoService: RemotePhotoService)
}

final class CoreDataModelController: ModelController {
	//******************************************************
	// MARK: Private Properties
	//******************************************************

	private var photoService: RemotePhotoService
	
	private lazy var persistentContainer: NSPersistentContainer = {
		let container = NSPersistentContainer(name: "Virtual Tourist")
		
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		
		container.viewContext.automaticallyMergesChangesFromParent = true
		return container
	}()
	
	
	//******************************************************
	// MARK: Init
	//******************************************************
	
	init(photoService: RemotePhotoService) {
		self.photoService = photoService
	}
	
	
	//******************************************************
	// MARK: Methods
	//******************************************************
	
	func getAllPins() -> NSFetchedResultsController<Pin> {
		let fetchRequest = Pin.fetchAllRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
		return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
	}
	
	func addPin(at coordinate: CLLocationCoordinate2D) {
		persistentContainer.performBackgroundTask() { context in
			_ = Pin(coordinate: coordinate, context: context)
			self.saveContext(context)
		}
	}
	
	func removePin(_ pin: Pin) {
		persistentContainer.performBackgroundTask() { context in
			let pinToDelete = context.object(with: pin.objectID)
			context.delete(pinToDelete)
			self.saveContext(context)
		}
	}
	
	func newAlbum(for pin: Pin, completionHandler: @escaping (Result<Void>) -> Void) {
		persistentContainer.performBackgroundTask() { context in
			let pin = context.object(with: pin.objectID) as! Pin
			self.removePhotos(Array<Photo>(pin.album))
			
			self.photoService.randomImagesNear(latitude: pin.latitude, longitude: pin.longitude) { result in
				switch result {
				case .Success(let urls):
					self.persistentContainer.performBackgroundTask() { context in
						let pin = context.object(with: pin.objectID) as! Pin
						pin.addToAlbum(Set<Photo>(urls.map { Photo.init(url: $0, context: context) }))
						self.saveContext(context)
						DispatchQueue.main.async {
							completionHandler(.Success())
						}
					}
				case .Failure(let error):
					DispatchQueue.main.async {
						completionHandler(.Failure(error))
					}
				}
			}
		}
	}
	
	func getPhotosFor(pin: Pin) -> NSFetchedResultsController<Photo> {
		let fetchRequest = Photo.fetchAllRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sourceURL", ascending: true)]
		fetchRequest.predicate = NSPredicate(format: "album = %@", argumentArray: [pin])
		return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
	}
	
	func loadData(of photo: Photo, completionHandler: @escaping (Result<Void>) -> Void) {
		persistentContainer.performBackgroundTask() { context in
			let photo = context.object(with: photo.objectID) as! Photo
			
			self.photoService.getImage(from: photo.url) { result in
				switch result {
				case .Success(let image):
					self.persistentContainer.performBackgroundTask() { context in
						let photo = context.object(with: photo.objectID) as! Photo
						photo.image = image
						self.saveContext(context)
					}
					completionHandler(.Success())
				case .Failure(let error):
					completionHandler(.Failure(error))
				}
			}
		}
	}
	
	func removePhotos(_ photos: [Photo], completionHandler:  (() -> Void)? = nil) {
		persistentContainer.performBackgroundTask() { context in
			for photo in photos {
				context.delete(context.object(with: photo.objectID))
			}
		
			self.saveContext(context)
			DispatchQueue.main.async {
				completionHandler?()
			}
		}
	}
	
	func cancelNetworkRequests() {
		photoService.cancelRequests()
	}
	
	//******************************************************
	// MARK: Save
	//******************************************************
	
	private func saveContext(_ context: NSManagedObjectContext) {
		do {
			try context.save()
			return
		} catch {
			fatalError("Error saving to core data: \(error)")
		}
	}
}
