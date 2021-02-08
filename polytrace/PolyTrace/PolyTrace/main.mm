//
//  MetalRaytrace.m
//  PolyTrace
//
//  Created by Natanijel Vasic on 13/01/2021.
//

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

#import <chrono>
#import <fstream>
#import <iostream>
#import <map>
#import <mutex>
#import <random>
#import <thread>
#import <vector>

#import "camera.h"
#import "config.h"
#import "framebuffer.h"
#import "loader.h"
#import "metal.h"
#import "pathbuffer.h"
#import "scene.h"
#import "tracer.h"
#import "triangle.h"

using namespace std;

Camera camera(simd_make_float3(0.0f, 1.2f, 0.0f),
              simd_make_float3(0.0f, 0.0f, 1.0f),
              simd_make_float3(0.0f, 1.0f, 0.0f),
              1.5f);

Framebuffer framebuffer(WIDTH, HEIGHT);
Loader loader;
Scene scene;

id<MTLDevice> device = MTLCreateSystemDefaultDevice();
MetalRaytrace* rtxt = [[MetalRaytrace alloc] initWithDevice:device];

Tracer tracer(&camera, &scene, rtxt);


int main(int argc, const char * argv[]) {
    
    @autoreleasepool {
        
        cout << "START" << endl;
        loader.load_obj("/Users/natanijelvasic/Desktop/TurboTracer/models/dragon/", scene);
        scene.load_dome("/Users/natanijelvasic/Desktop/TurboTracer/pano/pano");
        scene.blockify(BLOCKS);
        scene.gpu_load_scene(rtxt);
        cout << "Scene Loaded to GPU" << endl;
        
        for(int s = 0; s < SUPERITERATIONS; s++){

            cout << string(33, '*') << " Superiteration: " << s << " " << string(33, '*') << endl << endl;
            auto s1 = chrono::high_resolution_clock::now();
            
            for(int b = 0; b < MAXBOUNCE; b++){
                cout << "Bounce: " << b << "\t|\t";
                tracer.gpu_raycast(0, b);
            }
            
            tracer.write_to_framebuffer(framebuffer);
            tracer.reset();
            
            auto s2 = chrono::high_resolution_clock::now();
            auto s_duration = chrono::duration_cast<std::chrono::nanoseconds>( s2 - s1 ).count();
            cout << endl << "Superiteration Time (s): " << s_duration/1000000000.0f << endl << endl;
            
            if(s % 10 == 0){
                framebuffer.save("/Users/natanijelvasic/Desktop/TurboTracer/frames/output.txt", s);
            }
        }
    }
    
    return 0;
    
}
