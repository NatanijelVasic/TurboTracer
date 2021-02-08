//
//  camera.m
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <MetalKit/MetalKit.h>

#import "camera.h"

Camera::Camera(simd_float3 init_position,
               simd_float3 init_direction,
               simd_float3 init_direction_up,
               float init_zoom){
    
    position = init_position;
    direction = init_direction;
    direction_up = init_direction_up;
    direction_side = simd_cross(direction_up, direction);
    zoom = init_zoom;
    
}
