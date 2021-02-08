//
//  triangle.h
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <MetalKit/MetalKit.h>

#import "vertex.h"

class Triangle{

public:

    Vertex* a;
    Vertex* b;
    Vertex* c;
    simd_float3 n;
    
    char type;
    bool overflow;
    bool smooth_normal;

    Triangle(Vertex* init_a,
             Vertex* init_b,
             Vertex* init_c,
             char init_type,
             bool init_overflow,
             bool init_smooth_normal);
        
};
