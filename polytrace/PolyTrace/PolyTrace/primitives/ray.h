//
//  ray.h
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <MetalKit/MetalKit.h>

class Ray{

public:
    
    simd_float3 position;
    simd_float3 direction;
    bool in_medium;

    Ray();
    Ray(simd_float3 init_position,
        simd_float3 init_direction,
        bool init_in_medium);
        
};
