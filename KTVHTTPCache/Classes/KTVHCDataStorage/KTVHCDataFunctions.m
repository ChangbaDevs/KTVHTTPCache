//
//  KTVHCDataFunctions.m
//  KTVHTTPCache
//
//  Created by Single on 2018/5/20.
//  Copyright © 2018年 Single. All rights reserved.
//

#import "KTVHCDataFunctions.h"

KTVHCDataRequest * KTVHCCopyRequestIfNeeded(KTVHCDataRequest * request, KTVHCRange range)
{
    if (!KTVHCEqualRanges(request.range, range)) {
        NSURL * URL = request.URL;
        NSDictionary * headers = KTVHCRangeFillToHeaders(range, request.headers);
        KTVHCDataRequest * obj = [[KTVHCDataRequest alloc] initWithURL:URL headers:headers];
        obj.acceptContentTypes = request.acceptContentTypes;
        return obj;
    }
    return request;
}
