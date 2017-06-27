//*********************************************************
// PhotoCollectionViewCell.swift
// Virtual Tourist
//
// Created by Matthew Mueller on 5/5/17.
// Copyright © 2017 Matthew Mueller. All rights reserved.
//*********************************************************

import UIKit

enum PhotoDisplayState {
	case loading, loaded(image: UIImage), error
}

class PhotoCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak private var photoImageView: UIImageView!
	@IBOutlet weak private var activityIndicator: UIActivityIndicatorView!
	
	var state: PhotoDisplayState = .loading {
		didSet {
			switch state {
			case .loading:
				photoImageView.backgroundColor = UIColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1.0)
				photoImageView.image = nil
				activityIndicator.startAnimating()
			case .loaded(let image):
				photoImageView.backgroundColor = UIColor.white
				photoImageView.image = image
				activityIndicator.stopAnimating()
			case .error:
				photoImageView.backgroundColor = UIColor(red: 0.8, green: 0.4, blue: 0.4, alpha: 1.0)
				photoImageView.image = nil
				activityIndicator.stopAnimating()
			}
		}
	}
	
	override var isSelected: Bool {
		didSet {
			photoImageView.alpha = isSelected ? 0.4 : 1.0
		}
	}
}
