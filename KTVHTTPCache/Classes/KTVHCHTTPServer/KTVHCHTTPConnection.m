//
//  KTVHCHTTPConnection.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/10.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCHTTPConnection.h"
#import "KTVHCHTTPHLSResponse.h"
#import "KTVHCHTTPResponse.h"
#import "KTVHCDataStorage.h"
#import "KTVHCHTTPHeader.h"
#import "KTVHCURLTool.h"
#import "KTVHCLog.h"

@implementation KTVHCHTTPConnection

+ (NSString *)URITokenPing
{
    return @"KTVHTTPCachePing";
}

+ (NSString *)URITokenPlaceHolder
{
    return @"KTVHTTPCachePlaceHolder";
}

+ (NSString *)URITokenLastPathComponent
{
    return @"KTVHTTPCacheLastPathComponent";
}

- (id)initWithAsyncSocket:(GCDAsyncSocket *)newSocket configuration:(HTTPConfig *)aConfig
{
    if (self = [super initWithAsyncSocket:newSocket configuration:aConfig]) {
        KTVHCLogAlloc(self);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    KTVHCLogHTTPConnection(@"%p, Receive request\nmethod : %@\npath : %@\nURL : %@", self, method, path, request.url);
    if ([path containsString:[self.class URITokenPing]]) {
        return [[HTTPDataResponse alloc] initWithData:[@"ping" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    NSMutableArray *components = [path componentsSeparatedByString:@"/"].mutableCopy;
    if (components.count < 3) {
        return [[HTTPErrorResponse alloc] initWithErrorCode:404];
    }
    NSString *URLString = [[KTVHCURLTool tool] URLDecode:components[1]];
    if (![URLString hasPrefix:@"http"]) {
        return [[HTTPErrorResponse alloc] initWithErrorCode:404];
    }
    NSURL *URL = nil;
    if ([path containsString:[self.class URITokenLastPathComponent]]) {
        URL = [NSURL URLWithString:URLString];
    } else {
        [components removeObjectAtIndex:0];
        [components removeObjectAtIndex:0];
        URLString = URLString.stringByDeletingLastPathComponent;
        if ([path containsString:[self.class URITokenPlaceHolder]]) {
            [components removeObjectAtIndex:0];
        } else {
            URLString = URLString.stringByDeletingLastPathComponent;
        }
        NSString *lastPathComponent = [components componentsJoinedByString:@"/"];
        if ([lastPathComponent hasPrefix:@"http"]) {
            URLString = lastPathComponent;
        } else {
            URLString = [URLString stringByAppendingPathComponent:lastPathComponent];
        }
        URL = [NSURL URLWithString:URLString];
        KTVHCLogHTTPConnection(@"%p, Receive redirect request\nURL : %@", self, URLString);
    }
    KTVHCLogHTTPConnection(@"%p, Accept request\nURL : %@", self, URL);
    KTVHCDataRequest *dataRequest = [[KTVHCDataRequest alloc] initWithURL:URL headers:request.allHeaderFields];
    if ([URLString containsString:@".m3u"]) {
        return [[KTVHCHTTPHLSResponse alloc] initWithConnection:self dataRequest:dataRequest];
    }
    return [[KTVHCHTTPResponse alloc] initWithConnection:self dataRequest:dataRequest];
}


@end
