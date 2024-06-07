//
//  Painter.swift
//  Dissolve
//
//  Created by 이현배 on 6/6/24.
//

import Metal

struct PaintInfo {
	let color: SIMD4<Float>
	let offset: SIMD2<UInt32>
	let count: UInt32
	let radius: Float
}

class Painter {
	var pipeline: MTLComputePipelineState? = nil
	var stroke: Stroke? = nil
	
	init(device: MTLDevice, library: MTLLibrary) throws {
		if let paintFunction = library.makeFunction(name: "paint") {
			pipeline = try device.makeComputePipelineState(function: paintFunction)
		}
	}
	
	func paint(location: SIMD2<Float>, radius: Float, color: SIMD4<Float>, texture: MTLTexture, commandBuffer: MTLCommandBuffer, device: MTLDevice) {
		guard var stroke else {
			stroke = Stroke(location: location)
			return
		}
		
		let segment = stroke.sketch(location: location, radius: radius)
		guard !segment.dabs.isEmpty, segment.box.isValid else { return }
		
		stroke.paint(device: device, segment: segment)
		
		if let pipeline,
			 let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
			var paintInfo = PaintInfo(color: color, offset: SIMD2<UInt32>(UInt32(segment.box.left), UInt32(segment.box.top)), count: UInt32(segment.dabs.count), radius: radius)
			computeEncoder.setComputePipelineState(pipeline)
			computeEncoder.setTexture(texture, index: 0)
			computeEncoder.setBuffer(stroke.buffer, offset: 0, index: 0)
			computeEncoder.setBytes(&paintInfo, length: MemoryLayout<PaintInfo>.stride, index: 1)
			let w = pipeline.threadExecutionWidth
			let h = pipeline.maxTotalThreadsPerThreadgroup / w
			let threadsPerThreadGroup = MTLSize(width: w, height: h, depth: 1)
			if device.supportsFamily(.apple4) {
				let threadsPerGrid = MTLSize(width: segment.box.width, height: segment.box.height, depth: 1)
				computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
			} else {
				let sizeX = Int(ceil(Float(segment.box.width) / Float(w)))
				let sizeY = Int(ceil(Float(segment.box.height) / Float(h)))
				let threadGroupsPerGrid = MTLSize(width: sizeX, height: sizeY, depth: 1)
				computeEncoder.dispatchThreadgroups(threadGroupsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
			}
			computeEncoder.endEncoding()
		}
		
		self.stroke = stroke
	}
}
