//*********************************************************
// Pin.swift
// Virtual Tourist
//
// Created by Matthew Mueller on 5/30/17.
// Copyright © 2017 Matthew Mueller. All rights reserved.
//*********************************************************

import Foundation
import CoreData

@objc(Pin)
class Pin: NSManagedObject {
	//******************************************************
	// MARK: - Managed Properties
	//******************************************************

	@NSManaged var latitude: Double
	@NSManaged var longitude: Double
	@NSManaged var album: Set<Photo>
	
	//******************************************************
	// MARK: - Convenience
	//******************************************************
	
	var hasPhotos: Bool {
		return album.count > 0
	}
	
	@nonobjc class func fetchAllRequest() -> NSFetchRequest<Pin> {
		return NSFetchRequest<Pin>(entityName: "Pin")
	}
	
	@objc(addAlbumObject:)
	@NSManaged func addToAlbum(_ value: Photo)
	
	@objc(removeAlbumObject:)
	@NSManaged func removeFromAlbum(_ value: Photo)
	
	@objc(addAlbum:)
	@NSManaged func addToAlbum(_ values: Set<Photo>)
	
	@objc(removeAlbum:)
	@NSManaged func removeFromAlbum(_ values: Set<Photo>)
}

