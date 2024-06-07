//
//  Box.swift
//  Dissolve
//
//  Created by 이현배 on 6/6/24.
//

import Foundation

struct Box {
	var left: Int
	var top: Int
	var right: Int
	var bottom: Int
	
	init(left: Int = Int.max, top: Int = Int.max, right: Int = Int.min, bottom: Int = Int.min) {
		self.left = left
		self.top = top
		self.right = right
		self.bottom = bottom
	}
	
	var isValid: Bool { get { return top < bottom && left < right } }
	var width: Int { get { return right - left } }
	var height: Int { get { return bottom - top } }
	
	static func +(left: Box, right: Box) -> Box {
		return Box(left: min(left.left, right.left), top: min(left.top, right.top), right: max(left.right, right.right), bottom: max(left.bottom, right.bottom))
	}
}
