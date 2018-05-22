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


#pragma mark - Init

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


#pragma mark - Control

- (BOOL)restart
{
    KTVHCLogHTTPServer(@"restart begin");
    
    NSLog(@"restart connection count, %lld", (long long)[self.coreHTTPServer numberOfHTTPConnections]);
    [self.coreHTTPServer stop];
    
    NSError * error = nil;
    [self.coreHTTPServer start:&error];
    if (error)
    {
        KTVHCLogHTTPServer(@"restart server failure : %@", error);
    }
    else
    {
        KTVHCLogHTTPServer(@"restart server success");
    }
    
    KTVHCLogHTTPServer(@"restart end");
    
    return error == nil;
}

- (void)start:(NSError * __autoreleasing *)error
{
    self.coreHTTPServer = [[HTTPServer alloc] init];
    [self.coreHTTPServer setConnectionClass:[KTVHCHTTPConnection class]];
    [self.coreHTTPServer setType:@"_http._tcp."];
    
    NSError * tempError = nil;
    [self.coreHTTPServer start:&tempError];
    if (tempError)
    {
        * error = tempError;
        KTVHCLogHTTPServer(@"start server failure : %@", tempError);
    }
    else
    {
        KTVHCLogHTTPServer(@"start server success");
    }
}

- (void)stop
{
    if (self.running)
    {
        [self.coreHTTPServer stop];
        [self.pingSession invalidateAndCancel];
        [self.pingDataTask cancel];
        self.pingDataTask = nil;
        self.pingSession = nil;
        
        KTVHCLogHTTPServer(@"stop server");
    }
}

- (NSString *)URLStringWithOriginalURLString:(NSString *)URLString
{
    if (self.running && [URLString hasPrefix:@"http"])
    {
        if ([self ping])
        {
            KTVHCHTTPURL * url = [KTVHCHTTPURL URLWithOriginalURLString:URLString];
            return [url proxyURLStringWithServerPort:self.coreHTTPServer.listeningPort];
        }
        else
        {
            KTVHCLogHTTPServer(@"ping failured 1");
            
            BOOL success = [self restart];
            if (success)
            {
                if ([self ping])
                {
                    KTVHCHTTPURL * url = [KTVHCHTTPURL URLWithOriginalURLString:URLString];
                    return [url proxyURLStringWithServerPort:self.coreHTTPServer.listeningPort];
                }
                else
                {
                    KTVHCLogHTTPServer(@"ping failured 2");
                }
            }
        }
    }
    
    KTVHCLogHTTPServer(@"return original URL string");
    
    return URLString;
}


#pragma mark - Ping

- (BOOL)ping
{
    /*
     if ([NSDate date].timeIntervalSince1970 - self.pingTimeInterval < 0.5)
     {
         return self.pingResult;
     }
     */
    
    if (self.running)
    {
        if (!self.pingSession)
        {
            self.pingCondition = [[NSCondition alloc] init];
            NSURLSessionConfiguration * sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfiguration.timeoutIntervalForRequest = 3;
            self.pingSession = [NSURLSession sessionWithConfiguration:sessionConfiguration];
        }
        
        [self.pingCondition lock];
        if (self.pinging)
        {
            [self.pingCondition wait];
        }
        else
        {
            NSURL * pingURL = [[KTVHCHTTPURL URLForPing] proxyURLWithServerPort:self.coreHTTPServer.listeningPort];
            self.pingDataTask = [self.pingSession dataTaskWithURL:pingURL
                                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                          if (!error && data.length > 0)
                                          {
                                              NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                              if ([string isEqualToString:[KTVHCHTTPConnection responsePingTokenString]])
                                              {
                                                  self.pingResult = YES;
                                              }
                                              else
                                              {
                                                  self.pingResult = NO;
                                              }
                                          }
                                          else
                                          {
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
    
    KTVHCLogHTTPServer(@"ping result, %d", self.pingResult);
    
    return self.pingResult;
}


#pragma mark - Setter/Getter

- (BOOL)running
{
    return self.coreHTTPServer.isRunning;
}


@end
