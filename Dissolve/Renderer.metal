//
//  Renderer.metal
//  Dissolve
//
//  Created by 이현배 on 6/6/24.
//

#include <metal_stdlib>
using namespace metal;

typedef struct {
		float4 position [[position]];
		float2 uv;
} VertexOut;

vertex VertexOut render_vertex(uint vertexID [[ vertex_id ]]) {
	if (vertexID == 0) {
		return VertexOut { float4(-1.0f, -1.0f, 0.0f, 1.0f), float2(0.0f, 0.0f) };
	} else if (vertexID == 1) {
		return VertexOut { float4(1.0f, -1.0f, 0.0f, 1.0f), float2(1.0f, 0.0f) };
	} else if (vertexID == 2) {
		return VertexOut { float4(-1.0f, 1.0f, 0.0f, 1.0f), float2(0.0f, 1.0f) };
	} else if (vertexID == 3) {
		return VertexOut { float4(1.0f, -1.0f, 0.0f, 1.0f), float2(1.0f, 0.0f) };
	} else if (vertexID == 4) {
		return VertexOut { float4(1.0f, 1.0f, 0.0f, 1.0f), float2(1.0f, 1.0f) };
	} else if (vertexID == 5) {
		return VertexOut { float4(-1.0f, 1.0f, 0.0f, 1.0f), float2(0.0f, 1.0f) };
	} else {
		return VertexOut { float4(0.0f, 0.0f, 0.0f, 1.0f), float2(0.0f, 0.0f) };
	}
}

fragment float4 render_fragment(
																VertexOut           in              [[ stage_in ]],
																texture2d<float>    imageTexture    [[ texture(0) ]]
) {
		constexpr sampler colorSampler(mag_filter::linear, min_filter::linear);
		return imageTexture.sample(colorSampler, in.uv);
}
