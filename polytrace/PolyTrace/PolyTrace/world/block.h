//
//  block.h
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <MetalKit/MetalKit.h>

#import <vector>

#import "triangle.h"

using namespace std;

class Block{
    
public:
    
    simd_float3 position;
    float length;
    vector<int> triangle_ids;
    
    Block(simd_float3 init_position, float block_scale);
    
};
