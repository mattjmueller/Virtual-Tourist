//*********************************************************
// Pin+MKAnnotation.swift
// Virtual Tourist
//
// Created by Matthew Mueller on 5/9/17.
// Copyright © 2017 Matthew Mueller. All rights reserved.
//*********************************************************

import Foundation
import MapKit
import CoreData

extension Pin: MKAnnotation {
	convenience init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
		self.init(context: context)
		self.latitude = coordinate.latitude
		self.longitude = coordinate.longitude
	}
	
	public var coordinate: CLLocationCoordinate2D {
		return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
	}
}
