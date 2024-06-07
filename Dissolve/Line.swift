//
//  Line.swift
//  Dissolve
//
//  Created by 이현배 on 6/6/24.
//

import simd

struct Line {
	let point1: SIMD2<Float>
	let point2: SIMD2<Float>
		
	func distanceTo(point: SIMD2<Float>) -> Float {
		let vector = point1 - point2
		let l2 = dot(vector, vector)
		let t1 = min(max(dot(point, point2) / l2, 0.0), 1.0)
		return length(point - point2 + vector * t1)
	}
}
