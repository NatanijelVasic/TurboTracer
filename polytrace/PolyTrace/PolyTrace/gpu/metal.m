//
//  MetalRaytrace.m
//  PolyTrace
//
//  Created by Natanijel Vasic on 13/01/2021.
//

#import <mach/mach_time.h>
#import <MetalKit/MetalKit.h>

#import "config.h"
#import "metal.h"

@implementation MetalRaytrace
{
    id<MTLDevice> _mDevice;
    id<MTLComputePipelineState> _mRTXTFunctionPSO;
    id<MTLCommandQueue> _mCommandQueue;

    // Buffers.
    id<MTLBuffer> _mBlockPosition;
    id<MTLBuffer> _mBlockTriIndex;
    id<MTLBuffer> _mBlockPosition_private;
    id<MTLBuffer> _mBlockTriIndex_private;
    
    id<MTLBuffer> _mBlockN;
    id<MTLBuffer> _mBlockScale;
    
    id<MTLBuffer> _mTriA;
    id<MTLBuffer> _mTriB;
    id<MTLBuffer> _mTriC;
    id<MTLBuffer> _mTriA_private;
    id<MTLBuffer> _mTriB_private;
    id<MTLBuffer> _mTriC_private;
    
    id<MTLBuffer> _rOrigin;
    id<MTLBuffer> _rDirection;
    id<MTLBuffer> _rOrigin_private;
    id<MTLBuffer> _rDirection_private;
    
    id<MTLBuffer> _mBufferResult;
    id<MTLBuffer> _mBufferResult_private;

}

- (instancetype) initWithDevice: (id<MTLDevice>) device
{
    self = [super init];
    if (self)
    {
        _mDevice = device;
        NSError* error = nil;
        id<MTLLibrary> defaultLibrary = [_mDevice newDefaultLibrary];
        id<MTLFunction> RTXTFunction = [defaultLibrary newFunctionWithName:@"rtxt"];
        _mRTXTFunctionPSO = [_mDevice newComputePipelineStateWithFunction: RTXTFunction error:&error];
        _mCommandQueue = [_mDevice newCommandQueue];
    }
    return self;
}

- (void) copyToVRAM: (id<MTLBuffer>) source
                   : (id<MTLBuffer>) destination
                   : (unsigned long) size
{
    
    id <MTLCommandBuffer> commandBuffer = [_mCommandQueue commandBuffer];
    id <MTLBlitCommandEncoder> blitCommandEncoder = [commandBuffer blitCommandEncoder];
    [blitCommandEncoder copyFromBuffer:source
                          sourceOffset:0
                              toBuffer:destination
                     destinationOffset:0
                                  size:size];
    [blitCommandEncoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
}

- (void) prepareData: (simd_float3*) blockPosition
                    : (int*) blockTriIndex
                    : (int*) blockN
                    : (float*) blockScale
                    : (simd_float3*) triA
                    : (simd_float3*) triB
                    : (simd_float3*) triC
                    : (unsigned long) triN;
{
    
    int l = WIDTH*HEIGHT*GPU_ITERATIONS; // HARD
    
    _mBlockPosition = [_mDevice newBufferWithBytes:blockPosition length:*blockN * sizeof(simd_float3) options:MTLResourceStorageModeShared];
    _mBlockTriIndex = [_mDevice newBufferWithBytes:blockTriIndex length:(*blockN + 1) * sizeof(int) options:MTLResourceStorageModeShared];
    _mBlockPosition_private = [_mDevice newBufferWithLength:*blockN * sizeof(simd_float3) options:MTLResourceStorageModePrivate];
    _mBlockTriIndex_private = [_mDevice newBufferWithLength:(*blockN + 1) * sizeof(int) options:MTLResourceStorageModePrivate];
    
    _mBlockN = [_mDevice newBufferWithBytes:blockN length:sizeof(int) options:MTLResourceStorageModeShared];
    _mBlockScale = [_mDevice newBufferWithBytes:blockScale length:sizeof(float) options:MTLResourceStorageModeShared];
    
    _mTriA = [_mDevice newBufferWithBytes:triA length:triN*sizeof(simd_float3) options:MTLResourceStorageModeShared];
    _mTriB = [_mDevice newBufferWithBytes:triB length:triN*sizeof(simd_float3) options:MTLResourceStorageModeShared];
    _mTriC = [_mDevice newBufferWithBytes:triC length:triN*sizeof(simd_float3) options:MTLResourceStorageModeShared];
    
    _mTriA_private = [_mDevice newBufferWithLength:triN*sizeof(simd_float3) options:MTLResourceStorageModePrivate];
    _mTriB_private = [_mDevice newBufferWithLength:triN*sizeof(simd_float3) options:MTLResourceStorageModePrivate];
    _mTriC_private = [_mDevice newBufferWithLength:triN*sizeof(simd_float3) options:MTLResourceStorageModePrivate];
    
    _rOrigin = [_mDevice newBufferWithLength:l*sizeof(simd_float3) options:MTLResourceStorageModeShared];
    _rDirection = [_mDevice newBufferWithLength:l*sizeof(simd_float3) options:MTLResourceStorageModeShared];
    _rOrigin_private = [_mDevice newBufferWithLength:l*sizeof(simd_float3) options:MTLResourceStorageModePrivate];
    _rDirection_private = [_mDevice newBufferWithLength:l*sizeof(simd_float3) options:MTLResourceStorageModePrivate];
    
    _mBufferResult = [_mDevice newBufferWithLength:l*sizeof(int) options:MTLResourceStorageModeShared];
    _mBufferResult_private = [_mDevice newBufferWithLength:l*sizeof(int) options:MTLResourceStorageModePrivate];
    
    [self copyToVRAM: _mTriA : _mTriA_private : triN * sizeof(simd_float3)];
    [self copyToVRAM: _mTriB : _mTriB_private : triN * sizeof(simd_float3)];
    [self copyToVRAM: _mTriC : _mTriC_private : triN * sizeof(simd_float3)];
    [self copyToVRAM: _mBlockPosition : _mBlockPosition_private : *blockN * sizeof(simd_float3)];
    [self copyToVRAM: _mBlockTriIndex : _mBlockTriIndex_private : (*blockN + 1) * sizeof(int)];
        
}

- (int*) sendComputeCommand: (simd_float3*) position_ray
                           : (simd_float3*) direction_ray
                           : (unsigned long) N
{
    @autoreleasepool {
        
        id <MTLCommandBuffer> commandBuffer = [_mCommandQueue commandBuffer];
        assert(commandBuffer != nil);
        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
        assert(computeEncoder != nil);

        [self encodeRTXTCommand: computeEncoder : position_ray : direction_ray : N];
        [computeEncoder endEncoding];
        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
        
        return _mBufferResult.contents;
        
    }
}

- (void)encodeRTXTCommand:(id<MTLComputeCommandEncoder>)computeEncoder
                         : (simd_float3*) position_ray
                         : (simd_float3*) direction_ray
                         : (unsigned long) N
{
    
    simd_float3* _rOriginPointer = _rOrigin.contents;
    simd_float3* _rDirectionPointer = _rDirection.contents;
    int* _mBufferResultPointer = _mBufferResult.contents;
    for (int index = 0; index < N; index++)
    {
        _rOriginPointer[index] = position_ray[index];
        _rDirectionPointer[index] = direction_ray[index];
        _mBufferResultPointer[index] = 505;
    }

    [computeEncoder setComputePipelineState:_mRTXTFunctionPSO];
    [computeEncoder setBuffer: _mBlockPosition_private offset:0 atIndex:0];
    [computeEncoder setBuffer:_mBlockTriIndex_private offset:0 atIndex:1];
    [computeEncoder setBuffer:_mBlockN offset:0 atIndex:2];
    [computeEncoder setBuffer:_mBlockScale offset:0 atIndex:3];
    [computeEncoder setBuffer:_mTriA_private offset:0 atIndex:4];
    [computeEncoder setBuffer:_mTriB_private offset:0 atIndex:5];
    [computeEncoder setBuffer:_mTriC_private offset:0 atIndex:6];
    [computeEncoder setBuffer:_rOrigin offset:0 atIndex:7];
    [computeEncoder setBuffer:_rDirection offset:0 atIndex:8];
    [computeEncoder setBuffer:_mBufferResult offset:0 atIndex:9];

    MTLSize gridSize = MTLSizeMake(N, 1, 1);
    NSUInteger threadGroupSize = _mRTXTFunctionPSO.maxTotalThreadsPerThreadgroup;
    MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);

    [computeEncoder dispatchThreads:gridSize
              threadsPerThreadgroup:threadgroupSize];
}

@end

