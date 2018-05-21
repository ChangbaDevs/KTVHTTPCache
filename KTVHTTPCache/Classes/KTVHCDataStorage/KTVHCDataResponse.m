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
        KTVHCLogDataResponse(@"%p Create data response\nURL : %@\nHeaders : %@\ncontentType : %@\ntotalLength : %lld\ncurrentLength : %lld", self, self.URL, self.headers, self.contentType, self.totalLength, self.currentLength);
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
    [[self withoutKeys] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [headersWithoutRangeAndLength removeObjectForKey:obj];
    }];
    _headersWithoutRangeAndLength = [headersWithoutRangeAndLength copy];
    _contentType = [self.headers objectForKey:@"Content-Type"];
    if (_contentType) {
        _contentType = [self.headers objectForKey:@"content-type"];
    }
    NSString * contentLength = [self.headers objectForKey:@"Content-Length"];
    if (!contentLength) {
        contentLength = [self.headers objectForKey:@"content-length"];
    }
    _currentLength = contentLength.longLongValue;
    NSString * contentRange = [self.headers objectForKey:@"Content-Range"];
    if (!contentRange) {
        contentRange = [self.headers objectForKey:@"content-range"];
    }
    NSRange range = [contentRange rangeOfString:@"/"];
    if (contentRange.length > 0 && range.location != NSNotFound) {
        _totalLength = [contentRange substringFromIndex:range.location + range.length].longLongValue;
    }
}

- (NSArray *)withoutKeys
{
    static NSArray * obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = @[@"Content-Length", @"content-length", @"Content-Range", @"content-range"];
    });
    return obj;
}

@end
