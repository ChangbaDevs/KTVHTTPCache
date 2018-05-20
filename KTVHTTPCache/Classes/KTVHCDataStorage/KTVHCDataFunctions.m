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

KTVHCDataResponse * KTVHCCopyResponseIfNeeded(KTVHCDataResponse * response, KTVHCRange range, long long totalLength)
{
    long long currentLength = KTVHCRangeGetLength(range);
    if (response.totalLength != totalLength || response.currentLength != currentLength) {
        NSMutableDictionary * headers = [NSMutableDictionary dictionaryWithDictionary:response.headersWithoutRangeAndLength];
        [headers setObject:[NSString stringWithFormat:@"%lld", currentLength] forKey:@"Content-Length"];
        [headers setObject:[NSString stringWithFormat:@"bytes %lld-%lld/%lld", range.start, range.end, totalLength] forKey:@"Content-Range"];
        KTVHCDataResponse * obj = [[KTVHCDataResponse alloc] initWithURL:response.URL headers:headers];
        return obj;
    }
    return response;
}
