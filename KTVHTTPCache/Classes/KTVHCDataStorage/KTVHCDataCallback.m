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
    
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("KTVHCDataCallbackQueue", DISPATCH_QUEUE_SERIAL);
    });
    dispatch_async(queue, ^{
        block();
    });
}

@end
