//
//  path.m
//  PolyTrace
//
//  Created by Natanijel Vasic on 27/01/2021.
//

#import <iostream>
#import <vector>

#import "color.h"
#import "path.h"
#import "ray.h"

using namespace std;


Path::Path(){
    
    color = Color(1.0f, 1.0f, 1.0f);
    terminated = false;
    
}

void Path::add(Ray ray){
    
    if(terminated == false){
        rays.push_back(ray);
    } else {
        cout << "Error: Rays cannot be added to a terminated path." << endl;
    }
    
}

Ray& Path::get_active_ray(){
    
    return rays.back();
    
}

void Path::terminate(){
    
    terminated = true;
    
}

void Path::reset(){
    
    rays.clear();
    color = Color(1.0f, 1.0f, 1.0f);
    terminated = false;
    
}
