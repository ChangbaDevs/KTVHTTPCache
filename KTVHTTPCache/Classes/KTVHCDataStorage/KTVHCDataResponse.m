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
        NSMutableDictionary *headerFieldsWithoutRangeAndLength = [headerFields mutableCopy];
        [headerFieldsWithoutRangeAndLength removeObjectsForKeys:[self withoutHeaderKeys]];
        self->_headerFieldsWithoutRangeAndLength = headerFieldsWithoutRangeAndLength;
        self->_contentType = [self headerValueWithKey:@"Content-Type"];
        self->_currentLength = [self headerValueWithKey:@"Content-Length"].longLongValue;
        self->_range = KTVHCRangeWithResponseHeaderValue([self headerValueWithKey:@"Content-Range"], &self->_totalLength);
        KTVHCLogDataResponse(@"%p Create data response\nURL : %@\nHeaders : %@\nheaderFieldsWithoutRangeAndLength : %@\ncontentType : %@\ntotalLength : %lld\ncurrentLength : %lld", self, self.URL, self.headerFields, self.headerFieldsWithoutRangeAndLength, self.contentType, self.totalLength, self.currentLength);
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

- (NSArray<NSString *> *)withoutHeaderKeys
{
    static NSArray *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = @[@"Content-Length",
                @"content-length",
                @"Content-Range",
                @"content-range"];
    });
    return obj;
}

- (KTVHCDataResponse *)responseWithRange:(KTVHCRange)range
{
    if (!KTVHCEqualRanges(self.range, range)) {
        NSDictionary *headerFields = KTVHCRangeFillToResponseHeaders(range, self.headerFields, self.totalLength);
        KTVHCDataResponse *obj = [[KTVHCDataResponse alloc] initWithURL:self.URL headerFields:headerFields];
        return obj;
    }
    return self;
}

@end
