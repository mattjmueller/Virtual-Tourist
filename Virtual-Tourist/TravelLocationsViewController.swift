//*********************************************************
// TravelLocationsViewController.swift
// Virtual Tourist
//
// Created by Matthew Mueller on 5/4/17.
// Copyright © 2017 Matthew Mueller. All rights reserved.
//*********************************************************

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, Persistable, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
	//******************************************************
	// MARK: - IB Outlets
	//******************************************************

	@IBOutlet weak private var mapView: MKMapView!
	@IBOutlet weak private var editButton: UIBarButtonItem!
	@IBOutlet weak private var deleteLabelHeightConstraint: NSLayoutConstraint!
	
	
	//******************************************************
	// MARK: - Public Properties
	//******************************************************
	
	weak var modelController: ModelController!
	var pinResultsController: NSFetchedResultsController<Pin>! {
		didSet {
			pinResultsController.delegate = self
			
			do {
				try pinResultsController.performFetch()
			} catch {
				print(error)
			}
			
			configureAnnotations()
		}
	}
	
	
	//******************************************************
	// MARK: - Private Properties
	//******************************************************
	
	private var isEditingPins = false {
		didSet {
			configureUI(editingPins: isEditingPins)
		}
	}
	
	
	//******************************************************
	// MARK: - Life Cycle
	//******************************************************
	
	override func viewDidLoad() {
		pinResultsController = modelController.getAllPins()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		isEditingPins = false
	}
	
	
	//******************************************************
	// MARK: - Helpers
	//******************************************************
	
	func configureUI(editingPins: Bool) {
		editButton.title = editingPins ? "Done" : "Edit"
		deleteLabelHeightConstraint.constant = editingPins ? 60 : 0
		view.setNeedsLayout()
		UIView.animate(withDuration: 0.12) { _ in
			self.view.layoutIfNeeded()
		}
	}
	
	func configureAnnotations() {
		mapView.removeAnnotations(mapView.annotations)
		mapView.addAnnotations(pinResultsController.fetchedObjects ?? [])
	}
	
	func viewAlbum(forPin pin: Pin) {
		let albumVC = storyboard!.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
		albumVC.modelController	= modelController
		albumVC.selectedPin = pin
		mapView.deselectAnnotation(pin, animated: false)
		navigationController!.pushViewController(albumVC, animated: true)
	}
	
	
	//******************************************************
	// MARK: - IB Actions
	//******************************************************
	
	@IBAction func editPins(_ sender: Any) {
		isEditingPins = !isEditingPins
	}
	
	@IBAction func dropPin(_ sender: UILongPressGestureRecognizer) {
		guard !isEditingPins else { return }
		guard sender.state == .began else { return }
		
		let touchPoint = sender.location(in: mapView)
		let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
		modelController.addPin(at: coordinate)
	}
	
	
	//******************************************************
	// MARK: - FRC Delegate
	//******************************************************
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			mapView.addAnnotation(anObject as! Pin)
		case .delete:
			mapView.removeAnnotation(anObject as! Pin)
		default:
			break
		}
	}
	

	//******************************************************
	// MARK: - Map View Delegate
	//******************************************************
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		let reuseId = "pin"
		var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
		
		if pinView == nil {
			pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
			pinView!.canShowCallout = false
			pinView!.pinTintColor = .red
		}
		else {
			pinView!.annotation = annotation
		}
		
		pinView!.animatesDrop = true
		return pinView
	}
	
	func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
		let pin = view.annotation as! Pin
		if isEditingPins {
			modelController.removePin(pin)
		} else {
			viewAlbum(forPin: pin)
		}
	}
}
