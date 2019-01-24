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

- (instancetype)initWithURL:(NSURL *)URL headerFields:(NSDictionary *)headerFields
{
    if (self = [super init]) {
        KTVHCLogAlloc(self);
        self->_URL = URL;
        self->_headerFields = headerFields;
        self->_contentType = [self headerValueWithKey:@"Content-Type"];
        self->_contentRangeString = [self headerValueWithKey:@"Content-Range"];
        self->_contentLength = [self headerValueWithKey:@"Content-Length"].longLongValue;
        self->_contentRange = KTVHCRangeWithResponseHeaderValue(self.contentRangeString, &self->_totalLength);
        KTVHCLogDataResponse(@"%p Create data response\nURL : %@\nHeaders : %@\ncontentType : %@\ntotalLength : %lld\ncurrentLength : %lld", self, self.URL, self.headerFields, self.contentType, self.totalLength, self.contentLength);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (NSString *)headerValueWithKey:(NSString *)key
{
    NSString *value = [self.headerFields objectForKey:key];
    if (!value) {
        value = [self.headerFields objectForKey:[key lowercaseString]];
    }
    return value;
}

- (KTVHCDataResponse *)responseWithRange:(KTVHCRange)range
{
    if (!KTVHCEqualRanges(self.contentRange, range)) {
        NSDictionary *headerFields = KTVHCRangeFillToResponseHeaders(range, self.headerFields, self.totalLength);
        KTVHCDataResponse *obj = [[KTVHCDataResponse alloc] initWithURL:self.URL headerFields:headerFields];
        return obj;
    }
    return self;
}

@end
