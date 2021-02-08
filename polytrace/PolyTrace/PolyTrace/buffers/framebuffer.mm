//
//  framebuffer.m
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <fstream>
#import <iostream>

#import "color.h"
#import "config.h"
#import "framebuffer.h"

using namespace std;

Framebuffer::Framebuffer(int width, int height){

    pixels = new Color[width * height];
    for (int i = 0; i < width * height; i++) {
        pixels[i].r = 0.0f;
        pixels[i].g = 0.0f;
        pixels[i].b = 0.0f;
    }
    
}

Framebuffer::~Framebuffer(){
    
    delete pixels;
    
}

void Framebuffer::save(string filepath, int s){
    
    ofstream file;
    file.open(filepath);
    
    for(int y = 0; y < HEIGHT; y++){
        for(int x = 0; x < WIDTH; x++){
            
            file << pixels[y * WIDTH + x].r/s << "\t";
            file << pixels[y * WIDTH + x].g/s << "\t";
            file << pixels[y * WIDTH + x].b/s << "\t";
            if(x < WIDTH-1){ file << "\n";}
            
        }
        file << "\n";
    }
    file.close();
    
}
