//
//  block.m
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <MetalKit/MetalKit.h>

#import <vector>

#import "block.h"

Block::Block(simd_float3 init_position, float block_scale){
    
    position = init_position;
    length = 1.0f/block_scale;
    
}
