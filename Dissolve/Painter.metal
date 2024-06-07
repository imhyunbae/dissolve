//
//  Painter.metal
//  Dissolve
//
//  Created by 이현배 on 6/6/24.
//

#include <metal_stdlib>
using namespace metal;

struct PaintInfo {
	float4 color;
	uint2 offset;
	uint32_t count;
	float radius;
};

float4 blend(float4 bottom, float4 top) {
		float w = 1.0f - (1.0f - bottom.w) * (1.0f - top.w);
		if (w == 0.0f) {
				return float4(top.xyz, w);
		} else {
				float r = (top.x * top.w + bottom.x * bottom.w * (1.0f - top.w)) / w;
				float g = (top.y * top.w + bottom.y * bottom.w * (1.0f - top.w)) / w;
				float b = (top.z * top.w + bottom.z * bottom.w * (1.0f - top.w)) / w;
				return float4(r, g, b, w);
		}
}

kernel void paint(
								 texture2d<float, access::read_write>		texture     [[texture(0)]],
								 const device float2*                   buffer      [[buffer(0)]],
								 const device PaintInfo*                paintInfo   [[buffer(1)]],
								 uint2                                  index       [[thread_position_in_grid]]
								 )
{
	uint2 coordinate = paintInfo->offset + index;
	float2 position = float2(coordinate);
	auto pixel = texture.read(coordinate);
	for (uint i = 0; i < paintInfo->count; i++) {
		const auto dab = buffer[i];
		float2 localPosition = (position - dab) / paintInfo->radius;
		float2 localUV = clamp((localPosition + float2(1.0f, 1.0f)) * 0.5f, 0.0f, 1.0f);
		if (localUV.x < 0.0f || localUV.y < 0.0f || 1.0f < localUV.x || 1.0f < localUV.y) continue;
		
		auto alpha = clamp((1.0f - smoothstep(0.45f, 0.5f, distance(float2(0.5f, 0.5f), localUV))) * paintInfo->color.w, 0.0f, 1.0f);
		pixel = blend(pixel, float4(paintInfo->color.xyz, alpha));
	}
	
	texture.write(pixel, coordinate);
}
