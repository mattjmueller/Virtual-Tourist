//*********************************************************
// Photo.swift
// Virtual Tourist
//
// Created by Matthew Mueller on 5/30/17.
// Copyright © 2017 Matthew Mueller. All rights reserved.
//*********************************************************

import UIKit
import CoreData

@objc(Photo)
class Photo: NSManagedObject {
	//******************************************************
	// MARK: - Managed Properties
	//******************************************************

	@NSManaged private var imageData: Data?
	@NSManaged private var sourceURL: String
	@NSManaged var album: Pin
	
	
	//******************************************************
	// MARK: - Init
	//******************************************************

	convenience init(url: URL, context: NSManagedObjectContext) {
		self.init(context: context)
		self.url = url
	}
	
	
	//******************************************************
	// MARK: - Convenience
	//******************************************************
	
	@nonobjc class func fetchAllRequest() -> NSFetchRequest<Photo> {
		return NSFetchRequest<Photo>(entityName: "Photo")
	}
	
	var url: URL {
		get { return URL(string: sourceURL)! }
		set { sourceURL = newValue.absoluteString }
	}
	
	var image: UIImage? {
		get { return imageData.flatMap { UIImage(data: $0) } }
		set { imageData = newValue.flatMap { UIImageJPEGRepresentation($0, 1) } }
	}
}
