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
#import <CocoaHTTPServer/CocoaHTTPServer.h>

@interface KTVHCHTTPServer ()

@property (nonatomic, strong) HTTPServer * coreHTTPServer;

@end

@implementation KTVHCHTTPServer


#pragma mark - Init

+ (instancetype)httpServer
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
    if (self = [super init]) {
        
    }
    return self;
}


#pragma mark - Control

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
        NSLog(@"%@, start core HTTPServer error : %@", [self class], tempError);
    }
    else
    {
        NSLog(@"%@, start core HTTPServer success", [self class]);
    }
}

- (void)stop
{
    if (self.running) {
        [self.coreHTTPServer stop];
    }
}

- (NSString *)URLStringWithOriginalURLString:(NSString *)urlString
{
#if 0
    return urlString;
#endif
    if (self.running)
    {
        KTVHCHTTPURL * url = [KTVHCHTTPURL URLWithOriginalURLString:urlString];
        return [url proxyURLString];
    }
    return urlString;
}


#pragma mark - Setter/Getter

- (BOOL)running
{
    return self.coreHTTPServer.isRunning;
}

- (NSInteger)listeningPort
{
    if (self.running) {
        return self.coreHTTPServer.listeningPort;
    }
    return 0;
}

@end
