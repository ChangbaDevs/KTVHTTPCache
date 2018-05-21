//
//  KTVHCHTTPServer.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCHTTPServer.h"
#import "KTVHCHTTPURL.h"
#import "KTVHCHTTPConnection.h"
#import "KTVHCHTTPHeader.h"
#import "KTVHCLog.h"

@interface KTVHCHTTPServer ()

@property (nonatomic, strong) HTTPServer * coreHTTPServer;

@property (nonatomic, assign) BOOL pinging;
@property (nonatomic, assign) BOOL pingResult;
@property (nonatomic, assign) NSTimeInterval pingTimeInterval;
@property (nonatomic, strong) NSCondition * pingCondition;
@property (nonatomic, strong) NSURLSession * pingSession;
@property (nonatomic, strong) NSURLSessionDataTask * pingDataTask;

@end

@implementation KTVHCHTTPServer

+ (instancetype)server
{
    static KTVHCHTTPServer * obj = nil;
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
        KTVHCLogAlloc(self);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
    [self stop];
}

- (BOOL)restart
{
    KTVHCLogHTTPServer(@"%p, Restart connection count : %lld", self, (long long)[self.coreHTTPServer numberOfHTTPConnections]);
    [self.coreHTTPServer stop];
    NSError * error = nil;
    [self.coreHTTPServer start:&error];
    if (error) {
        KTVHCLogHTTPServer(@"%p, Restart server failed : %@", self, error);
    } else {
        KTVHCLogHTTPServer(@"%p, Restart server success", self);
    }
    return error == nil;
}

- (void)start:(NSError * __autoreleasing *)error
{
    self.coreHTTPServer = [[HTTPServer alloc] init];
    [self.coreHTTPServer setConnectionClass:[KTVHCHTTPConnection class]];
    [self.coreHTTPServer setType:@"_http._tcp."];
    NSError * tempError = nil;
    [self.coreHTTPServer start:&tempError];
    if (tempError) {
        * error = tempError;
        KTVHCLogHTTPServer(@"%p, Start server failed : %@", self, tempError);
    } else {
        KTVHCLogHTTPServer(@"%p, Start server success", self);
    }
}

- (void)stop
{
    if (self.running) {
        [self.coreHTTPServer stop];
        [self.pingSession invalidateAndCancel];
        [self.pingDataTask cancel];
        self.pingDataTask = nil;
        self.pingSession = nil;
        KTVHCLogHTTPServer(@"%p, Stop server", self);
    }
}

- (NSString *)URLStringWithOriginalURLString:(NSString *)URLString
{
    if (self.running && [URLString hasPrefix:@"http"]) {
        if ([self ping]) {
            KTVHCHTTPURL * url = [KTVHCHTTPURL URLWithOriginalURLString:URLString];
            NSString * ret = [url proxyURLStringWithServerPort:self.coreHTTPServer.listeningPort];
            KTVHCLogHTTPServer(@"%p, Return proxy URL\n%@", self, ret);
            return ret;
        } else {
            KTVHCLogHTTPServer(@"%p, Ping failed 1", self);
            BOOL success = [self restart];
            if (success) {
                if ([self ping]) {
                    KTVHCHTTPURL * url = [KTVHCHTTPURL URLWithOriginalURLString:URLString];
                    return [url proxyURLStringWithServerPort:self.coreHTTPServer.listeningPort];
                } else {
                    KTVHCLogHTTPServer(@"%p, Ping failed 2", self);
                }
            }
        }
    }
    KTVHCLogHTTPServer(@"%p, Return original URL\n%@", self, URLString);
    return URLString;
}

- (BOOL)ping
{
     if ([NSDate date].timeIntervalSince1970 - self.pingTimeInterval < 0.5) {
         return self.pingResult;
     }
    if (self.running) {
        if (!self.pingSession) {
            self.pingCondition = [[NSCondition alloc] init];
            NSURLSessionConfiguration * sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfiguration.timeoutIntervalForRequest = 3;
            self.pingSession = [NSURLSession sessionWithConfiguration:sessionConfiguration];
        }
        [self.pingCondition lock];
        if (self.pinging) {
            [self.pingCondition wait];
        } else {
            NSURL * pingURL = [[KTVHCHTTPURL URLForPing] proxyURLWithServerPort:self.coreHTTPServer.listeningPort];
            self.pingDataTask = [self.pingSession dataTaskWithURL:pingURL
                                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                          if (!error && data.length > 0) {
                                              NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                              if ([string isEqualToString:[KTVHCHTTPConnection responsePingTokenString]]) {
                                                  self.pingResult = YES;
                                              } else {
                                                  self.pingResult = NO;
                                              }
                                          } else {
                                              self.pingResult = NO;
                                          }
                                          self.pingTimeInterval = [NSDate date].timeIntervalSince1970;
                                          [self.pingCondition lock];
                                          self.pinging = NO;
                                          [self.pingCondition broadcast];
                                          [self.pingCondition unlock];
                                      }];
            self.pinging = YES;
            [self.pingDataTask resume];
            [self.pingCondition wait];
        }
        [self.pingCondition unlock];
    }
    KTVHCLogHTTPServer(@"%p, Ping result : %d", self, self.pingResult);
    return self.pingResult;
}

- (BOOL)running
{
    return self.coreHTTPServer.isRunning;
}

@end
