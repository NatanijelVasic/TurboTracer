//
//  vertex.m
//  PolyTrace
//
//  Created by Natanijel Vasic on 29/01/2021.
//

#import <MetalKit/MetalKit.h>

#import <iostream>
#import <vector>

#import "vertex.h"

Vertex::Vertex(){
    
    position = simd_make_float3(-1.0f, -1.0f, -1.0f);
    
}

Vertex::Vertex(simd_float3 init_position){
    
    position = init_position;
    
}

void Vertex::scale(float scale){
    
    position *= scale;
    
}

void Vertex::rotate(float angle){
    
    simd_float3 position_old = simd_make_float3(position);
    position[0] = cos(angle) * position_old[0] - sin(angle) * position_old[2];
    position[2] = sin(angle) * position_old[0] + cos(angle) * position_old[2];
    
}

void Vertex::offset(simd_float3 offset){
    
    position += offset;
    
}

void Vertex::add_normal(simd_float3 normal){
    
    normals.push_back(normal);
    
}

void Vertex::calculate_vertex_normal(){ // and apply to triangles
    
    for(int i = 0; i < normals.size(); i++){
        n += normals[i];
    }
    n = simd_normalize(n);
    
}
