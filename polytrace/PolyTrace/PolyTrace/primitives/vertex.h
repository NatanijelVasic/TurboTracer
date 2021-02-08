//
//  vertex.h
//  PolyTrace
//
//  Created by Natanijel Vasic on 29/01/2021.
//

#import <MetalKit/MetalKit.h>

#import <vector>

using namespace std;

class Vertex{

public:
    
    simd_float3 position;
    vector<simd_float3> normals;
    simd_float3 n;

    Vertex();
    Vertex(simd_float3 init_position);
    
    void scale(float scale);
    void rotate(float angle);
    void offset(simd_float3 offset);
    
    void add_normal(simd_float3 normal);
    void calculate_vertex_normal();
        
};
