//
//  Kernels.metal
//  4D Pattern Capture
//
//  Created by Taylor Hinchliffe on 6/13/24.
//

#include <metal_stdlib>
using namespace metal;

kernel void processFrame(
    texture2d<float, access::read> inTexture [[texture(0)]],
    texture2d<float, access::write> outTexture [[texture(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) {
        return;
    }

    float4 color = inTexture.read(gid);

    // Apply chroma key to remove black background
    if (color.r < 0.1 && color.g < 0.1 && color.b < 0.1) {
        color.a = 0.0;  // Set alpha to 0 to make it transparent
    }

    outTexture.write(color, gid);
}
