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
}


#pragma mark - Control

- (BOOL)restart
{
    KTVHCLogHTTPServer(@"restart begin");
    
    NSLog(@"restart connection count, %ld", [self.coreHTTPServer numberOfHTTPConnections]);
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
        KTVHCLogHTTPServer(@"stop server");
    }
}

- (NSString *)URLStringWithOriginalURLString:(NSString *)urlString
{
    if (self.running)
    {
        if ([self ping])
        {
            KTVHCHTTPURL * url = [KTVHCHTTPURL URLWithOriginalURLString:urlString];
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
                    KTVHCHTTPURL * url = [KTVHCHTTPURL URLWithOriginalURLString:urlString];
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
    
    return urlString;
}


#pragma mark - Ping

- (BOOL)ping
{
    static BOOL result = NO;
    static NSTimeInterval resultTime = 0;
    
    /*
     if ([NSDate date].timeIntervalSince1970 - resultTime < 1)
     {
     return result;
     }
     */
    
    if (self.running)
    {
        static BOOL pinging = NO;
        static NSCondition * pingCondition = nil;
        static NSURLSession * pingSession = nil;
        static NSURLSessionDataTask * pingDataTask = nil;
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            pingCondition = [[NSCondition alloc] init];
            NSURLSessionConfiguration * pingSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
            pingSessionConfiguration.timeoutIntervalForRequest = 3;
            pingSession = [NSURLSession sessionWithConfiguration:pingSessionConfiguration];
        });
        
        [pingCondition lock];
        if (pinging)
        {
            [pingCondition wait];
        }
        else
        {
            pingDataTask = [pingSession dataTaskWithURL:[[KTVHCHTTPURL URLForPing] proxyURLWithServerPort:self.coreHTTPServer.listeningPort]
                                      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                                          if (!error && data.length > 0)
                                          {
                                              NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                              if ([string isEqualToString:[KTVHCHTTPConnection responsePingTokenString]])
                                              {
                                                  result = YES;
                                              }
                                              else
                                              {
                                                  result = NO;
                                              }
                                          }
                                          else
                                          {
                                              result = NO;
                                          }
                                          resultTime = [NSDate date].timeIntervalSince1970;
                                          
                                          [pingCondition lock];
                                          pinging = NO;
                                          [pingCondition broadcast];
                                          [pingCondition unlock];
                                      }];
            pinging = YES;
            [pingDataTask resume];
            [pingCondition wait];
        }
        [pingCondition unlock];
    }
    
    KTVHCLogHTTPServer(@"ping result, %d", result);
    
    return result;
}


#pragma mark - Setter/Getter

- (BOOL)running
{
    return self.coreHTTPServer.isRunning;
}


@end
