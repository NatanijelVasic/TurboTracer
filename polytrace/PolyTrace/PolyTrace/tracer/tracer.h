//
//  tracer.h
//  PolyTrace
//
//  Created by Natanijel Vasic on 27/01/2021.
//

#import <MetalKit/MetalKit.h>

#import "camera.h"
#import "framebuffer.h"
#import "metal.h"
#import <mutex>
#import "path.h"
#import "pathbuffer.h"
#import "ray.h"
#import "raybuffer.h"
#import "scene.h"

class Tracer{
    
    Camera* _camera;
    Scene* _scene;
    
    Pathbuffer _pathbuffer;
    Raybuffer _raybuffer;
    
    vector<simd_float3> _gpu_raybuffer_position;
    vector<simd_float3> _gpu_raybuffer_direction;
    
    MetalRaytrace* _rtxt;
    mutex gpu_mutex;

public:

    Tracer(Camera* camera, Scene* scene, MetalRaytrace* rtxt);
//    ~Tracer();
    void reset();
    void gpu_raycast(int cpu_thread_id, int bounce);
    void write_to_framebuffer(Framebuffer &framebuffer);
        
};
