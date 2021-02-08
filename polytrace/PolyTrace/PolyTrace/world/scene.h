//
//  scene.h
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <MetalKit/MetalKit.h>

#import <vector>

#import "block.h"
#import "color.h"
#import "config.h"
#import "metal.h"
#import "triangle.h"
#import "vertex.h"

class Scene{
    
    vector<Block> blocks;
    Block overflow_block = Block(simd_make_float3(-1.0f, -1.0f, -1.0f), -1.0f);
    simd_float3 snap_to_block(simd_float3 position,
                              float block_scale);
    
public:
    
    vector<Vertex> vertices;
    vector<Triangle> triangles;
    vector<Triangle> sorted_triangles;
    
    vector<int> gpu_blockmap;
    vector<simd_float3> gpu_block_positions;
    vector<simd_float3> gpu_sorted_vertex_a;
    vector<simd_float3> gpu_sorted_vertex_b;
    vector<simd_float3> gpu_sorted_vertex_c;
    int block_n = 0;
    float block_scale = BLOCKS;
    
    Color* dome;
    
    void load_dome(string filepath);
    
    void blockify(float block_scale);
    void gpu_load_scene(MetalRaytrace* rtxt);
    
};
