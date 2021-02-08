//
//  camera.h
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <MetalKit/MetalKit.h>

class Camera{

public:
    
    simd_float3 position;
    simd_float3 direction;
    simd_float3 direction_up;
    simd_float3 direction_side;
    float zoom;

    Camera(simd_float3 init_position,
           simd_float3 init_direction,
           simd_float3 init_direction_up,
           float init_zoom);
        
};
