//
//  KTVHCDataResponse.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/24.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataResponse.h"
#import "KTVHCDataPrivate.h"
#import "KTVHCLog.h"


@interface KTVHCDataResponse ()


@property (nonatomic, copy) NSString * contentType;

@property (nonatomic, assign) long long currentContentLength;
@property (nonatomic, assign) long long totalContentLength;

@property (nonatomic, copy) NSDictionary * headerFields;
@property (nonatomic, copy) NSDictionary * headerFieldsWithoutRangeAndLength;


@end


@implementation KTVHCDataResponse


+ (instancetype)responseWithCurrentContentLength:(long long)currentContentLength
                              totalContentLength:(long long)totalContentLength
                                    headerFields:(NSDictionary *)headerFields
               headerFieldsWithoutRangeAndLength:(NSDictionary *)headerFieldsWithoutRangeAndLength
{
    return [[self alloc] initWithCurrentContentLength:currentContentLength
                                   totalContentLength:totalContentLength
                                         headerFields:headerFields
                    headerFieldsWithoutRangeAndLength:headerFieldsWithoutRangeAndLength];
}

- (instancetype)initWithCurrentContentLength:(long long)currentContentLength
                              totalContentLength:(long long)totalContentLength
                                    headerFields:(NSDictionary *)headerFields
                headerFieldsWithoutRangeAndLength:(NSDictionary *)headerFieldsWithoutRangeAndLength
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        
        self.currentContentLength = currentContentLength;
        self.totalContentLength = totalContentLength;
        self.headerFields = headerFields;
        self.headerFieldsWithoutRangeAndLength = headerFieldsWithoutRangeAndLength;
        self.contentType = [self.headerFields objectForKey:@"Content-Type"];
        if (!self.contentType) {
            self.contentType = [self.headerFields objectForKey:@"content-type"];
        }
        
        KTVHCLogDataResponse(@"did setup\n%@\n%@\n%@\n%lld, %lld", self.contentType, self.headerFields, self.headerFieldsWithoutRangeAndLength, self.currentContentLength, self.totalContentLength);
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL headers:(NSDictionary *)headers
{
    if (self = [super init])
    {
        _URL = URL;
        _headers = headers;
        [self prepare];
        KTVHCLogAlloc(self);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (void)prepare
{
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

@end
