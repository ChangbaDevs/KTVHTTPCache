//
//  KTVHCHTTPServer.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCHTTPServer.h"
#import "KTVHCHTTPConnection.h"
#import "KTVHCHTTPHeader.h"
#import "KTVHCHTTPURL.h"
#import "KTVHCLog.h"

@interface KTVHCHTTPServer ()

@property (nonatomic, strong) HTTPServer *server;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic) BOOL wantsRunning;

@end

@implementation KTVHCHTTPServer

+ (instancetype)server
{
    static KTVHCHTTPServer *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[self alloc] init];
    });
    return obj;
}

- (instancetype)init
{
    if (self = [super init]) {
        KTVHCLogAlloc(self);
        self.backgroundTask = UIBackgroundTaskInvalid;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(HTTPConnectionDidDie)
                                                     name:HTTPConnectionDidDieNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
    [self stopInternal];
}

- (BOOL)running
{
    return self.server.isRunning;
}

- (void)start:(NSError **)error
{
    self.wantsRunning = YES;
    [self startInternal:error];
}

- (void)stop
{
    self.wantsRunning = NO;
    [self stopInternal];
}

- (NSURL *)URLWithOriginalURL:(NSURL *)URL
{
    KTVHCHTTPURL *HCURL = [[KTVHCHTTPURL alloc] initWithOriginalURL:URL];
    URL = [HCURL proxyURLWithPort:self.server.listeningPort];
    KTVHCLogHTTPServer(@"%p, Return URL\nURL : %@", self, URL);
    return URL;
}

#pragma mark - Internal

- (void)startInternal:(NSError **)error
{
    self.server = [[HTTPServer alloc] init];
    [self.server setConnectionClass:[KTVHCHTTPConnection class]];
    [self.server setType:@"_http._tcp."];
    [self.server setPort:80];
    if ([self.server start:error]) {
        KTVHCLogHTTPServer(@"%p, Start server success", self);
    } else {
        KTVHCLogHTTPServer(@"%p, Start server failed", self);
    }
}

- (void)stopInternal
{
    [self.server stop];
    self.server = nil;
}

#pragma mark - Background

- (void)applicationDidEnterBackground
{
    if (self.server.numberOfHTTPConnections > 0) {
        [self beginBackgroundTask];
    } else {
        [self endBackgroundTask];
    }
}

- (void)applicationWillEnterForeground
{
    if (self.backgroundTask == UIBackgroundTaskInvalid) {
        if (self.wantsRunning) {
            [self startInternal:nil];
        }
    } else {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
}

- (void)HTTPConnectionDidDie
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground &&
            self.backgroundTask != UIBackgroundTaskInvalid &&
            self.server.numberOfHTTPConnections == 0) {
            [self endBackgroundTask];
        }
    });
}

- (void)beginBackgroundTask
{
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
}

- (void)endBackgroundTask
{
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
    self.backgroundTask = UIBackgroundTaskInvalid;
    [self stopInternal];
}

@end
