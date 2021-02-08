//
//  raybuffer.m
//  PolyTrace
//
//  Created by Natanijel Vasic on 27/01/2021.
//

#import <vector>

#import "ray.h"
#import "raybuffer.h"

void Raybuffer::add(Ray ray){
    
    rays.push_back(ray);
    
}

int Raybuffer::size(){
    
    return (int)rays.size();
    
}

void Raybuffer::clear(){
    
    rays.clear();
    
}
