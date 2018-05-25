//
//  KTVHCLog.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/17.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCLog.h"
#import "KTVHCPathTools.h"

#import <UIKit/UIKit.h>

@interface KTVHCLog ()

@property (nonatomic, strong) NSLock * lock;
@property (nonatomic, strong) NSFileHandle * writingHandle;
@property (nonatomic, strong) NSMutableArray <NSError *> * internalErrors;
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
        self.consoleLogEnable = NO;
        self.recordLogEnable = NO;
        self.lock = [[NSLock alloc] init];
        self.internalErrors = [NSMutableArray array];
        [self deleteRecordLog];
    }
    return self;
}

- (void)addRecordLog:(NSString *)log
{
    if (!self.consoleLogEnable)
    {
        return;
    }
    if (!self.recordLogEnable)
    {
        return;
    }
    if (log.length <= 0) {
        return;
    }
    if (!self.createLogAndFileHandleToken)
    {
        [self createLogAndFileHandle];
        self.createLogAndFileHandleToken = YES;
    }
    if (!self.writingHandle)
    {
        return;
    }
    [self.lock lock];
    log = [NSString stringWithFormat:@"%@  %@\n", [NSDate date], log];
    NSData * data = [log dataUsingEncoding:NSUTF8StringEncoding];
    [self.writingHandle writeData:data];
    [self.lock unlock];
}

- (void)deleteRecordLog
{
    [self.lock lock];
    [KTVHCPathTools deleteFileAtPath:[KTVHCPathTools logPath]];
    [self.lock unlock];
}

- (void)createLogAndFileHandle
{
    [self.lock lock];
    [KTVHCPathTools createFileAtPath:[KTVHCPathTools logPath]];
    self.writingHandle = [NSFileHandle fileHandleForWritingAtPath:[KTVHCPathTools logPath]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [self.lock unlock];
}

- (NSString *)recordLogFilePath
{
    NSString * path = nil;
    [self.lock lock];
    long long logFileSize = [KTVHCPathTools sizeOfItemAtPath:[KTVHCPathTools logPath]];
    if (logFileSize > 0)
    {
        path = [KTVHCPathTools logPath];
    }
    [self.lock unlock];
    return path;
}

- (NSError *)lastError
{
    if (self.internalErrors.count > 0)
    {
        return self.internalErrors.lastObject;
    }
    return nil;
}

- (NSArray<NSError *> *)allErrors
{
    if (self.internalErrors.count > 0)
    {
        return [self.internalErrors copy];
    }
    return nil;
}

- (void)addError:(NSError *)error
{
    if (error && [error isKindOfClass:[NSError class]])
    {
        [self.internalErrors addObject:error];
    }
}

#pragma mark - UIApplicationWillTerminateNotification

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self.lock lock];
    [self.writingHandle closeFile];
    self.writingHandle = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    [self.lock unlock];
}

@end
