//
//  loader.m
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <fstream>
#import <iostream>
#import <vector>

#import "config.h"
#import "loader.h"
#import "triangle.h"

using namespace std;
    
void Loader::load_obj(string filepath, Scene &scene){
    
    scene.vertices.push_back(Vertex(simd_make_float3(-100, 0, -100)));
    scene.vertices.push_back(Vertex(simd_make_float3(0, 0, 1000)));
    scene.vertices.push_back(Vertex(simd_make_float3(100, 0, -100))); // floor
    
//    scene.vertices.push_back(Vertex(simd_make_float3(0, 2, -1)));
//    scene.vertices.push_back(Vertex(simd_make_float3(6, 2, -1)));
//    scene.vertices.push_back(Vertex(simd_make_float3(3, 5, 0))); // backlight
    
    scene.vertices.push_back(Vertex(simd_make_float3(-20, 0, 7)));
    scene.vertices.push_back(Vertex(simd_make_float3(-20, 2000, 7)));
    scene.vertices.push_back(Vertex(simd_make_float3(20, 0, 7))); // wall
    
//    scene.vertices.push_back(Vertex(simd_make_float3(-0, 2, -1)));
//    scene.vertices.push_back(Vertex(simd_make_float3(-3, 5, 0))); // backlight
//    scene.vertices.push_back(Vertex(simd_make_float3(-6, 2, -1)));
        
    const int VERTS = 125066; // HARD
    const int TRIS = 249999; // HARD

    float vertex[VERTS][3];
    int face[TRIS][3];

    ifstream vertex_file { filepath + "vertex.txt" };
    for (int i = 0; i < VERTS; i++) {
        for (int j = 0; j < 3; j++) {
            vertex_file >> vertex[i][j];
        }
    }
    
    ifstream face_file { filepath + "face.txt" };
    for (int i = 0; i < TRIS; i++) {
        for (int j = 0; j < 3; j++) {
            face_file >> face[i][j];
        }
    }
    
    for (int i = 0; i < VERTS; i++){
        
        Vertex v(simd_make_float3(vertex[i][0],
                                  vertex[i][1],
                                  vertex[i][2]));
        v.scale(MODEL_SCALE);
        v.rotate(MODEL_ROTATION);
        v.offset(simd_make_float3(MODEL_OFFSET_X,
                                  MODEL_OFFSET_Y,
                                  MODEL_OFFSET_Z));
        
        scene.vertices.push_back(v);
        
    }
    
    scene.triangles.push_back(Triangle(&scene.vertices[0],
                                       &scene.vertices[1],
                                       &scene.vertices[2],
                                       's', true, false)); // floor
    
//    scene.triangles.push_back(Triangle(&scene.vertices[3],
//                                       &scene.vertices[4],
//                                       &scene.vertices[5],
//                                       'l', true, false)); // light
    
    scene.triangles.push_back(Triangle(&scene.vertices[3],
                                       &scene.vertices[4],
                                       &scene.vertices[5],
                                       'w', true, false)); // wall
    
//    scene.triangles.push_back(Triangle(&scene.vertices[6],
//                                       &scene.vertices[7],
//                                       &scene.vertices[8],
//                                       'y', true, false)); // light left
    
    for (int i = 0; i < TRIS; i++){
        
        const int offset = 6;
        
        scene.triangles.push_back(Triangle(&scene.vertices[face[i][0] - 1 + offset], // hard 6
                                           &scene.vertices[face[i][1] - 1 + offset], // hard 6
                                           &scene.vertices[face[i][2] - 1 + offset], // hard 6
                                           'm', false, true));
        
        scene.vertices[face[i][0] - 1 + offset].add_normal(scene.triangles.back().n); // hard 6
        scene.vertices[face[i][1] - 1 + offset].add_normal(scene.triangles.back().n); // hard 6
        scene.vertices[face[i][2] - 1 + offset].add_normal(scene.triangles.back().n); // hard 6
        
    }
    
    for (int i = 0; i < scene.vertices.size(); i++){
        
        scene.vertices[i].calculate_vertex_normal();
        
    }
    
}
