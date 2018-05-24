//
//  KTVHCDataResponse.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/24.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataResponse.h"
#import "KTVHCLog.h"

@implementation KTVHCDataResponse

- (instancetype)initWithURL:(NSURL *)URL headers:(NSDictionary *)headers
{
    if (self = [super init])
    {
        _URL = URL;
        _headers = headers;
        [self prepare];
        KTVHCLogAlloc(self);
        KTVHCLogDataResponse(@"%p Create data response\nURL : %@\nHeaders : %@\ncontentType : %@\ntotalLength : %lld\ncurrentLength : %lld",
                             self,
                             self.URL,
                             self.headers,
                             self.contentType,
                             self.totalLength,
                             self.currentLength);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (void)prepare
{
    NSMutableDictionary * headersWithoutRangeAndLength = [_headers mutableCopy];
    for (NSString * key in [self withoutHeaderKeys])
    {
        [headersWithoutRangeAndLength removeObjectForKey:key];
    }
    _headersWithoutRangeAndLength = [headersWithoutRangeAndLength copy];
    
    _contentType = [self headerValueWithKey:@"Content-Type"];
    _currentLength = [self headerValueWithKey:@"Content-Length"].longLongValue;
    
    NSString * contentRange = [self headerValueWithKey:@"Content-Range"];
    NSRange range = [contentRange rangeOfString:@"/"];
    if (contentRange.length > 0 && range.location != NSNotFound)
    {
        _totalLength = [contentRange substringFromIndex:range.location + range.length].longLongValue;
    }
}

- (NSString *)headerValueWithKey:(NSString *)key
{
    NSString * value = [self.headers objectForKey:key];
    if (!value)
    {
        value = [self.headers objectForKey:[key lowercaseString]];
    }
    return value;
}

- (NSArray <NSString *> *)withoutHeaderKeys
{
    static NSArray * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = @[@"Content-Length", @"content-length", @"Content-Range", @"content-range"];
    });
    return obj;
}

@end
