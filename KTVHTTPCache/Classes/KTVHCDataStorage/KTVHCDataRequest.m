//
//  KTVHCDataRequest.m
//  KTVHTTPCache
//
//  Created by Single on 2017/8/11.
//  Copyright © 2017年 Single. All rights reserved.
//

#import "KTVHCDataRequest.h"
#import "KTVHCDataPrivate.h"
#import "KTVHCContentType.h"
#import "KTVHCLog.h"

@implementation KTVHCDataRequest

- (instancetype)initWithURL:(NSURL *)URL headers:(NSDictionary *)headers
{
    if (self = [super init])
    {
        KTVHCLogAlloc(self);
        
        _URL = URL;
        _headers = headers;
        _contentRange = KTVHCRangeWithHeaderValue(self.headers[@"Range"]);
        _acceptContentTypes = [KTVHCContentType defaultAcceptContextTypes];
        
        KTVHCLogDataRequest(@"did setup\n%@\nrange, %@, \n%@", self.URL, KTVHCStringFromRange(self.contentRange), self.headers);
    }
    return self;
}

- (void)dealloc
{
    KTVHCLogDealloc(self);
}

@end
