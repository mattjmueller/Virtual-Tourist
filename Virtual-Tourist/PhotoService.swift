//*********************************************************
// PhotoService.swift
// Virtual Tourist
//
// Created by Matthew Mueller on 5/5/17.
// Copyright © 2017 Matthew Mueller. All rights reserved.
//*********************************************************

import Foundation
import UIKit

enum RemotePhotoServiceError: Error {
	case failedRequest
	case noPhotos
	case invalidImageData
}

protocol RemotePhotoService: class {
	func randomImagesNear(latitude: Double, longitude: Double, completionHandler: @escaping (Result<[URL]>) -> Void)
	func getImage(from url: URL, completionHandler: @escaping (Result<UIImage>) -> Void)
	func cancelRequests()
}

class FlickrPhotoService: RemotePhotoService, RestClient {
	//******************************************************
	// MARK: - Private Properties
	//******************************************************

	let maxSearchResults = 4000
	let pageSize = 100
	
	//******************************************************
	// MARK: - Rest Client Conformance
	//******************************************************
	
	let networkService: NetworkService
	var defaultConfig = RestClientConfig(
		urlScheme: .HTTPS,
		host: "api.flickr.com",
		apiBase: "/services/rest",
		defaultheaders: [:]
	)
	
	required init(networkService: NetworkService) {
		self.networkService = networkService
	}
	
	func extractResponseDict(data: Data, completionHandler: @escaping (Result<[String : Any]>) -> Void) {
		guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
			return completionHandler(.Failure(RestError.invalidJSONObject))
		}
		
		guard let jsonDict = jsonObject as? [String:Any],
				let status = jsonDict["stat"] as? String, status == "ok",
				let photosDict = jsonDict["photos"] as? [String:Any] else {
			return completionHandler(.Failure(RestError.invalidJSONDict))
		}
		
		completionHandler(.Success(photosDict))
	}
	
	
	//******************************************************
	// MARK: - Public Requests
	//******************************************************
	
	func randomImagesNear(latitude: Double, longitude: Double, completionHandler: @escaping (Result<[URL]>) -> Void) {
		let randomPageRequest: RestRequest<Int> = createSearchRequest(latitude: latitude, longitude: longitude) { photosDict in
			guard let totalPages = photosDict["pages"] as? Int else {
				return .Failure(RemotePhotoServiceError.noPhotos)
			}

			let pageLimit = min(self.maxSearchResults / self.pageSize, totalPages)
			let randomPage = arc4random_uniform(UInt32(pageLimit)) + 1
			return .Success(Int(randomPage))
		}
		
		func getImages(page: Int, completionHandler: @escaping (Result<[URL]>) -> Void) {
			let limit = 21
			let imagesRequest: RestRequest<[URL]> = self.createSearchRequest(latitude: latitude, longitude: longitude, page: page) { photoDict in
				guard let photosArray = photoDict["photo"] as? [[String:Any]] else {
					return .Failure(RemotePhotoServiceError.noPhotos)
				}
				
				let resultArray = self.chooseRandomPhotos(count: limit, from: photosArray)
				return .Success(resultArray)
			}
			
			self.perform(request: imagesRequest, completionHandler: completionHandler)
		}
		
		let chained = perform • getImages
		chained(randomPageRequest, completionHandler)
	}
	
	func getImage(from url: URL, completionHandler: @escaping (Result<UIImage>) -> Void) {
		networkService.fetchContents(of: url) { result in
			switch result {
			case .Success(let data):
				if let image = UIImage(data: data) {
					completionHandler(.Success(image))
				} else {
					completionHandler(.Failure(RemotePhotoServiceError.invalidImageData))
				}
			case .Failure(let error):
				completionHandler(.Failure(error))
			}
		}
	}
	
	func cancelRequests() {
		networkService.cancelActiveRequests()
	}
	
	
	//******************************************************
	// MARK: - Private Methods
	//******************************************************

	private func chooseRandomPhotos(count: Int, from photosArray: [[String:Any]]) -> [URL] {
		guard photosArray.count > 0 else { return [] }
			
		var resultArray = [URL]()
		var indexesTried = Set<Int>()
		
		while resultArray.count < min(photosArray.count, count) || indexesTried.count == photosArray.count {
			var randomPhotoIndex: Int = Int(arc4random_uniform(UInt32(photosArray.count)))
			while indexesTried.contains(randomPhotoIndex) {
				randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
			}
			
			let photoDict = photosArray[randomPhotoIndex] as [String:Any]
			if let imageUrlString = photoDict["url_m"] as? String {
				if let url = URL(string: imageUrlString) {
					resultArray.append(url)
				}
			}
			
			indexesTried.insert(randomPhotoIndex)
		}
		
		return resultArray
	}
	
	private func createSearchRequest<T>(latitude: Double, longitude: Double, page: Int = 1, parseModel: @escaping ([String:Any]) -> Result<T>) -> RestRequest<T> {
		return RestRequest(
			methodType: .GET,
			method: "",
			parameters: [
				"method": "flickr.photos.search",
				"api_key": "0c660c019b91245a00d3c93d246a5ef7",
				"bbox": bboxString(latitude: latitude, longitude: longitude),
				"safe_search": "1",
				"per_page": "\(pageSize)",
				"page": "\(page)",
				"extras": "url_m",
				"format": "json",
				"nojsoncallback": "1"
				],
			jsonData: nil,
			headers: [:],
			modelFromResponseDict: parseModel
		)
	}
	
	private func bboxString(latitude: Double, longitude: Double) -> String {
		let radius = 1.0
		let latRange = (-90.0, 90.0)
		let longRange = (-180.0, 180.0)
		
		let minimumLon = max(longitude - radius, longRange.0)
		let minimumLat = max(latitude - radius, latRange.0)
		let maximumLon = min(longitude + radius, longRange.1)
		let maximumLat = min(latitude + radius, latRange.1)
		return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
	}
}
