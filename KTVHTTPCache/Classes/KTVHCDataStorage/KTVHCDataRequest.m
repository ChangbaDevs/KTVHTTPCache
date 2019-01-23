//
//  KTVHCDataRequest.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataRequest.h"
#import "KTVHCLog.h"

@implementation KTVHCDataRequest

- (instancetype)initWithURL:(NSURL *)URL headerFields:(NSDictionary *)headerFields
{
    if (self = [super init]) {
        KTVHCLogAlloc(self);
        self->_URL = URL;
        self->_headerFields = KTVHCRangeFillToRequestHeadersIfNeeded(KTVHCRangeFull(), headerFields);
        self->_range = KTVHCRangeWithRequestHeaderValue([self.headerFields objectForKey:@"Range"]);
        KTVHCLogDataRequest(@"%p Create data request\nURL : %@\nHeaders : %@\nRange : %@", self, self.URL, self.headerFields, KTVHCStringFromRange(self.range));
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

- (KTVHCDataRequest *)requestWithRange:(KTVHCRange)range
{
    NSDictionary *headerFields = KTVHCRangeFillToRequestHeaders(range, self.headerFields);
    KTVHCDataRequest *obj = [[KTVHCDataRequest alloc] initWithURL:self.URL headerFields:headerFields];
    return obj;
}

- (KTVHCDataRequest *)requestWithTotalLength:(long long)totalLength
{
    KTVHCRange range = KTVHCRangeWithEnsureLength(self.range, totalLength);
    return [self requestWithRange:range];
}

@end
