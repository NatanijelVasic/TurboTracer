//
//  triangle.mm
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <MetalKit/MetalKit.h>

#import "triangle.h"
#import "vertex.h"

Triangle::Triangle(Vertex* init_a,
                   Vertex* init_b,
                   Vertex* init_c,
                   char init_type,
                   bool init_overflow,
                   bool init_smooth_normal){
        
    a = init_a;
    b = init_b;
    c = init_c;
    n = simd_normalize(simd_cross(b->position - a->position,
                                  c->position - a->position));
    type = init_type;
    overflow = init_overflow;
    smooth_normal = init_smooth_normal;
        
}
