//
//  MetalRaytrace.h
//  PolyTrace
//
//  Created by Natanijel Vasic on 13/01/2021.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

@interface MetalRaytrace : NSObject

- (instancetype) initWithDevice: (id<MTLDevice>) device;

- (void) prepareData: (simd_float3*) blockPosition
                    : (int*) blockTriIndex
                    : (int*) blockN
                    : (float*) blockScale
                    : (simd_float3*) triA
                    : (simd_float3*) triB
                    : (simd_float3*) triC
                    : (unsigned long) triN;

- (int*) sendComputeCommand: (simd_float3*) position_ray
                           : (simd_float3*) direction_ray
                           : (unsigned long) N;

@end
