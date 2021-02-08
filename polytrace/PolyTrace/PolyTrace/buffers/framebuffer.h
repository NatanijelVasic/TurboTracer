//
//  framebuffer.h
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <iostream>

#import "color.h"

using namespace std;

class Framebuffer{
    
public:
    
    Color* pixels;
    
    Framebuffer(int width, int height);
    ~Framebuffer();
    void save(string filepath, int s);
    
};
