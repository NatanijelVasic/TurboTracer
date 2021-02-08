//
//  loader.h
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <iostream>
#import <vector>

#import "scene.h"
#import "triangle.h"

using namespace std;

class Loader{
    
public:
    
    void load_obj(string filepath, Scene &scene);
    
};
