//
//  KTVHCDataCallback.h
//  KTVHTTPCache
//
//  Created by Single on 2017/8/12.
//  Copyright © 2017年 Single. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KTVHCDataCallback : NSObject


+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (void)workingCallbackWithBlock:(void (^)(void))block;

+ (void)callbackWithQueue:(dispatch_queue_t)queue block:(void (^)(void))block;      // default is async.
+ (void)callbackWithQueue:(dispatch_queue_t)queue block:(void (^)(void))block async:(BOOL)async;


@end
