//
//  ContentView.swift
//  Dissolve
//
//  Created by 이현배 on 6/6/24.
//

import SwiftUI
import MetalKit

class DrawView: MTKView, MTKViewDelegate {
	var commandQueue: MTLCommandQueue? = nil
	var renderer: Renderer? = nil
	var painter: Painter? = nil
	var texture: MTLTexture? = nil
	var viewModel: ContentViewModel? = nil
	
	required init(coder: NSCoder) {
		super.init(coder: coder)
		setup()
	}
	
	override init(frame frameRect: CGRect, device: (any MTLDevice)?) {
		super.init(frame: frameRect, device: device)
		setup()
	}
	
	func createTexture() -> MTLTexture? {
		guard let device else { return nil }
		let textureDescriptor = MTLTextureDescriptor()
		textureDescriptor.textureType = .type2D
		textureDescriptor.width = 1024
		textureDescriptor.height = 1024
		textureDescriptor.pixelFormat = .bgra8Unorm
		textureDescriptor.usage = [.shaderRead, .shaderWrite]
		return device.makeTexture(descriptor: textureDescriptor)
	}
	
	func setup() {
		device = MTLCreateSystemDefaultDevice()
		delegate = self
		
		clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
		
		commandQueue = device?.makeCommandQueue()
		
		guard let device, let library = device.makeDefaultLibrary() else { return }
		
		do {
			renderer = try Renderer(device: device, library: library)
			painter = try Painter(device: device, library: library)
			texture = createTexture()
			if let texture {
				var bytes = [UInt8](repeating: 255, count: texture.width * texture.height * 4)
				texture.replace(region: MTLRegionMake2D(0, 0, texture.width, texture.height), mipmapLevel: 0, withBytes: &bytes, bytesPerRow: texture.width * 4)
			}
		} catch {
			print(error.localizedDescription)
		}
	}
	
	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		
	}
	
	func draw(in view: MTKView) {
		guard let device,
					let currentDrawable,
					let currentRenderPassDescriptor,
					let texture,
					let viewModel,
					let commandBuffer = commandQueue?.makeCommandBuffer() else { return }
		
		viewModel.angle += Angle(degrees: 1)
		if let touch = viewModel.touch {
			let angle = -Float(viewModel.angle.radians)
			let rotationMatrix = float2x2(columns: (SIMD2<Float>(cos(angle), sin(angle)), SIMD2<Float>(-sin(angle), cos(angle))))
			var location = touch - SIMD2<Float>(repeating: 0.5)
			location = rotationMatrix * location
			location += SIMD2<Float>(repeating: 0.5)
			location *= SIMD2<Float>(Float(texture.width), Float(texture.height))
			painter?.paint(location: location, radius: 10, color: SIMD4<Float>(0, 0, 0, 1), texture: texture, commandBuffer: commandBuffer, device: device)
		} else {
			painter?.stroke = nil
		}
		
		renderer?.render(texture: texture, commandBuffer: commandBuffer, renderPassDescriptor: currentRenderPassDescriptor, drawable: currentDrawable)
		
		commandBuffer.present(currentDrawable)
		commandBuffer.commit()
	}
}

struct DrawViewRepresentable: UIViewRepresentable {
	let viewModel: ContentViewModel
	func makeUIView(context: Context) -> DrawView {
		return DrawView()
	}
	
	func updateUIView(_ view: DrawView, context: Context) {
		view.viewModel = viewModel
	}
}

class ContentViewModel: ObservableObject {
	@Published var angle = Angle(degrees: 0)
	var touch: SIMD2<Float>? = nil
	
}

struct ContentView: View {
	@StateObject var viewModel = ContentViewModel()
	
	var body: some View {
		ZStack {
			Color.black
			GeometryReader { proxy in
				DrawViewRepresentable(viewModel: viewModel)
					.scaleEffect(y: -1)
					.rotationEffect(viewModel.angle)
					.clipShape(Circle())
					.gesture(
						DragGesture()
							.onChanged { value in
								viewModel.touch = SIMD2<Float>(Float(value.location.x / proxy.size.width), Float(value.location.y / proxy.size.height))
							}
							.onEnded { value in
								viewModel.touch = nil
							}
					)
			}
			.aspectRatio(1.0, contentMode: .fit)
		}
		.ignoresSafeArea()
	}
}

#Preview {
    ContentView()
}
