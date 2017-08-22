//
//  KTVHCLog.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/17.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCLog.h"
#import <UIKit/UIKit.h>
#import "KTVHCPathTools.h"


@interface KTVHCLog ()

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) NSFileHandle * writingHandle;
@property (nonatomic, assign) BOOL createLogAndFileHandleToken;

@end


@implementation KTVHCLog


+ (instancetype)log
{
    static KTVHCLog * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.logEnable = NO;
        self.lock = [[NSLock alloc] init];
        [self deleteLog];
    }
    return self;
}

- (void)recordLog:(NSString *)log
{
    if (!self.logEnable) {
        return;
    }
    if (log.length <= 0) {
        return;
    }
    if (!self.createLogAndFileHandleToken)
    {
        [self createLogAndFileHandleToken];
        self.createLogAndFileHandleToken = YES;
    }
    if (!self.writingHandle) {
        return;
    }
    
    [self.lock lock];
    
    log = [NSString stringWithFormat:@"%@  %@\n", [NSDate date], log];
    NSData * data = [log dataUsingEncoding:NSUTF8StringEncoding];
    [self.writingHandle writeData:data];
    
    [self.lock unlock];
}

- (void)deleteLog
{
    [self.lock lock];
    
    [KTVHCPathTools deleteFileAtPath:[KTVHCPathTools pathForLog]];

    [self.lock unlock];
}

- (void)createLogAndFileHandle
{
    [self.lock lock];
    
    [[NSFileManager defaultManager] createFileAtPath:self.logFilePath contents:nil attributes:nil];
    self.writingHandle = [NSFileHandle fileHandleForWritingAtPath:[KTVHCPathTools pathForLog]];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    [self.lock unlock];
}

- (NSString *)logFilePath
{
    return [KTVHCPathTools pathForLog];
}


#pragma mark - UIApplicationWillTerminateNotification

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self.lock lock];
    
    [self.writingHandle closeFile];
    self.writingHandle = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillTerminateNotification
                                                  object:nil];
    
    [self.lock unlock];
}


@end
