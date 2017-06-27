//*********************************************************
// ComposeOperator.swift
// Virtual Tourist
//
// Created by Matthew Mueller on 4/29/17.
// Copyright © 2017 Matthew Mueller. All rights reserved.
//*********************************************************

import Foundation

// Essentially an updated version of ths implementation:
// http://stackoverflow.com/a/38281463/7649952
// with further background from here
// http://alisoftware.github.io/swift/async/error/2016/02/06/async-errors/ and
// http://jensravens.com/how-to-train-your-monad/

precedencegroup ComposePrecedence {
	associativity: right
	higherThan: BitwiseShiftPrecedence
}

infix operator • : ComposePrecedence


typealias Async<T, U> = (T, @escaping (Result<U>) -> Void) -> Void


func compose<T, U, V>(_ f: @escaping Async<T, U>, _ g: @escaping Async<U, V>) -> Async<T, V> {
	return { value, completionHandler in
		f(value, { result in
			switch result {
			case .Success(let b): g(b, completionHandler)
			case .Failure(let e): completionHandler(.Failure(e))
			}
		})
	}
}

func •<T, U, V>(_ f: @escaping Async<T, U>, _ g: @escaping Async<U, V>) -> Async<T, V> {
	return compose(f, g)
}
