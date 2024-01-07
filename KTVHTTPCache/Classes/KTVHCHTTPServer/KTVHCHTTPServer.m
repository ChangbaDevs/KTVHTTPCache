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
#import "KTVHCURLTool.h"
#import "KTVHCLog.h"

#import <net/if.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

@interface KTVHCHTTPServer ()

@property (nonatomic) BOOL wantsRunning;
@property (nonatomic, strong) HTTPServer *server;
@property (nonatomic, strong) NSCondition *pingCondition;
@property (nonatomic, strong) dispatch_queue_t pingQueue;
@property (nonatomic, strong) NSURLSessionDataTask *pingTask;

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
        self.server = [[HTTPServer alloc] init];
        [self.server setConnectionClass:[KTVHCHTTPConnection class]];
        [self.server setType:@"_http._tcp."];
        self.pingCondition = [[NSCondition alloc] init];
        self.pingQueue = dispatch_queue_create("KTVHCHTTPServer_pingQueue", DISPATCH_QUEUE_SERIAL);
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
    [self stopInternal];
}

- (BOOL)setPort:(UInt16)port
{
    if (self.isRunning) {
        return NO;
    }
    [self.server setPort:port];
    return YES;
}

- (BOOL)isRunning
{
    return self.server.isRunning;
}

- (BOOL)start:(NSError **)error
{
    self.wantsRunning = YES;
    return [self startInternal:error];
}

- (void)stop
{
    self.wantsRunning = NO;
    [self stopInternal];
}

- (NSURL *)URLWithOriginalURL:(NSURL *)URL
{
    return [self URLWithOriginalURL:URL bindToLocalhost:YES];
}

- (NSURL *)URLWithOriginalURL:(NSURL *)URL bindToLocalhost:(BOOL)bindToLocalhost
{
    if (!URL || URL.isFileURL || URL.absoluteString.length == 0) {
        return URL;
    }
    if (!self.isRunning) {
        return URL;
    }
    NSString *URLString = [NSString stringWithFormat:@"http://%@:%d/%@/%@/%@%@",
                           bindToLocalhost ? @"localhost" : [self getPrimaryIPAddress],
                           self.server.listeningPort,
                           [[KTVHCURLTool tool] URLEncode:URL.absoluteString],
                           [KTVHCHTTPConnection URITokenPlaceHolder],
                           [KTVHCHTTPConnection URITokenLastPathComponent],
                           URL.pathExtension.length > 0 ? [NSString stringWithFormat:@".%@", URL.pathExtension] : @""];
    URL = [NSURL URLWithString:URLString];
    KTVHCLogHTTPServer(@"%p, Return URL\nURL : %@", self, URL);
    return URL;
}

#pragma mark - Internal

- (BOOL)startInternal:(NSError **)error
{
    BOOL ret = [self.server start:error];
    if (ret) {
        KTVHCLogHTTPServer(@"%p, Start server success", self);
    } else {
        KTVHCLogHTTPServer(@"%p, Start server failed", self);
    }
    return ret;
}

- (void)stopInternal
{
    [self.server stop];
}

- (BOOL)ping
{
    [self.pingCondition lock];
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.timeoutIntervalForRequest = 3;
        session = [NSURLSession sessionWithConfiguration:configuration];
    });
    __block BOOL result = NO;
    __weak typeof(self) weakSelf = self;
    NSURL *URL = [self URLWithOriginalURL:[NSURL URLWithString:[KTVHCHTTPConnection URITokenPing]]];
    self.pingTask = [session dataTaskWithURL:URL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error && data.length > 0) {
            result = YES;
        }
        [weakSelf.pingCondition lock];
        [weakSelf.pingCondition broadcast];
        [weakSelf.pingCondition unlock];
    }];
    [self.pingTask resume];
    [self.pingCondition wait];
    self.pingTask = nil;
    [self.pingCondition unlock];
    return result;
}

- (NSString *)getPrimaryIPAddress
{
    NSString *address = @"localhost";
    struct ifaddrs *list;
    if (getifaddrs(&list) >= 0) {
        for (struct ifaddrs *ifap = list; ifap; ifap = ifap->ifa_next) {
            if (strcmp(ifap->ifa_name, "en0")) {
                continue;
            }
            if ((ifap->ifa_flags & IFF_UP) && (ifap->ifa_addr->sa_family == AF_INET)) {
                address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)ifap->ifa_addr)->sin_addr)];
                break;
            }
        }
        freeifaddrs(list);
    }
    return address;
}

#pragma mark - Background Task

- (void)applicationWillEnterForeground
{
    dispatch_async(self.pingQueue, ^{
        if (self.wantsRunning) {
            KTVHCLogHTTPServer(@"%p, ping server", self);
            if (![self ping]) {
                [self stopInternal];
                NSError *error = nil;
                if (![self startInternal:&error]) {
                    KTVHCLogHTTPServer(@"%p, restart server error %@", self, error);
                };
            }
        }
    });
}

@end
