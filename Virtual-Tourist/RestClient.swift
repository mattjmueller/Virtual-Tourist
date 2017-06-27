//*********************************************************
// RestClient.swift
// Virtual Tourist
//
// Created by Matthew Mueller on 4/24/17.
// Copyright © 2017 Matthew Mueller. All rights reserved.
//*********************************************************

import Foundation

//**************************
// Rest Types
//**************************

enum RestError: Error {
	case invalidJSONObject
	case invalidJSONDict
	case invalidModelDict
	case invalidURL
}

enum HTTPRequestType: String {
	case GET = "GET"
	case PUT = "PUT"
	case POST = "POST"
	case DELETE = "DELETE"
}

enum URLScheme: String {
	case HTTP = "http"
	case HTTPS = "https"
}


//**************************
// Rest Request
//**************************

struct RestRequest<T> {
	let methodType: HTTPRequestType
	let method: String
	var parameters: [String:Any]
	var jsonData: [String:Any]?
	var headers: [String:String]
	var modelFromResponseDict: ([String:Any]) -> Result<T>
	
	func parseModel(responseDict: [String:Any], completionHandler: @escaping (Result<T>) -> Void) {
		completionHandler(modelFromResponseDict(responseDict))
	}
}


//**************************
// Rest Client
//**************************

struct RestClientConfig {
	let urlScheme: URLScheme
	let host: String
	let apiBase: String
	let defaultheaders: [String:String]
}

protocol RestClient {
	var networkService: NetworkService { get }
	var defaultConfig: RestClientConfig { get }
	
	init(networkService: NetworkService)
	func perform<T>(request: RestRequest<T>, completionHandler: @escaping (Result<T>) -> Void)
	func extractResponseDict(data: Data, completionHandler: @escaping (Result<[String:Any]>) -> Void)
}

extension RestClient {
	func perform<T>(request: RestRequest<T>, completionHandler: @escaping (Result<T>) -> Void) {
		let chained: Async<RestRequest<T>, T> = buildURLRequest • networkService.fetchRequest • extractResponseDict • request.parseModel
		chained(request, completionHandler)
	}

	func buildURLRequest<T>(_ restRequest: RestRequest<T>, completionHandler: @escaping (Result<URLRequest>) -> Void) {
		var components = URLComponents()
		components.scheme = defaultConfig.urlScheme.rawValue
		components.host = defaultConfig.host
		components.path = defaultConfig.apiBase + restRequest.method
		
		if restRequest.parameters.count > 0 {
			components.queryItems = [URLQueryItem]()
			for (key, value) in restRequest.parameters {
				let escapedKey: String = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
				let queryItem = URLQueryItem(name: escapedKey, value: "\(value)")
				components.queryItems!.append(queryItem)
			}
		}
		
		guard let url = components.url else {
			return completionHandler(.Failure(RestError.invalidURL))
		}
		
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = restRequest.methodType.rawValue
		
		for (key, value) in defaultConfig.defaultheaders {
			urlRequest.addValue(value, forHTTPHeaderField: key)
		}
		
		for (key, value) in restRequest.headers {
			urlRequest.addValue(value, forHTTPHeaderField: key)
		}
		
		if let body = restRequest.jsonData {
			do {
				urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
			} catch {
				completionHandler(.Failure(RestError.invalidJSONObject))
			}
		}
		
		return completionHandler(.Success(urlRequest))
	}
}
