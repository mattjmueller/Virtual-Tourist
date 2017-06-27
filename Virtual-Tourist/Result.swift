//*********************************************************
// Result.swift
// Virtual Tourist
//
// Created by Matthew Mueller on 4/24/17.
// Copyright © 2017 Matthew Mueller. All rights reserved.
//*********************************************************

import Foundation

enum Result<T> {
	case Success(T)
	case Failure(Error)
}
