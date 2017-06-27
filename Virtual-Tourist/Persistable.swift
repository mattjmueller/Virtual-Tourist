//
//  Persistable.swift
//  Virtual Tourist
//
//  Created by Matthew Mueller on 5/9/17.
//  Copyright © 2017 Matthew Mueller. All rights reserved.
//

import Foundation

protocol Persistable: class {
	weak var modelController: ModelController! { get set }
}
