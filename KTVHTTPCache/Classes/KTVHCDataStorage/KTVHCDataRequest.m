//
//  KTVHCDataRequest.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataRequest.h"
#import "KTVHCContentType.h"
#import "KTVHCLog.h"

@implementation KTVHCDataRequest

- (instancetype)initWithURL:(NSURL *)URL headers:(NSDictionary *)headers
{
    if (self = [super init])
    {
        _URL = URL;
        _headers = headers;
        _range = KTVHCRangeWithHeaderValue(self.headers[@"Range"]);
        _acceptContentTypes = [KTVHCContentType defaultAcceptContentTypes];
        KTVHCLogAlloc(self);
        KTVHCLogDataRequest(@"%p Create data request\nURL : %@\nHeaders : %@\nRange : %@\nAcceptContentTypes : %@", self, self.URL, self.headers, KTVHCStringFromRange(self.range), self.acceptContentTypes);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

@end
