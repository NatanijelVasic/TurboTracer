//
//  scene.m
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <MetalKit/MetalKit.h>

#import <fstream>
#import <iostream>
#import <map>
#import <vector>

#import "block.h"
#import "color.h"
#import "config.h"
#import "metal.h"
#import "scene.h"
#import "triangle.h"

using namespace std;

simd_float3 Scene::snap_to_block(simd_float3 position, float block_scale){
    
    float x = floor(block_scale * position[0]) / block_scale;
    float y = floor(block_scale * position[1]) / block_scale;
    float z = floor(block_scale * position[2]) / block_scale;
    return simd_make_float3(x, y, z);
    
}

void Scene::load_dome(string filepath){
    
    dome = new Color[DOMEHEIGHT * DOMEWIDTH];
    
    ifstream file_r { filepath + "_r.txt" };
    for (int i = 0; i < DOMEHEIGHT; i++) {
        for (int j = 0; j < DOMEWIDTH; j++) {
            file_r >> dome[i * DOMEWIDTH + j].r;
        }
    }
    
    ifstream file_g { filepath + "_g.txt" };
    for (int i = 0; i < DOMEHEIGHT; i++) {
        for (int j = 0; j < DOMEWIDTH; j++) {
            file_g >> dome[i * DOMEWIDTH + j].g;
        }
    }
    
    ifstream file_b { filepath + "_b.txt" };
    for (int i = 0; i < DOMEHEIGHT; i++) {
        for (int j = 0; j < DOMEWIDTH; j++) {
            file_b >> dome[i * DOMEWIDTH + j].b;
        }
    }
    
}

void Scene::blockify(float block_scale){
    
    map<tuple<float, float, float>, vector<int>> blockmap;
    int tris_sorted = 0;
    float average_tris_per_block;
    
    for(int t = 0; t < triangles.size(); t++){
        
        if(triangles[t].overflow == false){
            
            const simd_float3 a_block = snap_to_block(triangles[t].a->position, block_scale);
            const simd_float3 b_block = snap_to_block(triangles[t].b->position, block_scale);
            const simd_float3 c_block = snap_to_block(triangles[t].c->position, block_scale);
            
            tuple<float, float, float> key;
            
            key = make_tuple(a_block[0], a_block[1], a_block[2]);
            if(blockmap[key].size() == 0){
                blockmap[key].push_back(t);
            } else {
                if(t != blockmap[key].back()){
                    blockmap[key].push_back(t);
                }
            }
            
            key = make_tuple(b_block[0], b_block[1], b_block[2]);
            if(blockmap[key].size() == 0){
                blockmap[key].push_back(t);
            } else {
                if(t != blockmap[key].back()){
                    blockmap[key].push_back(t);
                }
            }
            
            key = make_tuple(c_block[0], c_block[1], c_block[2]);
            if(blockmap[key].size() == 0){
                blockmap[key].push_back(t);
            } else {
                if(t != blockmap[key].back()){
                    blockmap[key].push_back(t);
                }
            }
            
        } else {
            overflow_block.triangle_ids.push_back(t);
        }
        
    }
    
    for (auto const& [key, val] : blockmap){
        simd_float3 block_position = simd_make_float3(get<0>(key),
                                                      get<1>(key),
                                                      get<2>(key));
        blocks.push_back(Block(block_position, block_scale));
        for(int i = 0; i < val.size(); i++){
            blocks.back().triangle_ids.push_back(val[i]);
            tris_sorted++;
        }
    }
    
    average_tris_per_block = tris_sorted/blockmap.size();
    cout << endl << "Blocks: " << blockmap.size() << endl;
    cout << "Block Quads: " << blockmap.size()*6 << endl;
    cout << "Average Tris per Block: " << average_tris_per_block << endl;
    cout << "Overflow Tris: " << overflow_block.triangle_ids.size() << endl;
    cout << "Tris sorted: " << tris_sorted + overflow_block.triangle_ids.size() << endl << endl;
    
    block_n = (int)blockmap.size();
    
}

void Scene::gpu_load_scene(MetalRaytrace* rtxt){
    
    gpu_blockmap.push_back(0);
    
    gpu_block_positions.push_back(overflow_block.position);
    for(int i = 0; i < overflow_block.triangle_ids.size(); i++){
        gpu_sorted_vertex_a.push_back(triangles[overflow_block.triangle_ids[i]].a->position);
        gpu_sorted_vertex_b.push_back(triangles[overflow_block.triangle_ids[i]].b->position);
        gpu_sorted_vertex_c.push_back(triangles[overflow_block.triangle_ids[i]].c->position);
        sorted_triangles.push_back(triangles[overflow_block.triangle_ids[i]]);
    }
    gpu_blockmap.push_back((int)overflow_block.triangle_ids.size());
    
    for(int b = 0; b < blocks.size(); b++){
        
        gpu_block_positions.push_back(blocks[b].position);
        for(int i = 0; i < blocks[b].triangle_ids.size(); i++){
            gpu_sorted_vertex_a.push_back(triangles[blocks[b].triangle_ids[i]].a->position);
            gpu_sorted_vertex_b.push_back(triangles[blocks[b].triangle_ids[i]].b->position);
            gpu_sorted_vertex_c.push_back(triangles[blocks[b].triangle_ids[i]].c->position);
            sorted_triangles.push_back(triangles[blocks[b].triangle_ids[i]]);
        }
        gpu_blockmap.push_back(gpu_blockmap.back() + (int)blocks[b].triangle_ids.size());
        
    }
    
    [rtxt prepareData: &gpu_block_positions[0]
                     : &gpu_blockmap[0]
                     : &block_n
                     : &block_scale
                     : &gpu_sorted_vertex_a[0]
                     : &gpu_sorted_vertex_b[0]
                     : &gpu_sorted_vertex_c[0]
                     : gpu_sorted_vertex_a.size()];
    
}
