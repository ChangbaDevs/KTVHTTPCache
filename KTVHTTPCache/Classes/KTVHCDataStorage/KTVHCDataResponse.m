//
//  KTVHCDataResponse.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/24.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataResponse.h"
#import "KTVHCData+Internal.h"
#import "KTVHCLog.h"

@interface KTVHCDataResponse ()

@property (nonatomic, readonly) KTVHCRange contentRange;
@property (nonatomic, copy, readonly) NSString *contentRangeString;

@end

@implementation KTVHCDataResponse

- (instancetype)initWithURL:(NSURL *)URL headers:(NSDictionary *)headers
{
    if (self = [super init]) {
        KTVHCLogAlloc(self);
        self->_URL = URL;
        self->_headers = headers;
        self->_contentType = [self headerValueWithKey:@"Content-Type"];
        self->_contentLength = [self headerValueWithKey:@"Content-Length"].longLongValue;
        self->_contentRangeString = [self headerValueWithKey:@"Content-Range"];
        if (self->_contentRangeString == nil && self->_contentLength > 0) {
            self->_contentRangeString = KTVHCResponseRangeStringWithContentLength(self->_contentLength);
        }
        if (self->_contentRangeString == nil) {
            self->_contentRange = KTVHCRangeInvaild();
            self->_totalLength = self->_contentLength;
        } else {
            self->_contentRange = KTVHCRangeWithResponseHeaderValue(self->_contentRangeString, &self->_totalLength);
        }
        KTVHCLogDataResponse(@"%p Create data response\nURL : %@\nHeaders : %@\ncontentType : %@\ntotalLength : %lld\ncurrentLength : %lld", self, self.URL, self.headers, self.contentType, self.totalLength, self.contentLength);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (NSString *)headerValueWithKey:(NSString *)key
{
    NSString *value = [self.headers objectForKey:key];
    if (!value) {
        value = [self.headers objectForKey:[key lowercaseString]];
    }
    return value;
}

@end
