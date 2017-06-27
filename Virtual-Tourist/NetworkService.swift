//*********************************************************
// NetworkService.swift
// Virtual Tourist
//
// Created by Matthew Mueller on 4/22/17.
// Copyright © 2017 Matthew Mueller. All rights reserved.
//*********************************************************

import UIKit

enum NetworkError: Error {
	case requestFailed
	case noData
}


struct NetworkService {
	func fetchContents(of url: URL, completionHandler: @escaping (Result<Data>) -> Void) {
		fetchRequest(URLRequest(url: url), completionHandler: completionHandler)
	}
	
	func cancelActiveRequests() {
		URLSession.shared.getAllTasks() { tasks in
			for task in tasks { task.cancel() }
		}
	}
	
	func fetchRequest(_ request: URLRequest, completionHandler: @escaping (Result<Data>) -> Void) {
		URLSession.shared.dataTask(with: request) { data, response, error in
			guard error == nil else {
				return completionHandler(.Failure(error!))
			}
			
			guard let data = data else {
				return completionHandler(.Failure(NetworkError.noData))
			}
			
			completionHandler(.Success(data))
		}.resume()
	}
}
