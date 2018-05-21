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

- (instancetype)initWithURL:(NSURL *)URL headers:(NSDictionary *)headers
{
    if (self = [super init])
    {
        _URL = URL;
        _headers = headers;
        _range = KTVHCRangeWithHeaderValue(self.headers[@"Range"]);
        KTVHCLogAlloc(self);
        KTVHCLogDataRequest(@"%p Create data request\nURL : %@\nHeaders : %@\nRange : %@", self, self.URL, self.headers, KTVHCStringFromRange(self.range));
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

@end
