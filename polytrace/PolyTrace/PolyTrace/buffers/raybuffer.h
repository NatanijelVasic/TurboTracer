//
//  raybuffer.h
//  PolyTrace
//
//  Created by Natanijel Vasic on 26/01/2021.
//

#import <vector>

#import "ray.h"

using namespace std;

class Raybuffer{
    
public:
    
    vector<Ray> rays;
    void add(Ray ray);
    int size();
    void clear();
    
};
