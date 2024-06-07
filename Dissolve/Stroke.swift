//
//  Stroke.swift
//  Dissolve
//
//  Created by 이현배 on 6/6/24.
//

import Metal
import simd

struct Stroke {
	var location1: SIMD2<Float>
	var location2: SIMD2<Float>?
	var location3: SIMD2<Float>?
	var location4: SIMD2<Float>?
	var elapsed: Float
	var buffer: MTLBuffer?
	
	init(location: SIMD2<Float>) {
		location1 = location
		location2 = nil
		location3 = nil
		location4 = nil
		elapsed = 0
		buffer = nil
	}
	
	mutating func sketch(location: SIMD2<Float>, radius: Float) -> Segment {
		location4 = location3
		location3 = location2
		location2 = location1
		location1 = location
		if let location2 {
			if let location3 {
				if let location4 {
					let direction2 = (location2 - location4) * 0.5
					let handle2 = location3 + direction2 * 0.5
					let direction1 = (location1 - location3) * 0.5
					let handle1 = location2 - direction1 * 0.5
					return sketchCurve(from: location3, fromHandle: handle2, toHandle: handle1, to: location2, radius: radius)
				} else {
					let handle2 = location3
					let direction1 = (location1 - location3) * 0.5
					let handle1 = location2 - direction1 * 0.5
					return sketchCurve(from: location3, fromHandle: handle2, toHandle: handle1, to: location2, radius: radius)
				}
			} else {
				return sketchPoint(location: location2, radius: radius)
			}
		} else {
			return Segment()
		}
	}
	
	func sketchPoint(location: SIMD2<Float>, radius: Float) -> Segment {
		return Segment(
			dabs: [ location ],
			box: Box(
				left: max(Int(floor(location.x - radius)), 0),
				top: max(Int(floor(location.y - radius)), 0),
				right: max(Int(ceil(location.x + radius)), 0),
				bottom: max(Int(ceil(location.y + radius)), 0)
			)
		)
	}
	
	mutating func sketchLine(from: SIMD2<Float>, to: SIMD2<Float>, radius: Float) -> Segment {
		let d = distance(from, to)
		let interval: Float = 1
		var t = (interval - elapsed) / d
		if t <= 0.0 {
			elapsed = 0.0
			return Segment()
		} else {
			elapsed += d
			var segment = Segment()
			while 0.0 < t && t <= 1.0 {
				let location = from * (1 - t) + to * t
				segment = segment + sketchPoint(location: location, radius: radius)
				elapsed = (1 - t) * d
				t += interval / d
			}
			return segment
		}
	}
	
	mutating func sketchCurve(from: SIMD2<Float>, fromHandle: SIMD2<Float>, toHandle: SIMD2<Float>, to: SIMD2<Float>, radius: Float) -> Segment {
		let line = Line(point1: to, point2: from)
		let d1 = line.distanceTo(point: toHandle)
		let d2 = line.distanceTo(point: fromHandle)

		if (d1 < 0.5 && d2 < 0.5) || d1.isNaN || d2.isNaN {
			return sketchLine(from: from, to: to, radius: radius)
		} else {
			let h = (fromHandle + toHandle) * 0.5
			let left2 = (from + fromHandle) * 0.5
			let left3 = (left2 + h) * 0.5
			let right2 = (to + toHandle) * 0.5
			let right3 = (right2 + h) * 0.5
			let location = (left3 + right3) * 0.5
			return sketchCurve(from: from, fromHandle: left2, toHandle: left3, to: location, radius: radius) + sketchCurve(from: location, fromHandle: right2, toHandle: right3, to: to, radius: radius)
		}
	}
	
	mutating func paint(device: MTLDevice, segment: Segment) {
		let bufferLength = segment.dabs.count * MemoryLayout<SIMD2<Float>>.stride
		var dabs = segment.dabs
		if let buffer {
			if buffer.length < bufferLength {
				self.buffer = device.makeBuffer(bytes: &dabs, length: bufferLength, options: .storageModeShared)
			} else {
				memcpy(buffer.contents(), &dabs, bufferLength)
			}
		} else {
			buffer = device.makeBuffer(bytes: &dabs, length: bufferLength, options: .storageModeShared)
		}
	}
}
