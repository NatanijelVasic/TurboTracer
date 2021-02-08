//
//  tracer.m
//  PolyTrace
//
//  Created by Natanijel Vasic on 27/01/2021.
//

#import <MetalKit/MetalKit.h>

#import "camera.h"
#import "config.h"
#import <iomanip>
#import "metal.h"
#import <mutex>
#import "path.h"
#import "pathbuffer.h"
#import "ray.h"
#import "raybuffer.h"
#import "tracer.h"
#import "triangle.h"


float rndm(){
    return (float) rand() / RAND_MAX;
}


simd_float3 orth(simd_float3 a){
    
    simd_float3 random_vector = simd_make_float3(1, 1, 1);
    simd_float3 orth = random_vector - simd_dot(a, random_vector) * a;
    return simd_fast_normalize(orth);
    
}


simd_float3 rtx(simd_float3 ray_origin,
                simd_float3 ray_direction,
                Triangle t){
    
    float p = simd_dot(t.n, t.a->position - ray_origin) / simd_dot(t.n, ray_direction);
    return ray_origin + (p * ray_direction);
    
}


Tracer::Tracer(Camera* camera,
               Scene* scene,
               MetalRaytrace* rtxt){
    
    _rtxt = rtxt;
    _camera = camera;
    _scene = scene;
    
    reset();
    
}

void Tracer::gpu_raycast(int cpu_thread_id, int bounce){
    
    _raybuffer.clear();
    
    auto t1 = chrono::high_resolution_clock::now();
    
    for(int g = 0; g < GPU_ITERATIONS; g++){
        for(int y = 0; y < HEIGHT; y++){
            for(int x = 0; x < WIDTH; x++){
                
                int i = cpu_thread_id * (GPU_ITERATIONS*HEIGHT*WIDTH) +
                        g * (HEIGHT*WIDTH) +
                        y * (WIDTH)
                        + x;
                
                Path* path = &_pathbuffer.paths[i];
                
                if(path->terminated == false){
                    _raybuffer.add(path->get_active_ray());
                }
                
            }
        }
    }
    
    auto t2 = chrono::high_resolution_clock::now();
    auto duration = chrono::duration_cast<std::chrono::nanoseconds>(t2 - t1).count();
    cout << std::left << std::setw(12) << duration/1000000000.0f << "\t|\t";
                    
    if(_raybuffer.size() > 0){
        
        gpu_mutex.lock();
        
        t1 = chrono::high_resolution_clock::now();
        
        for(int i = 0; i < _raybuffer.size(); i++){
            _gpu_raybuffer_position.push_back(_raybuffer.rays[i].position);
            _gpu_raybuffer_direction.push_back(_raybuffer.rays[i].direction);
        }

        int* result = [_rtxt sendComputeCommand: &_gpu_raybuffer_position[0]
                                               : &_gpu_raybuffer_direction[0]
                                               : _raybuffer.size()];
        
        _gpu_raybuffer_position.clear();
        _gpu_raybuffer_direction.clear();
        
        t2 = chrono::high_resolution_clock::now();
        duration = chrono::duration_cast<std::chrono::nanoseconds>(t2 - t1).count();
        cout << std::setw(12) << duration/1000000000.0f << "\t|\t";
        
        gpu_mutex.unlock();
        
        int result_counter = 0;
        
        auto t1 = chrono::high_resolution_clock::now();
                    
        for(int g = 0; g < GPU_ITERATIONS; g++){
            for(int y = 0; y < HEIGHT; y++){
                for(int x = 0; x < WIDTH; x++){
                    
                    int i = cpu_thread_id * (GPU_ITERATIONS*HEIGHT*WIDTH) +
                            g * (HEIGHT*WIDTH) +
                            y * (WIDTH)
                            + x;
                    
                    Path* path = &_pathbuffer.paths[i];
                    
                    if(path->terminated == false){
                        
                        simd_float3 ray_direction = path->get_active_ray().direction;
                        
                        if(result[result_counter] != -1){
                            
                            Triangle tri = _scene->sorted_triangles[result[result_counter]];
                            simd_float3 ray_position_new = rtx(path->get_active_ray().position,
                                                               path->get_active_ray().direction,
                                                               tri);
                            simd_float3 ray_direction_new;
                            
                            if(tri.smooth_normal){
                                
                                simd_float3 oa = tri.a->position - ray_position_new;
                                simd_float3 ob = tri.b->position - ray_position_new;
                                simd_float3 oc = tri.c->position - ray_position_new;
                                float aa = simd_length(simd_cross(ob, oc));
                                float ab = simd_length(simd_cross(oc, oa));
                                float ac = simd_length(simd_cross(oa, ob));
                                float atot = aa + ab + ac;
                                
                                tri.n = (aa * tri.a->n + ab * tri.b->n + ac * tri.c->n)/atot;
                                
                            }
                            
                            if(tri.type == 'l'){
                                
                                path->color.r *= 0.5f;
                                path->color.g *= 0.9f;
                                path->color.b *= 0.9f;
                                path->terminate();
                                
                            }
                            
                            if(tri.type == 'y'){
                                
                                path->color.r *= 0.9f;
                                path->color.g *= 0.9f;
                                path->color.b *= 0.5f;
                                path->terminate();
                                
                            }
                            
                            if(tri.type == 'o'){
                                
                                path->color.r *= 0.9f;
                                path->color.g *= 0.1f;
                                path->color.b *= 0.9f;
                                simd_float3 orth_a = orth(tri.n);
                                simd_float3 orth_b = simd_cross(tri.n, orth_a);
                                ray_direction_new = rndm() * tri.n + (rndm()-0.5f) * orth_a;
                                ray_direction_new = ray_direction_new + (rndm()-0.5f) * orth_b;
                                ray_direction_new = simd_normalize(ray_direction_new);
                                path->add(Ray(ray_position_new, ray_direction_new, false));
                                
                            }
                            
                            if(tri.type == 'r'){
                                
                                path->color.r *= 0.10f;
                                path->color.g *= 0.90f;
                                path->color.b *= 0.90f;
                                ray_direction_new = ray_direction + 2.0f*abs(simd_dot(ray_direction, tri.n)) * tri.n;
                                ray_direction_new = simd_normalize(ray_direction_new);
                                path->add(Ray(ray_position_new, ray_direction_new, false));
                                
                            }
                            
                            if(tri.type == 'm'){
                                
                                if(rndm() < 0.5){
                                    
                                    path->color.r *= 0.00f;
                                    path->color.g *= 0.95f;
                                    path->color.b *= 0.65f;
                                    simd_float3 orth_a = orth(tri.n);
                                    simd_float3 orth_b = simd_cross(tri.n, orth_a);
                                    ray_direction_new = rndm() * tri.n + (rndm()-0.5f) * orth_a;
                                    ray_direction_new = ray_direction_new + (rndm()-0.5f) * orth_b;
                                    
                                } else {
                                    
                                    path->color.r *= 0.90f;
                                    path->color.g *= 0.98f;
                                    path->color.b *= 0.90f;
                                    ray_direction_new = ray_direction + 2.0f*abs(simd_dot(ray_direction, tri.n)) * tri.n;
                                    
                                }
                                
                                ray_direction_new = simd_normalize(ray_direction_new);
                                path->add(Ray(ray_position_new, ray_direction_new, false));
                                
                            }
                            
                            if(tri.type == 's'){
                                
                                ray_direction_new = simd_make_float3(0, 0, 0);
                                
                                if((int(1000000.0f + ray_position_new[0] * 5.0f)) % 2 ==
                                   (int(1000000.0f + ray_position_new[2] * 5.0f)) % 2){
                                    
                                    path->color.r *= 0.95f;
                                    path->color.g *= 0.95f;
                                    path->color.b *= 0.90f;
                                    simd_float3 orth_a = orth(tri.n);
                                    simd_float3 orth_b = simd_cross(tri.n, orth_a);
                                    ray_direction_new = rndm() * tri.n + (rndm()-0.5f) * orth_a;
                                    ray_direction_new = ray_direction_new + (rndm()-0.5f) * orth_b;
                                    
                                } else {
                                    
                                    path->color.r *= 0.85f;
                                    path->color.g *= 0.85f;
                                    path->color.b *= 0.85f;
                                    simd_float3 orth_a = orth(tri.n);
                                    simd_float3 orth_b = simd_cross(tri.n, orth_a);
                                    ray_direction_new = rndm() * tri.n + (rndm()-0.5f) * orth_a;
                                    ray_direction_new = ray_direction_new + (rndm()-0.5f) * orth_b;
                                    
                                }
                                
                                ray_direction_new = simd_normalize(ray_direction_new);
                                path->add(Ray(ray_position_new, ray_direction_new, false));
                                
                            }
                            
                            if(tri.type == 'w'){
                                
                                ray_direction_new = simd_make_float3(0, 0, 0);
                                
                                if((int(1000000.0f + ray_position_new[0] * 2.0f)) % 2 ==
                                   (int(1000000.0f + ray_position_new[1] * 2.0f)) % 2){
                                    
                                    path->color.r *= 0.95f;
                                    path->color.g *= 0.95f;
                                    path->color.b *= 0.90f;
                                    simd_float3 orth_a = orth(tri.n);
                                    simd_float3 orth_b = simd_cross(tri.n, orth_a);
                                    ray_direction_new = rndm() * tri.n + (rndm()-0.5f) * orth_a;
                                    ray_direction_new = ray_direction_new + (rndm()-0.5f) * orth_b;
                                    
                                } else {
                                    
                                    path->color.r *= 0.85f;
                                    path->color.g *= 0.85f;
                                    path->color.b *= 0.85f;
                                    simd_float3 orth_a = orth(tri.n);
                                    simd_float3 orth_b = simd_cross(tri.n, orth_a);
                                    ray_direction_new = rndm() * tri.n + (rndm()-0.5f) * orth_a;
                                    ray_direction_new = ray_direction_new + (rndm()-0.5f) * orth_b;
                                    
                                }
                                
                                ray_direction_new = simd_normalize(ray_direction_new);
                                path->add(Ray(ray_position_new, ray_direction_new, false));
                                
                            }
                            
                            if(tri.type == 'g'){ // what about critical angle?

                                ray_direction = simd_normalize(ray_direction);
                                float adotn = simd_dot(ray_direction, tri.n);

                                if(path->get_active_ray().in_medium == false){ // entering glass
                                    
                                    float x1 = sqrt(1 - adotn * adotn);
                                    float x2 = 0.666f * x1;
                                    simd_float3 tangent = simd_normalize(ray_direction - simd_dot(ray_direction, tri.n) * tri.n);

                                    if(rndm() < 0.9){ // refract, should be angle dependant branch
                                        
                                        ray_direction_new = tangent * x2 - sqrt(1 - x2 * x2) * tri.n;
                                        path->color.r *= 0.2f; //* pow(0.5f, 1.2f*distance(position_ray[_i], ray_origin_new));
                                        path->color.g *= 0.8f; //* pow(0.5f, 1.2f*distance(position_ray[_i], ray_origin_new));
                                        path->color.b *= 0.8f; //* pow(0.5f, 1.2f*distance(position_ray[_i], ray_origin_new));
                                        ray_direction_new = simd_normalize(ray_direction_new);
                                        path->add(Ray(ray_position_new, ray_direction_new, true));
                                        
                                    } else {
                                        
                                        ray_direction_new = ray_direction + 2*abs(adotn) * tri.n;
                                        path->color.r *= (1-abs(adotn)) * 0.9f;
                                        path->color.g *= (1-abs(adotn)) * 0.9f;
                                        path->color.b *= (1-abs(adotn)) * 0.9f;
                                        ray_direction_new = simd_normalize(ray_direction_new);
                                        path->add(Ray(ray_position_new, ray_direction_new, false));
                                        
                                    }
                                    
                                }
                                
                                else { // exiting glass

                                    float x1 = 0.666f * sqrt(1 - adotn * adotn); // 0.3 HARD
                                    float x2 = x1;
                                    simd_float3 tangent = simd_normalize(ray_direction - simd_dot(ray_direction, tri.n) * tri.n);

                                    if(rndm() < 0.9){ // refract, should be angle dependant branch
                                        ray_direction_new = tangent * x2 + sqrt(1 - x2 * x2) * tri.n; // ADDRESS negative root
                                        path->color.r *= 0.2f; //* pow(0.5f, 1.2f*distance(position_ray[_i], ray_origin_new));
                                        path->color.g *= 0.8f; //* pow(0.5f, 1.2f*distance(position_ray[_i], ray_origin_new));
                                        path->color.b *= 0.8f; //* pow(0.5f, 1.2f*distance(position_ray[_i], ray_origin_new));
                                        ray_direction_new = simd_normalize(ray_direction_new);
                                        path->add(Ray(ray_position_new, ray_direction_new, false));
                                    } else {
                                        ray_direction_new = ray_direction + 2*abs(adotn) * -tri.n;
                                        path->color.r *= (1-abs(adotn)) * 0.9f;
                                        path->color.g *= (1-abs(adotn)) * 0.9f;
                                        path->color.b *= (1-abs(adotn)) * 0.9f;
                                        ray_direction_new = simd_normalize(ray_direction_new);
                                        path->add(Ray(ray_position_new, ray_direction_new, true));
                                    }
                                }

                            }
                            
                        } else { // dome lighting
                            
                            float pi = 3.14159265;
                            
                            float x = ray_direction[0];
                            float y = ray_direction[1];
                            float z = ray_direction[2];
                            
                            float phi = atan2(z, x);
                            float theta = atan2(sqrt(x * x + z * z), y);
                            
                            int ix = (phi/(2.0f*pi)) * DOMEWIDTH;
                            int iy = (theta/pi) * DOMEHEIGHT;

                            Color dome_color = _scene->dome[iy * DOMEWIDTH + (2*ix + 0) % DOMEWIDTH];
                            path->color.r *= dome_color.r;
                            path->color.g *= dome_color.g;
                            path->color.b *= dome_color.b;
                            path->terminate();
                            
                        }
                        result_counter++;
                    }
                }
            }
        }
        
        auto t2 = chrono::high_resolution_clock::now();
        duration = chrono::duration_cast<std::chrono::nanoseconds>(t2 - t1).count();
        cout << std::setw(12) << duration/1000000000.0f << "\t|\t";
        cout << _raybuffer.size() << " Rays" << endl;
    }
    
}

void Tracer::write_to_framebuffer(Framebuffer &framebuffer){
    
    for(int t = 0; t < THREADS; t++){
        for(int g = 0; g < GPU_ITERATIONS; g++){
            for(int y = 0; y < HEIGHT; y++){
                for(int x = 0; x < WIDTH; x++){
                    
                    int i = t * (GPU_ITERATIONS * HEIGHT * WIDTH) +
                            g * (HEIGHT * WIDTH) +
                            y * (WIDTH) +
                            x;
                    
                    if(_pathbuffer.paths[i].terminated){
                        framebuffer.pixels[y * WIDTH + x].r += _pathbuffer.paths[i].color.r;
                        framebuffer.pixels[y * WIDTH + x].g += _pathbuffer.paths[i].color.g;
                        framebuffer.pixels[y * WIDTH + x].b += _pathbuffer.paths[i].color.b;
                    }
                    
                }
            }
        }
    }
    
}

void Tracer::reset(){
    
    auto t1 = chrono::high_resolution_clock::now();
    
    for(int t = 0; t < THREADS; t++){
        for(int g = 0; g < GPU_ITERATIONS; g++){
            for(int y = 0; y < HEIGHT; y++){
                for(int x = 0; x < WIDTH; x++){
                    
                    int i = t * (GPU_ITERATIONS*HEIGHT*WIDTH) +
                            g * (HEIGHT*WIDTH) +
                            y * (WIDTH) +
                            x;
                    
                    _pathbuffer.paths[i].reset();
                    
                    float rand_x = rndm() - 0.5f;
                    float rand_y = rndm() - 0.5f;
                    
                    float dh = -HFOV/2.0f + HFOV*(((float)x + rand_x)/(float)WIDTH);
                    float dv = +VFOV/2.0f - VFOV*(((float)y + rand_y)/(float)HEIGHT);
                    
                    simd_float3 ray_direction = _camera->direction * _camera->zoom +
                                                dh * _camera->direction_side +
                                                dv * _camera->direction_up;
                   
                    // DOF
                    
                    simd_float3 orth_a = orth(ray_direction);
                    simd_float3 orth_b = simd_cross(ray_direction, orth_a);
                    orth_a = simd_normalize(orth_a);
                    orth_b = simd_normalize(orth_b);
                    float delta_a = (rndm() - 0.5f);
                    float delta_b = (rndm() - 0.5f);
                    simd_float3 delta = DOF * (delta_a * orth_a + delta_b * orth_b);
                    simd_float3 ray_position = _camera->position + delta;
                    ray_direction = FOCUS * ray_direction - delta;
                    
                    //
                    
                    ray_direction = simd_normalize(ray_direction);
                   
                    Ray ray = Ray(ray_position, ray_direction, false);
                    _pathbuffer.paths[i].add(ray);
                    
                }
            }
        }
    }
    
    auto t2 = chrono::high_resolution_clock::now();
    auto duration = chrono::duration_cast<std::chrono::nanoseconds>(t2 - t1).count();
    cout << "Reset (s): " << duration/1000000000.0f << endl;
    
}
