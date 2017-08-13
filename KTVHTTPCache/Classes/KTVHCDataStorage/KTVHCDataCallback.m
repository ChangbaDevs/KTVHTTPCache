//
//  KTVHCDataCallback.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataCallback.h"

@implementation KTVHCDataCallback

+ (void)callbackWithBlock:(void (^)())block
{
    if (!block) {
        return;
    }
    
    static NSLock * lock = nil;
    static dispatch_queue_t queue = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [[NSLock alloc] init];
        queue = dispatch_queue_create("KTVHCDataCallbackQueue", DISPATCH_QUEUE_SERIAL);
    });
    
    [lock lock];
    dispatch_async(queue, ^{
        if (block) {
            block();
        }
    });
    [lock unlock];
}

@end
