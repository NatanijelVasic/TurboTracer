//
//  rtxt.metal
//  PolyTrace
//
//  Created by Natanijel Vasic on 13/01/2021.
//

#include <metal_stdlib>

using namespace metal;


float3 normal(float3 o,
              float3 a,
              float3 b){
    
    float3 oa = a - o;
    float3 ob = b - o;
    return normalize(cross(oa, ob));
    
}

// Ray-triangle intersection length.
float rtxl(float3 ray_origin,
           float3 ray_direction,
           float3 a,
           float3 b,
           float3 c){
    
    float3 n = normal(a, b, c);
    float p = dot(n, a - ray_origin) / dot(n, ray_direction);
    return p;
    
}

float volume_tetrahedron(float3 o,
                         float3 a,
                         float3 b,
                         float3 c){
    
    float3 oa = a - o;
    float3 ob = b - o;
    float3 oc = c - o;
    return dot(oa, cross(ob, oc));
    
}

// Ray-triangle intersection bool.
bool rtxb(float3 ray_origin,
          float3 ray_direction,
          float3 tri_a,
          float3 tri_b,
          float3 tri_c){
    
    float3 o = ray_origin + ray_direction;
    
    if(volume_tetrahedron(o, tri_a, tri_b, ray_origin) > 0.0f &&
       volume_tetrahedron(o, tri_b, tri_c, ray_origin) > 0.0f &&
       volume_tetrahedron(o, tri_c, tri_a, ray_origin) > 0.0f){
        return true;
    }
    
    // Only required for glass.
    else if(volume_tetrahedron(o, tri_a, tri_b, ray_origin) < 0.0f &&
            volume_tetrahedron(o, tri_b, tri_c, ray_origin) < 0.0f &&
            volume_tetrahedron(o, tri_c, tri_a, ray_origin) < 0.0f){
        return true;
    }
    
    else {
        return false;
    }
}

// Ray-quad intersection bool
bool rqxb(float3 ray_origin,
          float3 ray_direction,
          float3 tri_a,
          float3 tri_b,
          float3 tri_c,
          float3 tri_d){
    
    float3 o = ray_origin + ray_direction;
    
    if(volume_tetrahedron(o, tri_a, tri_b, ray_origin) > 0.0f &&
       volume_tetrahedron(o, tri_b, tri_c, ray_origin) > 0.0f &&
       volume_tetrahedron(o, tri_c, tri_d, ray_origin) > 0.0f &&
       volume_tetrahedron(o, tri_d, tri_a, ray_origin) > 0.0f){
        return true;
    }
    else {
        return false;
    }
}

// Ray-block intersection length.
float rbxl(float3 ray_origin,
                float3 ray_direction,
                float3 pos,
                float d){
    
    float3 _a = pos + float3(0, 0, 0);
    float3 _b = pos + float3(0, 0, d);
    float3 _c = pos + float3(0, d, 0);
    float3 _d = pos + float3(0, d, d);
    float3 _e = pos + float3(d, 0, 0);
    float3 _f = pos + float3(d, 0, d);
    float3 _g = pos + float3(d, d, 0);
    float3 _h = pos + float3(d, d, d);
    
    if(rqxb(ray_origin, ray_direction, _a, _c, _g, _e)){
        return rtxl(ray_origin, ray_direction, _a, _c, _g);
    }
    else if(rqxb(ray_origin, ray_direction, _e, _g, _h, _f)){
        return rtxl(ray_origin, ray_direction, _e, _g, _h);
    }
    else if(rqxb(ray_origin, ray_direction, _f, _h, _d, _b)){
        return rtxl(ray_origin, ray_direction, _f, _h, _d);
    }
    else if(rqxb(ray_origin, ray_direction, _b, _d, _c, _a)){
        return rtxl(ray_origin, ray_direction, _b, _d, _c);
    }
    else if(rqxb(ray_origin, ray_direction, _c, _d, _h, _g)){
        return rtxl(ray_origin, ray_direction, _c, _d, _h);
    }
    else if(rqxb(ray_origin, ray_direction, _a, _e, _f, _b)){
        return rtxl(ray_origin, ray_direction, _a, _e, _f);
    }
    
    return -1.0; // no intersction code
    
}

kernel void rtxt(device const float3* block_position,
                 device const int* block_tri_index,
                 device const int* block_n,
                 device const float* block_scale,
                 device const float3* tri_a,
                 device const float3* tri_b,
                 device const float3* tri_c,
                 device const float3* ray_origin,
                 device const float3* ray_direction,
                 device int* result,
                 uint j [[thread_position_in_grid]])
{
    
    const int MAX_RAY_BLOCKS = 64; // HARD
    const float MIN_RAY_LENGTH = 1.0e-6f; // HARD: Investigate floating point accuracy to prevent re-intersections
    
    float l_min_tri = 1.0e9;
    int tri_select = -1;
    
    int blox[64];
    float blox_dist[64];
    int blox_counter = 0;
    int blox_done[64];
    int blox_sorted[64];
    
    for(int i = 0; i < MAX_RAY_BLOCKS; i++){
        blox[i] = -1;
        blox_dist[i] = -1;
        blox_done[i] = 0;
        blox_sorted[i] = -1;
    }
    
    result[j] = -1;
    
    // First check the special tris.
    
    for(int i = block_tri_index[0];
            i < block_tri_index[1];
            i++){
        
        if(rtxb(ray_origin[j],
                ray_direction[j],
                tri_a[i],
                tri_b[i],
                tri_c[i])){
            
            float l = rtxl(ray_origin[j],
                           ray_direction[j],
                           tri_a[i],
                           tri_b[i],
                           tri_c[i]);
            
            if(l > MIN_RAY_LENGTH &&
               l < l_min_tri){
                    
                tri_select = i;
                l_min_tri = l;
                    
            }
        }
    }
    
    // Check local block.
    
    int local_block_index = -1;
    float3 local_block_pos = float3(floor((*block_scale) * ray_origin[j][0]) / (*block_scale),
                                    floor((*block_scale) * ray_origin[j][1]) / (*block_scale),
                                    floor((*block_scale) * ray_origin[j][2]) / (*block_scale));
    
    for(int i = 0; i < *block_n; i++){
        
        if(local_block_pos[0] == block_position[i][0] &&
           local_block_pos[1] == block_position[i][1] &&
           local_block_pos[2] == block_position[i][2]){
            
            local_block_index = i;
            
        }
    }
    
    if(local_block_index > -1){
        
        for(int i = block_tri_index[local_block_index];
                i < block_tri_index[local_block_index+1];
                i++){
            
            if(rtxb(ray_origin[j],
                    ray_direction[j],
                    tri_a[i],
                    tri_b[i],
                    tri_c[i])){
                
                float l = rtxl(ray_origin[j],
                               ray_direction[j],
                               tri_a[i],
                               tri_b[i],
                               tri_c[i]);
                
                if(l > MIN_RAY_LENGTH &&
                   l < l_min_tri){
                        
                    tri_select = i;
                    l_min_tri = l;
                        
                }
            }
        }
    }
    
    for(int i = 1; i < *block_n; i++){
        
        if(rbxl(ray_origin[j],
                     ray_direction[j],
                     block_position[i],
                     1.0f/(*block_scale)) > 0.0f){
            
            float l = rbxl(ray_origin[j],
                                ray_direction[j],
                                block_position[i],
                                (1.0f/(*block_scale)));
            
            blox_dist[blox_counter] = l;
            blox[blox_counter] = i;
            blox_counter++;
            
        }
    }
    
    // Sort the intersected blocks by distance.
    
    for(int i = 0; i < blox_counter; i++){
        
        float min_dist = 1.0e9f;
        int min_dist_at = -1;
        
        for(int j = 0; j < blox_counter; j++){
            
            if(blox_done[j] == 0){
                
                if(blox_dist[j] < min_dist){
                    
                    blox_sorted[i] = blox[j];
                    min_dist = blox_dist[j];
                    min_dist_at = j;
                    
                }
            }
        }
        blox_done[min_dist_at] = 1;
    }
    
    // Find tri in candidate blocks (sorted by distance).
    
    if(blox[0] == -1){
        
        result[j] = tri_select;
        
    } else {
        
        bool tri_in_block_found = false;
        for(int b = 0; b < blox_counter; b++){
            
            for(int i = block_tri_index[blox_sorted[b]];
                    i < block_tri_index[blox_sorted[b]+1];
                    i++){
                
                if(rtxb(ray_origin[j],
                        ray_direction[j],
                        tri_a[i],
                        tri_b[i],
                        tri_c[i])){
                    
                    float l = rtxl(ray_origin[j],
                                   ray_direction[j],
                                   tri_a[i],
                                   tri_b[i],
                                   tri_c[i]);
                    
                    if(l > MIN_RAY_LENGTH &&
                       l < l_min_tri){
                            
                        tri_select = i;
                        l_min_tri = l;
                        tri_in_block_found = true;
                            
                    }
                }
            }
            if(tri_in_block_found){break;}
        }
        result[j] = tri_select;
    }
    
}
