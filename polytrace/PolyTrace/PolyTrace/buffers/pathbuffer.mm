//
//  pathbuffer.m
//  PolyTrace
//
//  Created by Natanijel Vasic on 27/01/2021.
//

#import <MetalKit/MetalKit.h>

#import "config.h"
#import "path.h"
#import "pathbuffer.h"

Pathbuffer::Pathbuffer(){
    
    paths = new Path[THREADS * GPU_ITERATIONS * HEIGHT * WIDTH];
    
}

Pathbuffer::~Pathbuffer(){
    
    delete[] paths;
    
}
