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

#import <ifaddrs.h>
#import <arpa/inet.h>
#import <net/if.h>

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
        self.server = [[HTTPServer alloc] init];
        [self.server setConnectionClass:[KTVHCHTTPConnection class]];
        [self.server setType:@"_http._tcp."];
        [self.server setPort:8089];
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


- (NSURL *)URLWithFileOriginalURL:(NSURL *)fileURL
{
    if (!fileURL.isFileURL) {
        return fileURL;
    }
    if (!self.isRunning) {
        return fileURL;
    }
    NSString * domain = [KTVHCHTTPServer deviceIPAdress];
    if ([domain isEqual: @"localhost"]) {
        domain = @"localhost";
    }
    NSString *original = [[KTVHCURLTool tool] URLEncode:fileURL.absoluteString];
    NSString *server = [NSString stringWithFormat:@"http://%@:%d/", domain,self.server.listeningPort];
    NSString *extension = fileURL.pathExtension ? [NSString stringWithFormat:@".%@", fileURL.pathExtension] : @"";
    NSString *URLString = [NSString stringWithFormat:@"%@request%@?fileUrl=%@", server, extension, original];
    fileURL = [NSURL URLWithString:URLString];
    KTVHCLogHTTPServer(@"%p, Return fileURL\fileURL : %@ domain = %@", self, fileURL,domain);
    return fileURL;
}


- (NSURL *)URLWithOriginalURL:(NSURL *)URL
{
    if (!URL || URL.isFileURL || URL.absoluteString.length == 0) {
        return URL;
    }
    if (!self.isRunning) {
        return URL;
    }
    NSString * domain = [KTVHCHTTPServer deviceIPAdress];
    if ([domain isEqual: @"localhost"]) {
        domain = @"localhost";
    }
    NSString *original = [[KTVHCURLTool tool] URLEncode:URL.absoluteString];
    NSString *server = [NSString stringWithFormat:@"http://%@:%d/", domain,self.server.listeningPort];
    NSString *extension = URL.pathExtension ? [NSString stringWithFormat:@".%@", URL.pathExtension] : @"";
    NSString *URLString = [NSString stringWithFormat:@"%@request%@?url=%@", server, extension, original];
    URL = [NSURL URLWithString:URLString];
    KTVHCLogHTTPServer(@"%p, Return URL\nURL : %@ domain = %@", self, URL, domain);
    return URL;
}

- (NSURL *)LocalHostURLWithOriginalURL:(NSURL *)URL
{
    if (!URL || URL.isFileURL || URL.absoluteString.length == 0) {
        return URL;
    }
    if (!self.isRunning) {
        return URL;
    }
    NSString * domain = @"localhost";
    NSString *original = [[KTVHCURLTool tool] URLEncode:URL.absoluteString];
    NSString *server = [NSString stringWithFormat:@"http://%@:%d/", domain,self.server.listeningPort];
    NSString *extension = URL.pathExtension ? [NSString stringWithFormat:@".%@", URL.pathExtension] : @"";
    NSString *URLString = [NSString stringWithFormat:@"%@request%@?url=%@", server, extension, original];
    URL = [NSURL URLWithString:URLString];
    KTVHCLogHTTPServer(@"%p, Return URL\nURL : %@ domain = %@", self, URL, domain);
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

#pragma mark - Background Task

- (void)applicationDidEnterBackground
{
    if (self.server.numberOfHTTPConnections > 0) {
        KTVHCLogHTTPServer(@"%p, enter background", self);
        [self beginBackgroundTask];
    } else {
        KTVHCLogHTTPServer(@"%p, enter background and stop server", self);
        [self stopInternal];
    }
}

- (void)applicationWillEnterForeground
{
    KTVHCLogHTTPServer(@"%p, enter foreground", self);
    if (self.backgroundTask == UIBackgroundTaskInvalid && self.wantsRunning) {
        KTVHCLogHTTPServer(@"%p, restart server", self);
        [self startInternal:nil];
    }
    [self endBackgroundTask];
}

- (void)HTTPConnectionDidDie
{
    KTVHCLogHTTPServer(@"%p, connection did die", self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground &&
            self.server.numberOfHTTPConnections == 0) {
            KTVHCLogHTTPServer(@"%p, server idle", self);
            [self endBackgroundTask];
            [self stopInternal];
        }
    });
}

- (void)beginBackgroundTask
{
    KTVHCLogHTTPServer(@"%p, begin background task", self);
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        KTVHCLogHTTPServer(@"%p, background task expiration", self);
        [self endBackgroundTask];
        [self stopInternal];
    }];
}

- (void)endBackgroundTask
{
    if (self.backgroundTask != UIBackgroundTaskInvalid) {
        KTVHCLogHTTPServer(@"%p, end background task", self);
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
}


+ (NSString *)deviceIPAdress {
    
    NSString *address = @"localhost";
    
    struct ifaddrs *interfaces = NULL;
    
    struct ifaddrs *temp_addr = NULL;
    
    int success = 0;
    
    success = getifaddrs(&interfaces);
    
    if (success == 0) { // 0 表示获取成功
        
        temp_addr = interfaces;
        
        while (temp_addr != NULL) {
            
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                
                // Check if interface is en0 which is the wifi connection on the iPhone
                
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    
                    // Get NSString from C String
                    
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
            
        }
        
    }
    
    freeifaddrs(interfaces);
    
    return address;
    
}


#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"
#define IOS_VPN         @"utun0"
#define IP_ADDR_IPv4    @"ipv4"
#define IP_ADDR_IPv6    @"ipv6"

#pragma mark - 获取设备当前网络IP地址
+ (NSString *)getIPAddress:(BOOL)preferIPv4
{
    NSArray *searchArray = preferIPv4 ?
    @[ IOS_VPN @"/" IP_ADDR_IPv4, IOS_VPN @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6 ] :
    @[ IOS_VPN @"/" IP_ADDR_IPv6, IOS_VPN @"/" IP_ADDR_IPv4, IOS_WIFI @"/" IP_ADDR_IPv6, IOS_WIFI @"/" IP_ADDR_IPv4, IOS_CELLULAR @"/" IP_ADDR_IPv6, IOS_CELLULAR @"/" IP_ADDR_IPv4 ] ;
    
    NSDictionary *addresses = [self getIPAddresses];
    NSLog(@"addresses: %@", addresses);
    
    __block NSString *address;
    [searchArray enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop)
     {
         address = addresses[key];
         //筛选出IP地址格式
         if([self isValidatIP:address]) *stop = YES;
     } ];
    return address ? address : @"0.0.0.0";
}

+ (BOOL)isValidatIP:(NSString *)ipAddress {
    if (ipAddress.length == 0) {
        return NO;
    }
    NSString *urlRegEx = @"^([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\."
    "([01]?\\d\\d?|2[0-4]\\d|25[0-5])$";
    
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:urlRegEx options:0 error:&error];
    
    if (regex != nil) {
        NSTextCheckingResult *firstMatch=[regex firstMatchInString:ipAddress options:0 range:NSMakeRange(0, [ipAddress length])];
        
        if (firstMatch) {
            NSRange resultRange = [firstMatch rangeAtIndex:0];
            NSString *result=[ipAddress substringWithRange:resultRange];
            //输出结果
            NSLog(@"%@",result);
            return YES;
        }
    }
    return NO;
}

+ (NSDictionary *)getIPAddresses
{
    NSMutableDictionary *addresses = [NSMutableDictionary dictionaryWithCapacity:8];
    
    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) /* || (interface->ifa_flags & IFF_LOOPBACK) */ ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *name = [NSString stringWithUTF8String:interface->ifa_name];
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    NSString *key = [NSString stringWithFormat:@"%@/%@", name, type];
                    addresses[key] = [NSString stringWithUTF8String:addrBuf];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return [addresses count] ? addresses : nil;
}
@end
