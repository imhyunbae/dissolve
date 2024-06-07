//
//  Segment.swift
//  Dissolve
//
//  Created by 이현배 on 6/6/24.
//

import simd

struct Segment {
	let dabs: [SIMD2<Float>]
	let box: Box
	
	init(dabs: [SIMD2<Float>] = [], box: Box = Box()) {
		self.dabs = dabs
		self.box = box
	}
	
	static func +(left: Segment, right: Segment) -> Segment {
		return Segment(dabs: left.dabs + right.dabs, box: left.box + right.box)
	}
}
