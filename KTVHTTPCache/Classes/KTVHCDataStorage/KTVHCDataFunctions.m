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
        NSDictionary * headers = KTVHCRangeFillToRequestHeaders(range, request.headers);
        KTVHCDataRequest * obj = [[KTVHCDataRequest alloc] initWithURL:request.URL headers:headers];
        return obj;
    }
    return request;
}

KTVHCDataResponse * KTVHCCopyResponseIfNeeded(KTVHCDataResponse * response, KTVHCRange range, long long totalLength)
{
    long long currentLength = KTVHCRangeGetLength(range);
    if (response.totalLength != totalLength || response.currentLength != currentLength) {
        NSDictionary * headers = KTVHCRangeFillToResponseHeaders(range, response.headers, totalLength);
        KTVHCDataResponse * obj = [[KTVHCDataResponse alloc] initWithURL:response.URL headers:headers];
        return obj;
    }
    return response;
}
