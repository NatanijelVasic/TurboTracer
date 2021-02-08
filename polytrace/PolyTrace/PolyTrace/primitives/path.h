//
//  path.h
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <MetalKit/MetalKit.h>

#import <vector>

#import "color.h"
#import "ray.h"

using namespace std;

class Path{

public:
    
    vector<Ray> rays;
    Color color;
    bool terminated;

    Path();
    void add(Ray ray);
    Ray& get_active_ray();
    void terminate();
    void reset();
        
};

