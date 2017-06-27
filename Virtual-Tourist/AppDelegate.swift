//*********************************************************
// AppDelegate.swift
// Virtual Tourist
//
// Created by Matthew Mueller on 5/8/17.
// Copyright © 2017 Matthew Mueller. All rights reserved.
//*********************************************************

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	
	//******************************************************
	// MARK: - Dependencies
	//******************************************************

	private var networkService: NetworkService!
	private var photoService: RemotePhotoService!
	private var modelController: ModelController!

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		networkService = NetworkService()
		photoService = FlickrPhotoService(networkService: networkService)
		modelController = CoreDataModelController(photoService: photoService)
		
		if let persistable = (window?.rootViewController as? UINavigationController)?.viewControllers.first as? Persistable {
			persistable.modelController = modelController
		}
		
		return true
	}
}

