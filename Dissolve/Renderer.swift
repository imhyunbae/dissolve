//
//  Renderer.swift
//  Dissolve
//
//  Created by 이현배 on 6/6/24.
//

import Metal

class Renderer {
	var pipeline: MTLRenderPipelineState? = nil
	
	init(device: MTLDevice, library: MTLLibrary) throws {
		let pipelineDescriptor = MTLRenderPipelineDescriptor()
		pipelineDescriptor.vertexFunction = library.makeFunction(name: "render_vertex")
		pipelineDescriptor.fragmentFunction = library.makeFunction(name: "render_fragment")
		pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
		pipeline = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
	}
	
	func render(texture: MTLTexture, commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, drawable: MTLDrawable) {
		if let pipeline,
			 let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
			renderCommandEncoder.setRenderPipelineState(pipeline)
			renderCommandEncoder.setFragmentTexture(texture, index: 0)
			renderCommandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
			renderCommandEncoder.endEncoding()
		}
	}
}
