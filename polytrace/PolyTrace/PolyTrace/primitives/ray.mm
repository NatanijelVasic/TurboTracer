//
//  ray.m
//  PolyTrace
//
//  Created by Natanijel Vasic on 27/01/2021.
//

#import <MetalKit/MetalKit.h>

#import "ray.h"

Ray::Ray(){
    
    position = simd_make_float3(0.0f, 0.0f, 0.0f);
    direction = simd_make_float3(0.0f, 0.0f, 0.0f);
    in_medium = false;
    
}

Ray::Ray(simd_float3 init_position,
         simd_float3 init_direction,
         bool init_in_medium){
    
    position = init_position;
    direction = init_direction;
    in_medium = init_in_medium;
    
}
