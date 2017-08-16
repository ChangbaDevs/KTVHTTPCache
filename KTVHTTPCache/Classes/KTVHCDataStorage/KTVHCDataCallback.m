//
//  KTVHCDataCallback.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataCallback.h"

@implementation KTVHCDataCallback

+ (void)workingCallbackWithBlock:(void (^)())block
{
    static dispatch_queue_t workingQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        workingQueue = dispatch_queue_create("KTVHCDataCallback_workingQueue", DISPATCH_QUEUE_SERIAL);
    });
    
    [self callbackWithQueue:workingQueue block:block aync:YES];
}

+ (void)commonCallbackWithBlock:(void (^)())block
{
    static dispatch_queue_t commonQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        commonQueue = dispatch_queue_create("KTVHCDataCallback_commonQueue", DISPATCH_QUEUE_SERIAL);
    });
    
    [self callbackWithQueue:commonQueue block:block aync:YES];
}

+ (void)callbackWithQueue:(dispatch_queue_t)queue block:(void (^)())block
{
    [self callbackWithQueue:queue block:block aync:YES];
}

+ (void)callbackWithQueue:(dispatch_queue_t)queue block:(void (^)())block aync:(BOOL)async
{
    if (!block) {
        return;
    }
    
    if (async) {
        dispatch_async(queue, ^{
            if (block) {
                block();
            }
        });
    } else {
        dispatch_sync(queue, ^{
            if (block) {
                block();
            }
        });
    }
}

@end
